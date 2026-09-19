-- Read-only collection adapters. Current-run perks are deliberately never consulted.
local A,U=EbonTomeFarm,EbonTomeFarm.util
local function spellbook()
    local ids={}
    if not (GetNumSpellTabs and GetSpellTabInfo and GetSpellLink) then return ids end
    for tab=1,GetNumSpellTabs() do
        local name,_,offset,count=GetSpellTabInfo(tab)
        if name=="Echoes" then
            for slot=offset+1,offset+count do
                local link=GetSpellLink(slot,BOOKTYPE_SPELL or "spell")
                local id=link and tonumber(link:match("spell:(%d+)"))
                if id then ids[id]=true end
            end
        end
    end
    return ids
end
-- Two seconds after login are a silent baseline, not newly acquired loot.
function A:BeginBagBaseline()
    self.runtime.bagSeen=self.runtime.bagSeen or {}
    self.runtime.bagBaselineReady=false;self.runtime.bagWarmup=2
end
function A:ScanBags(deferRefresh)
    if not (GetContainerNumSlots and GetContainerItemLink) then return false end
    local bags={}
    for bag=0,4 do
        for slot=1,GetContainerNumSlots(bag) do
            local link=GetContainerItemLink(bag,slot)
            if link then
                local label=link:match("|h%[(.-)%]|h") or ""
                if label:lower():match("^tome of echo%s*:") or label:lower():match("^tome of echoes%s*:") then
                    local key=U.key(label);local tome=self.tomesByKey and self.tomesByKey[key]
                    bags[key]={key=key,name=tome and tome.name or U.name(label),link=link,bag=bag,slot=slot}
                end
            end
        end
    end
    local old=self.runtime.bags or {};local changed=false
    for key in pairs(bags) do if not old[key] then changed=true end end
    for key in pairs(old) do if not bags[key] then changed=true end end
    self.runtime.bags=bags
    local seen=self.runtime.bagSeen or {};self.runtime.bagSeen=seen
    local warming=(self.runtime.bagWarmup or 0)>0
    local silent=not self.runtime.bagBaselineReady or warming
    for _,key in ipairs(U.sortedKeys(bags)) do
        if not seen[key] then
            seen[key]=true
            if not silent and self.char.settings.tomeAlerts and self.ShowTomeFound then self:ShowTomeFound(bags[key]) end
        end
    end
    if not warming then self.runtime.bagBaselineReady=true end
    -- The session-wide seen set survives bag sorting, use, rescans and build resets.
    if changed and not deferRefresh then self:Refresh() end
    return changed
end
function A:ScanCollection()
    local owned={}
    local service=ProjectEbonhold and ProjectEbonhold.PerkService
    self.runtime.collectionAPI=false
    if service and type(service.GetDiscoveredEchoes)=="function" then
        local ok,found=pcall(service.GetDiscoveredEchoes)
        if ok and type(found)=="table" then
            self.runtime.collectionAPI=true
            for id,value in pairs(found) do
                local p=self.perksByID[tonumber(id)]
                if p and value~=false then owned[p.key]=true end
            end
        end
    end
    -- Only the dedicated permanent Echoes tab, not the ordinary spellbook/buff list.
    local ok,book=pcall(spellbook)
    if ok then
        for id,p in pairs(self.perksByID or {}) do
            if (type(p.requiredSpell)=="number" and p.requiredSpell>0 and book[p.requiredSpell]) or book[id+100000] then owned[p.key]=true end
        end
    end
    self.runtime.owned=owned
    self:ScanBags(true)
    self:Refresh()
end
function A:GetHubBuilds()
    -- Copy only when explicitly selected by the user; never alter Hub saved variables.
    local db=EbonholdHubDB
    local found={}
    if type(db)~="table" or type(db.builds)~="table" then return found end
    for _,key in ipairs(U.sortedKeys(db.builds)) do
        local b=db.builds[key]
        if type(b)=="table" and (b.echoTiers or b.lockedEchoes or b.echoWeights) then
            found[#found+1]={key=key,title=U.clean(b.title or b.name or tostring(key)),data=b}
        end
    end
    return found
end
