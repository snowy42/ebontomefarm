-- Native 3.3.5 map support, with optional legacy TomTom. No travel or combat automation.
local A,U=EbonTomeFarm,EbonTomeFarm.util
local atan2=math.atan2 or function(y,x)
    if x>0 then return math.atan(y/x) end
    if x<0 then return math.atan(y/x)+(y>=0 and math.pi or -math.pi) end
    if y>0 then return math.pi/2 elseif y<0 then return -math.pi/2 end;return 0
end
function A:InitMaps()
    self.mapCZ={}
    if not (GetMapContinents and GetMapZones and SetMapZoom and GetCurrentMapAreaID) then return end
    local c,z=GetCurrentMapContinent(),GetCurrentMapZone()
    local level=GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel()
    for ci in ipairs({GetMapContinents()}) do
        SetMapZoom(ci,0);self.mapCZ[GetCurrentMapAreaID()]={c=ci,z=0}
        for zi in ipairs({GetMapZones(ci)}) do
            SetMapZoom(ci,zi);self.mapCZ[GetCurrentMapAreaID()]={c=ci,z=zi}
        end
    end
    SetMapZoom(c or 0,z or 0)
    if level and level>0 and SetDungeonMapLevel then SetDungeonMapLevel(level) end
end
function A:SamplePosition()
    -- Never switch the map while a player is inspecting it. Keep the last safe sample.
    if WorldMapFrame and WorldMapFrame:IsShown() then return false end
    if IsInInstance then local inside=IsInInstance();if inside then self.runtime.position=nil;return false end end
    if not (SetMapToCurrentZone and GetCurrentMapAreaID and GetPlayerMapPosition) then return false end
    SetMapToCurrentZone()
    local mid=GetCurrentMapAreaID();local x,y=GetPlayerMapPosition("player")
    local zone=self.Data.zones[mid]
    if zone and type(x)=="number" and type(y)=="number" and x>0 and x<1 and y>0 and y<1 then
        self.runtime.position={mapID=mid,x=x,y=y,c=zone.c};return true
    end
    self.runtime.position=nil;return false
end
function A:ClearWaypoint()
    if self.runtime.tomtomUID and TomTom and type(TomTom.RemoveWaypoint)=="function" then pcall(TomTom.RemoveWaypoint,TomTom,self.runtime.tomtomUID) end
    self.runtime.tomtomUID=nil
    if self.arrow then self.arrow:Hide() end
end
function A:SetWaypoint(stop)
    self:ClearWaypoint()
    if not stop then return end
    self.runtime.mapLocation=stop.loc
    if self.char.settings.tomtom and TomTom and type(TomTom.AddZWaypoint)=="function" then
        local cz=self.mapCZ and self.mapCZ[stop.loc.mapID]
        if cz and cz.z>0 then
            local title="ETF: "..stop.loc.place
            local ok,uid=pcall(TomTom.AddZWaypoint,TomTom,cz.c,cz.z,stop.x*100,stop.y*100,title,false,false,true)
            if ok and uid then
                self.runtime.tomtomUID=uid
                if type(TomTom.SetCrazyArrow)=="function" then pcall(TomTom.SetCrazyArrow,TomTom,uid,20,title) end
            end
        end
    end
    if self.UpdateNavigation then self:UpdateNavigation() end
end
function A:ShowLocation(target,loc)
    self.runtime.selected=target and target.key or self.runtime.selected
    self.runtime.mapLocation=loc
    if self.ShowDetails then self:ShowDetails(target,loc) end
    if not loc or not loc.mapID then
        self:Print("This source has no verified map position. Its details are still shown.");return
    end
    if WorldMapFrame then
        if ShowUIPanel then ShowUIPanel(WorldMapFrame) else WorldMapFrame:Show() end
    end
    -- Original 3.3.5 GetCurrentMapAreaID returns the DBC ID plus one.
    -- SetMapByID takes the DBC ID itself; Questie also applies this offset.
    if SetMapByID then SetMapByID(loc.mapID-1)
    elseif self.mapCZ and self.mapCZ[loc.mapID] then
        local cz=self.mapCZ[loc.mapID];SetMapZoom(cz.c,cz.z)
    end
    if GetCurrentMapDungeonLevel and SetDungeonMapLevel and GetCurrentMapDungeonLevel()>0 then SetDungeonMapLevel(0) end
    self:DrawPins()
end
function A:MapXY(loc,mapID)
    if not (loc and loc.x and loc.y) then return end
    if loc.mapID==mapID then return loc.x,loc.y end
    local displayed=self.Data.zones[mapID]
    if not displayed or not displayed.continent then return end
    local x,y,i=self:WorldPoint(loc.mapID,loc.x,loc.y)
    if x and i==displayed.instance then return (displayed.left-x)/displayed.width,(displayed.top-y)/displayed.height end
end
function A:DrawPins()
    if not (WorldMapFrame and WorldMapFrame:IsShown()) then return end
    local canvas=WorldMapButton or WorldMapDetailFrame
    if not canvas then return end
    self.mapPins=self.mapPins or {}
    for _,p in ipairs(self.mapPins) do p:Hide() end
    if GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel()>0 then return end
    local mid=GetCurrentMapAreaID();local loc=self.runtime.mapLocation
    if not loc then return end
    local places={loc}
    for _,pt in ipairs(loc.spawns or {}) do
        if math.abs(pt[1]-loc.x)+math.abs(pt[2]-loc.y)>.0001 then places[#places+1]={mapID=loc.mapID,x=pt[1],y=pt[2]} end
    end
    for i,point in ipairs(places) do
        local x,y=self:MapXY(point,mid)
        if x and x>0 and x<1 and y>0 and y<1 then
            local p=self.mapPins[i]
            if not p then
                p=CreateFrame("Button",nil,canvas);p:SetFrameStrata("FULLSCREEN_DIALOG");p:SetFrameLevel(canvas:GetFrameLevel()+20)
                p:SetWidth(i==1 and 22 or 12);p:SetHeight(i==1 and 22 or 12)
                p.icon=p:CreateTexture(nil,"OVERLAY");p.icon:SetAllPoints();p.icon:SetTexture("Interface\\Minimap\\POIIcons");p.icon:SetTexCoord(.5,.625,0,.125)
                p:SetScript("OnEnter",function(pin)
                    GameTooltip:SetOwner(pin,"ANCHOR_RIGHT");GameTooltip:AddLine("EbonTomeFarm",.84,.70,.42)
                    GameTooltip:AddLine(pin.label,1,1,1,true);GameTooltip:Show()
                end)
                p:SetScript("OnLeave",function()GameTooltip:Hide()end)
                self.mapPins[i]=p
            end
            p:ClearAllPoints();p:SetPoint("CENTER",canvas,"TOPLEFT",canvas:GetWidth()*x,-canvas:GetHeight()*y)
            p.label=loc.place.."\n"..table.concat(loc.mobs or {},", ").."\n"..(loc.accuracy=="entrance" and "Exterior instance entrance" or "Representative farming position")
            p.icon:SetVertexColor(i==1 and 1 or .65,i==1 and .78 or .77,i==1 and .3 or 1,1);p:Show()
        end
    end
end
function A:Bearing(position,loc,facing)
    local x,y,i=self:WorldPoint(position.mapID,position.x,position.y)
    local xx,yy,ii=self:WorldPoint(loc.mapID,loc.x,loc.y)
    if not x or not xx or i~=ii then return end
    -- HBD-style map axes: east decreases x, north increases y.
    -- GetPlayerFacing is 0=north and positive counter-clockwise (west).
    return atan2(x-xx,yy-y)+(facing or 0),math.sqrt((x-xx)^2+(y-yy)^2)
end
function A:UpdateNavigation()
    local stop=self:ActiveStop()
    if not self.arrow then return end
    if not self.runtime.running or not stop or not self.char.settings.show then self.arrow:Hide();return end
    self.arrow:Show();self.arrow.title:SetText(stop.loc.place)
    if WorldMapFrame and WorldMapFrame:IsShown() then self.arrow.icon:Hide();self.arrow.info:SetText("Close the map for live direction");return end
    if IsInInstance and IsInInstance() then self.arrow.icon:Hide();self.arrow.info:SetText("Inside instance - consult the boss / mob list");return end
    local p=self.runtime.position
    local angle,distance
    if p then angle,distance=self:Bearing(p,stop,GetPlayerFacing and GetPlayerFacing() or 0) end
    if angle then
        self.arrow.icon:Show()
        -- Rotate UVs, compatible with original 3.3.5 textures (SetRotation is not required).
        local c,s=math.cos(-angle),math.sin(-angle)
        local function uv(x,y)return .5+x*c-y*s,.5+x*s+y*c end
        local ulx,uly=uv(-.5,-.5);local llx,lly=uv(-.5,.5);local urx,ury=uv(.5,-.5);local lrx,lry=uv(.5,.5)
        self.arrow.icon:SetTexCoord(ulx,uly,llx,lly,urx,ury,lrx,lry)
        if distance<65 then self.arrow.info:SetText("Farm here - stay until collected")
        else self.arrow.info:SetText(string.format("%.0f yd straight-line  |  %d tome%s",distance,#stop.targets,#stop.targets==1 and "" or "s")) end
    else
        self.arrow.icon:Hide()
        self.arrow.info:SetText("Travel to "..(stop.loc.zone or stop.loc.place).." - open map for details")
    end
end
