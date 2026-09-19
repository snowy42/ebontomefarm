-- Nearest-first farming, finishing one native map zone at a time.
-- Distances are straight-line within a continent, not roads/portals/flight paths.
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
    local old=self.runtime.active
    local previous=self:ActiveStop()
    local active=old and byid[old]
    if active and self.runtime.skipped[old] then active=nil end
    -- Sample BEFORE choosing: bag/zone events may run before the navigation tick.
    if self.SamplePosition then self:SamplePosition() end
    local mapOpen=WorldMapFrame and WorldMapFrame:IsShown()
    if not mapOpen then self.runtime.pendingReplan=nil end
    local cursor=self.runtime.position
    if not cursor and IsInInstance and IsInInstance() then cursor=self.runtime.lastOutdoorPosition end
    if self.runtime.pendingReplan then cursor=nil end
    local zone=self.runtime.running and self.runtime.routeZone or nil
    if active then
        -- Arrival alone never completes a farm. Keep all outstanding camp targets.
        r[#r+1]=active;cursor=active;zone=active.mapID
        for _,t in ipairs(active.targets) do covered[t.key]=true end
    elseif old then
        self.runtime.active=nil
        if self.ClearWaypoint then self:ClearWaypoint() end
        if previous then zone=previous.mapID end
        if not self.char.settings.autoAdvance then self.runtime.running=false end
    end
    if not cursor then
        -- Never choose an arbitrary high-coverage raid while position is unavailable.
        self.runtime.route={};self.runtime.waitingForPosition=#candidates>0
        if #candidates==0 then self.runtime.running=false end
        return
    end
    self.runtime.waitingForPosition=false
    local function choose(onlyZone)
        local best,bestTargets,bestContinent,bestDistance
        local origin=self.Data.zones[cursor.mapID]
        for _,s in ipairs(candidates) do
            if not self.runtime.skipped[s.id] and (not onlyZone or s.mapID==onlyZone) then
                local needed={}
                for _,t in ipairs(s.targets) do if not covered[t.key] then needed[#needed+1]=t end end
                if #needed>0 then
                    local z=self.Data.zones[s.mapID]
                    local continent=(origin and z and origin.c==z.c) and 0 or 1
                    local distance=self:Distance(cursor,s) or math.huge
                    -- No tier/coverage weighting: a distant multi-tome raid cannot
                    -- outrank a nearby single tome. Across continents there is no
                    -- meaningful Euclidean travel distance, so use a stable order.
                    if continent==1 then distance=math.huge end
                    if not best or continent<bestContinent
                        or (continent==bestContinent and (distance<bestDistance
                        or (distance==bestDistance and (s.mapID<best.mapID
                        or (s.mapID==best.mapID and s.id<best.id))))) then
                        best,bestTargets,bestContinent,bestDistance=s,needed,continent,distance
                    end
                end
            end
        end
        return best,bestTargets
    end
    while true do
        local best,targets
        if zone then best,targets=choose(zone) end
        if not best then best,targets=choose(nil) end
        if not best then break end
        local stop={id=best.id,loc=best.loc,targets=targets,targetLocs=best.targetLocs,
            mapID=best.mapID,x=best.x,y=best.y,c=best.c}
        r[#r+1]=stop;cursor=stop;zone=stop.mapID
        for _,t in ipairs(targets) do covered[t.key]=true end
    end
    self.runtime.route=r
    if self.runtime.running and not self.runtime.active and r[1] then
        self.runtime.active=r[1].id;self.runtime.routeZone=r[1].mapID
        if self.SetWaypoint then self:SetWaypoint(r[1]) end
    elseif self.runtime.running and #r==0 then
        self.runtime.running=false;self.runtime.routeZone=nil
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
    if not self:GetBuild() then self:Print("Import a build first.");return end
    self.runtime.running=true
    if WorldMapFrame and WorldMapFrame:IsShown() and not self:ActiveStop() then self.runtime.pendingReplan=true end
    self:ScanCollection()
    if self.runtime.waitingForPosition then
        self:Print("Waiting for your position. Close the world map and stand in a mapped outdoor zone.")
    elseif not self:ActiveStop() then self:Print("No routable stops. Check source details, instance filters, or record your own location.") end
end
function A:PauseRoute()
    self.runtime.running=false;self.runtime.active=nil;self.runtime.routeZone=nil;self.runtime.pendingReplan=nil
    if self.ClearWaypoint then self:ClearWaypoint() end;self:Refresh()
end
function A:SkipStop()
    local s=self:ActiveStop() or self.runtime.route[1]
    if s then self.runtime.skipped[s.id]=true;self.runtime.routeZone=s.mapID end
    self.runtime.active=nil;self.runtime.running=true
    if self.ClearWaypoint then self:ClearWaypoint() end;self:Refresh()
end
function A:Replan()
    if not self:GetBuild() then self:Print("Import a build first.");return end
    self.runtime.skipped={};self.runtime.active=nil;self.runtime.routeZone=nil
    self.runtime.running=true
    self.runtime.pendingReplan=WorldMapFrame and WorldMapFrame:IsShown() or nil
    if self.ClearWaypoint then self:ClearWaypoint() end
    self:BuildPerkIndex();self:ScanCollection()
    if self.runtime.waitingForPosition then self:Print("Close the world map to replan from your current outdoor position.") end
end
-- Reset only overrides for the active build; never delete a build or real unlocks.
function A:ResetBuild(expectedID)
    local build=self:GetBuild()
    if not build or (expectedID and build.id~=expectedID) then return nil,"The active build changed. Open Reset build again." end
    for _,t in ipairs(build.targets) do self.char.manual[t.key]=nil end
    self:BuildPerkIndex();self:IndexTargets()
    for _,t in ipairs(build.targets) do self.char.manual[t.key]=nil end
    self.runtime.skipped={};self.runtime.active=nil;self.runtime.routeZone=nil
    self.runtime.running=false;self.runtime.pendingReplan=nil;self.runtime.selected=nil
    self.runtime.mapLocation=nil;self.runtime.search="";self.runtime.scroll=0
    if self.ClearWaypoint then self:ClearWaypoint() end
    if self.UI and self.UI.search then self.UI.search:SetText("") end
    if self.mapPins then for _,pin in ipairs(self.mapPins) do pin:Hide() end end
    self:ScanCollection()
    if self.UI and self.UI.details then self.UI.details:Hide() end
    self:Print("Build reset. Manual ticks and skipped stops cleared; learned echoes and bags rescanned. Click Start route when ready.")
    return true
end
function A:NavigateLocation(t,loc)
    if not self:LocationUsable(loc) then self:ShowLocation(t,loc);return end
    local _,byid=self:RouteCandidates();local s=byid[self:SourceGroup(loc)]
    if not s then
        -- Completed/filtered targets may still be inspected, but do not contaminate the farm itinerary.
        self:ShowLocation(t,loc);self:Print("This location is not an outstanding enabled farm stop.");return
    end
    self.runtime.skipped[s.id]=nil;self.runtime.active=s.id;self.runtime.running=true
    self.runtime.routeZone=s.mapID;self.runtime.pendingReplan=nil
    self:SetWaypoint(s);self:Refresh()
end
function A:RecordLocation(t)
    if not self:SamplePosition() then return nil,"Close the map and stand outdoors in a mapped zone first." end
    local p=self.runtime.position
    if not p or self.Data.zones[p.mapID].continent then return nil,"A native zone position is required." end
    self.char.locations[t.key]={mapID=p.mapID,x=p.x,y=p.y,place=GetSubZoneText and GetSubZoneText() or "My farming spot",mob=UnitName and UnitName("target") or nil}
    self:Refresh();return true
end
