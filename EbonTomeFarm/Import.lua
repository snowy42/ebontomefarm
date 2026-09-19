-- Independent readers for the observed EbonholdHub JSON/Base64 and EBH1/EWL1 wire formats.
local A,U=EbonTomeFarm,EbonTomeFarm.util
local rank={Locked=5,S=4,A=3,B=2,C=1,F=0,pool=0}
A.TierRank=rank
function A:LoadData()
    self.sourceGroups=nil
    self.tomesByID,self.tomesByKey,self.locationsByID={},{},{}
    for _,t in ipairs(self.Data.tomes) do self.tomesByID[t.id]=t;self.tomesByKey[U.key(t.name)]=t;t.locations={} end
    for _,loc in ipairs(self.Data.locations) do
        self.locationsByID[loc.id]=loc
        local tome=self.tomesByID[loc.tomeID];if tome then tome.locations[#tome.locations+1]=loc end
    end
end
function A:BuildPerkIndex()
    self.perksByKey={};self.perksByID={}
    local db=ProjectEbonhold and ProjectEbonhold.PerkDatabase
    if type(db)~="table" then return end
    for id,p in pairs(db) do
        if type(id)=="number" and type(p)=="table" then
            local name=type(p.comment)=="string" and U.name(p.comment) or nil
            if not name or name=="" then name=GetSpellInfo and GetSpellInfo(id) end
            if name and name~="" then
                local k=U.key(name);self.perksByKey[k]=self.perksByKey[k] or {}
                local v={id=id,key=k,name=U.name(name),requiredSpell=p.requiredSpell,quality=p.quality,groupId=p.groupId}
                self.perksByKey[k][#self.perksByKey[k]+1]=v;self.perksByID[id]=v
            end
        end
    end
end
function A:ResolveTarget(raw)
    local id=tonumber(raw.spellID);local perk=id and self.perksByID and self.perksByID[id]
    local name=perk and perk.name or raw.name
    if (not name or name=="") and id and GetSpellInfo then name=GetSpellInfo(id) end
    name=U.name(name)
    if name=="" then name="Unknown echo #"..tostring(id or "?") end
    local k=perk and perk.key or (name:match("^Unknown echo #") and "spell:"..tostring(id) or U.key(name))
    local tome=self.tomesByKey and self.tomesByKey[k]
    local target={key=k,name=tome and tome.name or name,spellID=id,tier=raw.tier or "B",locked=raw.locked,tomeID=tome and tome.id}
    if not tome then
        local entries=self.perksByKey and self.perksByKey[k]
        -- Only an explicit zero requirement can establish an innate echo. Missing data cannot.
        local hasZero,hasPositive=false,false
        for _,p in ipairs(entries or {}) do
            if p.requiredSpell==0 then hasZero=true elseif type(p.requiredSpell)=="number" and p.requiredSpell>0 then hasPositive=true end
        end
        target.innate=hasZero and not hasPositive or nil
    end
    return target
end
function A:IndexTargets()
    local b=self:GetBuild();if not b then return end
    if not b.sourceTargets then b.sourceTargets=U.copy(b.targets) end
    local targets,seen={},{}
    for _,raw in ipairs(b.sourceTargets) do
        local t=self:ResolveTarget(raw);local old=seen[t.key]
        if old then
            if (rank[t.tier] or 0)>(rank[old.tier] or 0) then old.tier=t.tier end
            old.locked=old.locked or t.locked;old.spellID=old.spellID or t.spellID
        else seen[t.key]=t;targets[#targets+1]=t end
    end
    table.sort(targets,function(x,y)
        if (rank[x.tier] or 0)~=(rank[y.tier] or 0) then return (rank[x.tier] or 0)>(rank[y.tier] or 0) end
        return x.name<y.name
    end)
    b.targets=targets
end
local function collect(data)
    local out,warnings={},{};local count=0
    local function add(name,id,tier,locked)
        if count>=512 then error("Build exceeds 512 echo references.") end
        if type(name)=="number" and not id then id=name;name=nil end
        if type(name)=="table" then
            local obj=name;name=obj.name or obj.echoName;id=obj.spellId or obj.spellID or obj.id or id
        end
        if name and type(name)~="string" then return end
        id=tonumber(id)
        if id and (id%1~=0 or id<=0 or id>10000000) then error("Invalid echo spell ID.") end
        if (not name or U.trim(name)=="") and not id then return end
        if name and #name>200 then error("An echo name exceeds 200 characters.") end
        out[#out+1]={name=name,spellID=id,tier=tier or "B",locked=locked or nil};count=count+1
    end
    local function wanted(t) return type(t)=="string" and (rank[t] or 0)>0 end
    if type(data.lockedEchoes)=="table" then
        for _,k in ipairs(U.sortedKeys(data.lockedEchoes)) do local x=data.lockedEchoes[k];if x~=A.Codec.NULL then add(x,nil,"Locked",true) end end
    end
    if type(data.echoTiers)=="table" then
        for _,name in ipairs(U.sortedKeys(data.echoTiers)) do
            local tier=data.echoTiers[name]
            if wanted(tier) then add(name,type(data.loadoutEchoSpellIds)=="table" and data.loadoutEchoSpellIds[name] or nil,tier) end
        end
    end
    if type(data.echoBundles)=="table" then
        for _,bundle in pairs(data.echoBundles) do
            if type(bundle)=="table" and wanted(bundle.tier) and type(bundle.echoes)=="table" then
                for _,echo in pairs(bundle.echoes) do add(echo,nil,bundle.tier) end
            end
        end
    end
    if type(data.echoWeights)=="table" and not (type(data.echoTiers)=="table" and next(data.echoTiers)) then
        for _,name in ipairs(U.sortedKeys(data.echoWeights)) do
            local w=tonumber(data.echoWeights[name]);if w and w>0 then add(name,nil,"B") end
        end
    end
    if type(data.loadoutEchoSpellIds)=="table" then
        for _,name in ipairs(U.sortedKeys(data.loadoutEchoSpellIds)) do
            local tier=type(data.echoTiers)=="table" and data.echoTiers[name] or nil
            if tier==nil then add(name,data.loadoutEchoSpellIds[name],"B") end
        end
    end
    if type(data.echoes)=="table" then
        for _,entry in ipairs(data.echoes) do add(entry,nil,"B") end
    end
    if #out==0 then return nil,"No wanted echoes found. F-tier / pool entries are not farming targets." end
    local title=type(data.title)=="string" and U.clean(data.title) or "Imported build"
    return {title=U.trim(title):sub(1,100),class=data.class,targets=out,sourceTargets=U.copy(out),warnings=warnings,format="EbonholdHub"}
end
function A:ParseImport(text)
    text=U.trim(text)
    if #text>524288 then return nil,"Import exceeds 512 KiB." end
    if text=="" then return nil,"Paste a Hub export, EBH1/EWL1 loadout, or one echo name per line." end
    if text:match("^https?://") then return nil,"Paste the build's Export code, not its page URL. WoW addons cannot fetch websites." end
    local version=text:match("^(E[WB][LH]%d+):") -- accepted versions are checked explicitly below
    if text:match("^EBH%d+:") or text:match("^EWL%d+:") then
        local out,title,class={},nil,nil
        if text:match("^EBH1:") then
            local entries;entries,class,title=text:match("^EBH1:([^:]+):([A-Z_]+):(.*)$")
            if not entries then return nil,"Expected EBH1:spellId.tier.stack,...:CLASS:Build name." end
            for token in (entries..","):gmatch("(.-),") do
                token=U.trim(token);local id,tier,stack=token:match("^(%d+)%.(%d+)%.(%d+)$")
                id,tier,stack=tonumber(id),tonumber(tier),tonumber(stack)
                if not id or id<1 or id>10000000 or not tier or tier<1 or tier>4 or not stack or stack<1 or stack>1000 then return nil,"Malformed EBH1 entry: "..token:sub(1,60) end
                if #out>=512 then return nil,"Loadout exceeds 512 entries." end
                out[#out+1]={spellID=id,tier=({[1]="B",[2]="A",[3]="S",[4]="S"})[tier]}
            end
        elseif text:match("^EWL1:") then
            local entries;class,entries=text:match("^EWL1:([A-Z_]+):(.+)$")
            if not entries then return nil,"Expected EWL1:CLASS:spellId:flag,..." end
            title=class.." wishlist"
            for token in (entries..","):gmatch("(.-),") do
                token=U.trim(token);local id,flag=token:match("^(%d+):(%d+)$");id,flag=tonumber(id),tonumber(flag)
                if not id or id<1 or id>10000000 or (flag~=0 and flag~=1) then return nil,"Malformed EWL1 entry: "..token:sub(1,60) end
                if #out>=512 then return nil,"Loadout exceeds 512 entries." end
                out[#out+1]={spellID=id,tier=flag==1 and "Locked" or "B",locked=flag==1 or nil}
            end
        else return nil,"Unsupported journal format version. Export as Hub Base64/JSON instead." end
        if #out==0 or #out>512 then return nil,"Loadout must contain between 1 and 512 entries." end
        return {title=U.clean(title or "Journal loadout"):sub(1,100),class=class,targets=out,sourceTargets=U.copy(out),format="Journal"}
    end
    local payload=text
    if text:sub(1,1)~="{" and text:sub(1,1)~="[" then
        local decoded,err=A.Codec.Base64Decode(text)
        if decoded then payload=decoded
        elseif text:find("\n",1,true) or self.tomesByKey[U.key(text)] then
            local out={};for line in text:gmatch("[^\r\n]+") do
                line=U.trim(line:gsub("^%s*[%-%*]%s+",""));if line~="" then
                    if #out>=512 then return nil,"Name list exceeds 512 entries." end
                    out[#out+1]={name=line,tier="B"} end
            end
            if #out>512 then return nil,"Name list exceeds 512 entries." end
            return {title="Tome wishlist",targets=out,sourceTargets=U.copy(out),format="Names"}
        else return nil,err end
    end
    local data,err=A.Codec.JSONDecode(payload)
    if not data then return nil,"Cannot read export: "..tostring(err) end
    if type(data)~="table" or data==A.Codec.NULL then return nil,"A build export must be a JSON object." end
    local ok,b,message=pcall(collect,data)
    if not ok then return nil,"Invalid build: "..tostring(b) end
    return b,message
end
function A:Import(text)
    local b,err=self:ParseImport(text);if not b then return nil,err end
    return self:SaveBuild(b)
end

function A:ParseHubData(data)
    if type(data)~="table" then return nil,"No Hub build data was supplied." end
    local ok,b,err=pcall(collect,data)
    if not ok then return nil,"Invalid Hub build: "..tostring(b) end
    return b,err
end
