-- Deterministic greedy farm-stop grouping. Not a terrain/flight-path travel solver.
local A,U=EbonTomeFarm,EbonTomeFarm.util
function A:Eligible(t)
    return t.locked or (self.TierRank[t.tier] or 0)>=(self.TierRank[self.char.settings.minimumTier] or 1)
end
function A:TargetByKey(key)
    local b=self:GetBuild();for _,t in ipairs(b and b.targets or {}) do if t.key==key then return t end end
end
function A:TargetLocations(t)
    local out={}
    local custom=self.char.locations[t.key]
    if custom and self.Data.zones[custom.mapID] then
        local z=self.Data.zones[custom.mapID]
        out[#out+1]={id="custom:"..t.key,tomeID=t.tomeID,place=custom.place or "Your recorded farming spot",zone=z.name,
            mapID=z.mapID,c=z.c,x=custom.x,y=custom.y,kind="world",accuracy="custom",mobs={custom.mob or "Your recorded location"},notes="Recorded on this character. Not part of the community dataset."}
    end
    local tome=t.tomeID and self.tomesByID[t.tomeID]
    for _,loc in ipairs(tome and tome.locations or {}) do out[#out+1]=loc end
    return out
end
function A:LocationUsable(loc)
    return loc and type(loc.x)=="number" and type(loc.y)=="number" and loc.x>0 and loc.x<1 and loc.y>0 and loc.y<1 and self.Data.zones[loc.mapID]
        and (loc.kind~="raid" or self.char.settings.raids) and (loc.kind~="dungeon" or self.char.settings.dungeons)
end
function A:WorldPoint(mapID,x,y)
    local z=self.Data.zones[mapID]
    if z and x and y then return z.left-z.width*x,z.top-z.height*y,z.instance end
end
function A:Distance(a,b)
    if not (a and b) then return nil end
    local x,y,i=self:WorldPoint(a.mapID,a.x,a.y);local xx,yy,ii=self:WorldPoint(b.mapID,b.x,b.y)
    if x and xx and i==ii then return math.sqrt((x-xx)^2+(y-yy)^2) end
end
function A:SourceGroup(loc)
    if loc.instanceArea then return "instance:"..loc.instanceArea end
    if loc.accuracy=="custom" then return loc.id end
    if not self.sourceGroups then
        -- Build against the complete static dataset so groups do not change as tomes are collected.
        self.sourceGroups={};local rows,camps={},{}
        for _,l in ipairs(self.Data.locations)do
            if l.mapID and l.x and l.y and not l.instanceArea then rows[#rows+1]=l end
        end
        table.sort(rows,function(a,b)return a.id<b.id end)
        for _,l in ipairs(rows)do
            local chosen
            for _,camp in ipairs(camps)do
                if l.mapID==camp.loc.mapID and l.kind==camp.loc.kind then
                    local distance=self:Distance(l,camp.loc)
                    local sameName=U.key(l.place)==U.key(camp.loc.place)
                    if distance and distance<=(sameName and 180 or 90)then chosen=camp;break end
                end
            end
            if not chosen then chosen={id="camp:"..l.id,loc=l};camps[#camps+1]=chosen end
            self.sourceGroups[l.id]=chosen.id
        end
    end
    return self.sourceGroups[loc.id] or "source:"..loc.id
end
function A:RouteCandidates()
    local candidates,byid={},{}
    local b=self:GetBuild()
    for _,t in ipairs(b and b.targets or {}) do
        if self:Eligible(t) and not self:IsDone(t) then
            for _,loc in ipairs(self:TargetLocations(t)) do
                if self:LocationUsable(loc) then
                    local id=self:SourceGroup(loc)
                    local s=byid[id]
                    if not s then s={id=id,loc=loc,targets={},targetLocs={},mapID=loc.mapID,x=loc.x,y=loc.y,c=loc.c};byid[id]=s;candidates[#candidates+1]=s end
                    if not s.targetLocs[t.key] then s.targets[#s.targets+1]=t;s.targetLocs[t.key]=loc end
                end
            end
        end
    end
    table.sort(candidates,function(a,b)return a.id<b.id end)
    return candidates,byid
end
function A:RebuildRoute()
    local candidates,byid=self:RouteCandidates()
    local r,covered={},{}
    local cursor=self.runtime.position
    local old=self.runtime.active
    local active=old and byid[old]
    -- Stay at an active farm while it has outstanding targets. Merely arriving never completes it.
    if active and not self.runtime.skipped[old] then
        r[#r+1]=active;cursor=active
        for _,t in ipairs(active.targets) do covered[t.key]=true end
    elseif old then
        self.runtime.active=nil
        if self.ClearWaypoint then self:ClearWaypoint() end
        if not self.char.settings.autoAdvance then self.runtime.running=false end
    end
    while true do
        local best,bestScore,bestTargets
        for _,s in ipairs(candidates) do
            if not self.runtime.skipped[s.id] then
                local needed,weight={},0
                for _,t in ipairs(s.targets) do
                    if not covered[t.key] then needed[#needed+1]=t;weight=weight+(1+(self.TierRank[t.tier] or 1)*.12) end
                end
                if #needed>0 then
                    local distance=self:Distance(cursor,s)
                    local cost=distance and (1+distance/2000) or (cursor and 20 or 1)
                    if cursor and cursor.c and cursor.c~=s.c then cost=cost+30 end
                    if s.loc.kind=="raid" then cost=cost+1 elseif s.loc.kind=="dungeon" then cost=cost+.35 end
                    local score=weight/cost
                    if not bestScore or score>bestScore then best,bestScore,bestTargets=s,score,needed end
                end
            end
        end
        if not best then break end
        local stop={id=best.id,loc=best.loc,targets=bestTargets,targetLocs=best.targetLocs,mapID=best.mapID,x=best.x,y=best.y,c=best.c}
        r[#r+1]=stop;cursor=stop
        for _,t in ipairs(bestTargets) do covered[t.key]=true end
    end
    self.runtime.route=r
    if self.runtime.running and not self.runtime.active and r[1] then
        self.runtime.active=r[1].id
        if self.SetWaypoint then self:SetWaypoint(r[1]) end
    elseif self.runtime.running and #r==0 then
        self.runtime.running=false
        if self.ClearWaypoint then self:ClearWaypoint() end
    end
end
function A:ActiveStop()
    for _,s in ipairs(self.runtime.route) do if s.id==self.runtime.active then return s end end
end
function A:BestLocation(t)
    for _,s in ipairs(self.runtime.route) do if s.targetLocs[t.key] then return s.targetLocs[t.key],s end end
    local locations=self:TargetLocations(t)
    for _,l in ipairs(locations) do if self:LocationUsable(l) then return l end end
    for _,l in ipairs(locations) do if l.mapID then return l end end
    return locations[1]
end
function A:StartRoute()
    if self.SamplePosition then self:SamplePosition() end
    self.runtime.running=true;self:Refresh()
    if not self:ActiveStop() then self:Print("No routable stops. Check source details, instance filters, or record your own location.") end
end
function A:PauseRoute()
    self.runtime.running=false;self.runtime.active=nil
    if self.ClearWaypoint then self:ClearWaypoint() end;self:Refresh()
end
function A:SkipStop()
    local s=self:ActiveStop() or self.runtime.route[1]
    if s then self.runtime.skipped[s.id]=true end
    self.runtime.active=nil;self.runtime.running=true
    if self.ClearWaypoint then self:ClearWaypoint() end;self:Refresh()
end
function A:Replan()
    self.runtime.skipped={};self.runtime.active=nil
    if self.ClearWaypoint then self:ClearWaypoint() end
    if self.SamplePosition then self:SamplePosition() end;self:Refresh()
end
function A:NavigateLocation(t,loc)
    if not self:LocationUsable(loc) then self:ShowLocation(t,loc);return end
    local _,byid=self:RouteCandidates();local s=byid[self:SourceGroup(loc)]
    if not s then
        -- Completed/filtered targets may still be inspected, but do not contaminate the farm itinerary.
        self:ShowLocation(t,loc);self:Print("This location is not an outstanding enabled farm stop.");return
    end
    self.runtime.skipped[s.id]=nil;self.runtime.active=s.id;self.runtime.running=true
    self:SetWaypoint(s);self:Refresh()
end
function A:RecordLocation(t)
    if not self:SamplePosition() then return nil,"Close the map and stand outdoors in a mapped zone first." end
    local p=self.runtime.position
    if not p or self.Data.zones[p.mapID].continent then return nil,"A native zone position is required." end
    self.char.locations[t.key]={mapID=p.mapID,x=p.x,y=p.y,place=GetSubZoneText and GetSubZoneText() or "My farming spot",mob=UnitName and UnitName("target") or nil}
    self:Refresh();return true
end
