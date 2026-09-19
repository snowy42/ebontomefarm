-- Deliberately restricted 3.3.5 API mock. Unknown frame methods fail rather than silently pass.
Mock={frames={},messages={},player={mapID=479,x=.48,y=.54},facing=0,bags={},discovered={},book={},inside=false,map=479,level=0,mapSwitches=0}
local M=Mock
local methods={}
local function plain(s)return tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")end
local function fractions(p)
    local x=p:find("LEFT")and 0 or p:find("RIGHT")and 1 or .5
    local y=p:find("TOP")and 0 or p:find("BOTTOM")and 1 or .5
    return x,y
end
local function new(kind,name,parent)
    local f=setmetatable({kind=kind,name=name,parent=parent,points={},scripts={},children={},shown=true,scale=1,level=1,strata="MEDIUM",fontSize=12},{__index=methods})
    M.frames[#M.frames+1]=f;if name then _G[name]=f end
    if parent then parent.children[#parent.children+1]=f end
    return f
end
function methods:GetName()return self.name end
function methods:GetParent()return self.parent end
function methods:SetParent(p)self.parent=p end
function methods:SetPoint(p,rel,rp,x,y)
    if type(rel)=="number"then y=rp;x=rel;rel=self.parent;rp=p end
    rel=rel or self.parent;rp=rp or p;x=x or 0;y=y or 0
    self.points[p]={p=p,rel=rel,rp=rp,x=x,y=y};self.firstPoint=self.firstPoint or p
end
function methods:ClearAllPoints()self.points={};self.firstPoint=nil end
function methods:GetPoint()
    local p=self.points[self.firstPoint];if p then return p.p,p.rel,p.rp,p.x,p.y end
end
function methods:SetAllPoints(rel)
    self:ClearAllPoints();self:SetPoint("TOPLEFT",rel or self.parent,"TOPLEFT");self:SetPoint("BOTTOMRIGHT",rel or self.parent,"BOTTOMRIGHT")
end
function methods:Rect()
    if self.root then return self.root[1],self.root[2],self.root[3],self.root[4] end
    if self.measuring then error("Cyclic anchors for "..tostring(self.name or self.kind))end
    self.measuring=true
    local anchors={}
    for _,p in pairs(self.points)do
        local rx,ry,rw,rh=0,0,1600,1000
        if p.rel then rx,ry,rw,rh=p.rel:Rect()end
        local fx,fy=fractions(p.p);local rfx,rfy=fractions(p.rp)
        anchors[#anchors+1]={fx=fx,fy=fy,x=rx+rw*rfx+p.x,y=ry+rh*rfy-p.y}
    end
    local w,h=self.w,self.h
    for i=1,#anchors do for j=i+1,#anchors do
        local a,b=anchors[i],anchors[j]
        if not w and a.fx~=b.fx then w=(b.x-a.x)/(b.fx-a.fx)end
        if not h and a.fy~=b.fy then h=(b.y-a.y)/(b.fy-a.fy)end
    end end
    if self.kind=="FontString"then
        w=w or math.max(1,#plain(self.text)*self.fontSize*.52)
        if not h then
            local lines=0
            for line in (plain(self.text).."\n"):gmatch("(.-)\n")do lines=lines+math.max(1,self.wordWrap==false and 1 or math.ceil(#line*self.fontSize*.52/math.max(1,w)))end
            h=lines*self.fontSize*1.2
        end
    end
    w,h=w or 0,h or 0
    local a=anchors[1];local x,y=0,0
    if a then x,y=a.x-a.fx*w,a.y-a.fy*h end
    self.measuring=false;return x,y,w,h
end
function methods:GetWidth()local _,_,w=self:Rect();return w end
function methods:GetHeight()local _,_,_,h=self:Rect();return h end
function methods:SetWidth(v)assert(type(v)=="number");self.w=v;if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,v,self.h or 0)end end
function methods:SetHeight(v)assert(type(v)=="number");self.h=v;if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,self.w or 0,v)end end
function methods:Show()local old=self.shown;self.shown=true;if not old and self.scripts.OnShow then self.scripts.OnShow(self)end end
function methods:Hide()self.shown=false;if self.scripts.OnHide then self.scripts.OnHide(self)end end
function methods:IsShown()return self.shown end
function methods:IsVisible()return self.shown and(not self.parent or self.parent:IsVisible())end
function methods:SetScript(k,f)self.scripts[k]=f end
function methods:GetScript(k)return self.scripts[k]end
function methods:HookScript(k,f)local old=self.scripts[k];self.scripts[k]=function(...)if old then old(...)end;f(...)end end
function methods:RegisterEvent(e)self.events=self.events or {};self.events[e]=true end
function methods:SetFrameStrata(s)self.strata=s end
function methods:SetFrameLevel(v)self.level=v end
function methods:GetFrameLevel()return self.level end
function methods:SetScale(v)self.scale=v end
function methods:GetScale()return self.scale end
function methods:SetFont(path,size,flags)self.font=path;self.fontSize=size;self.fontFlags=flags end
function methods:SetFontObject(_)self.fontSize=12 end
function methods:SetText(t)
    assert(type(t)=="string"or type(t)=="number","SetText requires a string/number, got "..type(t));self.text=tostring(t)
    if self.kind=="EditBox"and self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false)end
end
function methods:GetText()return self.text or ""end
function methods:GetStringHeight()return self:GetHeight()end
function methods:GetStringWidth()return #plain(self.text)*self.fontSize*.52 end
function methods:SetTextColor(...)self.color={...}end
function methods:SetVertexColor(...)self.color={...}end
function methods:SetWordWrap(v)self.wordWrap=v end
function methods:SetJustifyH(v)self.justifyH=v end
function methods:SetJustifyV(v)self.justifyV=v end
function methods:SetBackdrop(v)self.backdrop=v end
function methods:SetBackdropColor(...)self.bg={...}end
function methods:SetBackdropBorderColor(...)self.border={...}end
function methods:CreateFontString(name,layer)local f=new("FontString",name,self);f.layer=layer;return f end
function methods:CreateTexture(name,layer)local f=new("Texture",name,self);f.layer=layer;return f end
function methods:SetTexture(t)self.texture=t end
function methods:SetTexCoord(...)self.uv={...}end
function methods:SetNormalTexture(t)self.normal=t end
function methods:SetStatusBarTexture(t)self.barTexture=t end
function methods:SetStatusBarColor(...)self.barColor={...}end
function methods:SetThumbTexture(t)self.thumb=new("Texture",nil,self);self.thumb:SetTexture(t)end
function methods:GetThumbTexture()return self.thumb end
function methods:SetMinMaxValues(a,b)assert(a<=b);self.min,self.max=a,b end
function methods:SetValue(v)
    self.value=math.max(self.min or 0,math.min(self.max or 1,v));if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,self.value)end
end
function methods:GetValue()return self.value end
function methods:SetChecked(v)self.checked=v and true or false end
function methods:GetChecked()return self.checked end
function methods:SetScrollChild(c)self.scrollChild=c;c:ClearAllPoints();c:SetPoint("TOPLEFT",self,"TOPLEFT",0,self.offset or 0)end
function methods:SetVerticalScroll(v)self.offset=math.max(0,v);if self.scrollChild then self.scrollChild:SetPoint("TOPLEFT",self,"TOPLEFT",0,self.offset)end end
function methods:GetVerticalScroll()return self.offset or 0 end
function methods:SetFocus()self.focused=true end
function methods:ClearFocus()self.focused=false end
function methods:SetMaxLetters(v)self.maxLetters=v end
function methods:SetMultiLine(v)self.multiline=v end
function methods:SetMovable(v)self.movable=v end
function methods:SetResizable(v)self.resizable=v end
function methods:SetMinResize(w,h)self.minW,self.minH=w,h end
function methods:SetMaxResize(w,h)self.maxW,self.maxH=w,h end
function methods:StartMoving()self.moving=true end
function methods:StartSizing()self.sizing=true end
function methods:StopMovingOrSizing()self.moving=false;self.sizing=false end
function methods:SetOwner(f,anchor)self.owner=f end
function methods:AddLine(t)self.lines=self.lines or {};self.lines[#self.lines+1]=t end
for _,name in ipairs({"EnableMouse","EnableMouseWheel","RegisterForDrag","RegisterForClicks","SetClampedToScreen","SetOrientation","SetValueStep","SetAutoFocus","SetTextInsets"})do methods[name]=function()end end
function CreateFrame(kind,name,parent,template)local f=new(kind,name,parent);f.template=template;return f end
UIParent=new("Frame","UIParent");UIParent.root={0,0,1600,1000}
WorldMapFrame=new("Frame","WorldMapFrame",UIParent);WorldMapFrame.root={100,70,1002,668};WorldMapFrame:Hide()
WorldMapButton=new("Button","WorldMapButton",WorldMapFrame);WorldMapButton:SetAllPoints(WorldMapFrame)
Minimap=new("Frame","Minimap",UIParent);Minimap.root={1440,10,140,140}
GameTooltip=new("GameTooltip","GameTooltip",UIParent);GameTooltip:Hide()
DEFAULT_CHAT_FRAME={AddMessage=function(_,s)M.messages[#M.messages+1]=s end}
UISpecialFrames={};SlashCmdList={};ChatFontNormal={};BOOKTYPE_SPELL="spell";STANDARD_TEXT_FONT="Fonts\\FRIZQT__.TTF"
function ShowUIPanel(f)f:Show()end
function HideUIPanel(f)f:Hide()end
function GetMapContinents()return "Kalimdor","Eastern Kingdoms","Outland","Northrend"end
local function zones(c)
    local r={};for id,z in pairs(EbonTomeFarm.Data.zones)do if z.c==c and not z.continent then r[#r+1]={id=id,name=z.name}end end
    table.sort(r,function(a,b)return a.id<b.id end);return r
end
function GetMapZones(c)local r={};for _,z in ipairs(zones(c))do r[#r+1]=z.name end;return unpack(r)end
function SetMapZoom(c,z)
    M.mapSwitches=M.mapSwitches+1;M.level=0
    if c==0 then M.map=0 elseif z==0 then
        for id,m in pairs(EbonTomeFarm.Data.zones)do if m.continent and m.c==c then M.map=id end end
    else local zz=zones(c)[z];assert(zz);M.map=zz.id end
end
function GetCurrentMapAreaID()return M.map end
function GetCurrentMapContinent()local z=EbonTomeFarm.Data.zones[M.map];return z and z.c or 0 end
function GetCurrentMapZone()for i,z in ipairs(zones(GetCurrentMapContinent()))do if z.id==M.map then return i end end;return 0 end
function GetCurrentMapDungeonLevel()return M.level end
function SetDungeonMapLevel(l)M.level=l end
function SetMapByID(mid)M.map=mid;M.level=0;M.mapSwitches=M.mapSwitches+1 end
function SetMapToCurrentZone()M.map=M.player.mapID;M.mapSwitches=M.mapSwitches+1 end
function GetPlayerMapPosition()if M.map==M.player.mapID then return M.player.x,M.player.y end;return 0,0 end
function GetPlayerFacing()return M.facing end
function IsInInstance()return M.inside end
function GetSubZoneText()return "Recorded test camp"end
function UnitName(u)if u=="target"then return M.targetName end;return "TestPlayer"end
function GetContainerNumSlots(b)return #(M.bags[b]or{})end
function GetContainerItemLink(b,s)return (M.bags[b]or{})[s]end
function GetNumSpellTabs()return 1 end
function GetSpellTabInfo()return "Echoes",nil,0,#M.book end
function GetSpellLink(slot)return M.book[slot]and"|Hspell:"..M.book[slot].."|h[Test]|h"end
function GetSpellInfo(id)local p=ProjectEbonhold and ProjectEbonhold.PerkDatabase[id];return p and p.comment end
function M.Click(f,which)
    assert(f,"Missing clickable frame")
    if f.kind=="CheckButton"then f.checked=not f.checked end
    if f.scripts.OnClick then f.scripts.OnClick(f,which or "LeftButton")end
end
function M.Emit(event,...)
    for _,f in ipairs(M.frames)do if f.events and f.events[event]and f.scripts.OnEvent then f.scripts.OnEvent(f,event,...)end end
end
function M.Tick(n)
    for _=1,n or 1 do
        for _,f in ipairs(M.frames)do if f.scripts.OnUpdate and f:IsVisible()then f.scripts.OnUpdate(f,.2)end end
    end
end
return M
