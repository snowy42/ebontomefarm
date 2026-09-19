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
function A:ScanCollection()
    local owned,bags={},{}
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
    if GetContainerNumSlots and GetContainerItemLink then
        for bag=0,4 do
            for slot=1,GetContainerNumSlots(bag) do
                local link=GetContainerItemLink(bag,slot)
                if link then
                    local label=link:match("|h%[(.-)%]|h") or ""
                    if label:lower():match("^tome of echo%s*:") or label:lower():match("^tome of echoes%s*:") then
                        bags[U.key(label)]={link=link,bag=bag,slot=slot}
                    end
                end
            end
        end
    end
    self.runtime.owned,self.runtime.bags=owned,bags
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
