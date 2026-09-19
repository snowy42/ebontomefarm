-- Lightweight original 3.3.5 widgets. Uses only textures/fonts shipped with the client.
local A,U=EbonTomeFarm,EbonTomeFarm.util
local function shown(f,v)if v then f:Show()else f:Hide()end end
local C={gold={.84,.70,.42},text={.92,.94,.98},muted={.58,.64,.73},green={.42,.85,.64},purple={.66,.57,.92}}
A.UI={};local UI=A.UI
local function size(f,w,h)f:SetWidth(w);f:SetHeight(h)end
local function text(parent,content,size_,x,y,w,color)
    local t=parent:CreateFontString(nil,"OVERLAY");t:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size_ or 12)
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x or 0,y or 0);t:SetJustifyH("LEFT");t:SetJustifyV("TOP")
    if w then t:SetWidth(w)end;t:SetTextColor(unpack(color or C.text));t:SetText(content or "");return t
end
local function skin(f,r,g,b,a)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
    f:SetBackdropColor(r or .055,g or .065,b or .085,a or .97);f:SetBackdropBorderColor(.22,.25,.31,1)
end
local function tip(f,title,body)
    f:SetScript("OnEnter",function(self)GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:AddLine(title,unpack(C.gold));GameTooltip:AddLine(body,1,1,1,true);GameTooltip:Show()end)
    f:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
local function button(parent,label,w,h,click)
    local b=CreateFrame("Button",nil,parent);size(b,w,h or 24);skin(b,.11,.13,.17,1)
    b.label=text(b,label,11,0,0,nil);b.label:ClearAllPoints();b.label:SetPoint("CENTER",b,"CENTER");b.label:SetJustifyH("CENTER");b.label:SetWordWrap(false);b.label:SetWidth(w-12)
    b:SetScript("OnClick",click);b:SetScript("OnEnter",function(self)self:SetBackdropBorderColor(unpack(C.gold))end)
    b:SetScript("OnLeave",function(self)self:SetBackdropBorderColor(.22,.25,.31,1)end)
    return b
end
local function movable(f,key)
    f:SetMovable(true);f:EnableMouse(true);f:SetClampedToScreen(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self)if key~="position" or not A.char.settings.locked then self:StartMoving()end end)
    f:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing();local p,_,rp,x,y=self:GetPoint();A.char[key]={p=p,rp=rp,x=x,y=y}
    end)
end
local function position(f,key,point,x,y)
    local p=A.char[key];f:ClearAllPoints()
    if type(p)=="table" and p.p and tonumber(p.x) and tonumber(p.y) then f:SetPoint(p.p,UIParent,p.rp or p.p,p.x,p.y)
    else f:SetPoint(point,UIParent,point,x,y)end
end
local function dialog(name,title,w,h)
    local f=CreateFrame("Frame",name,UIParent);size(f,w,h);f:SetFrameStrata("FULLSCREEN_DIALOG");skin(f)
    f:SetPoint("CENTER",UIParent,"CENTER");movable(f,name.."Position")
    f.heading=text(f,title,16,16,-16,w-64,C.gold)
    f.close=button(f,"x",24,24,function()f:Hide()end);f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-10,-10)
    UISpecialFrames=UISpecialFrames or {};UISpecialFrames[#UISpecialFrames+1]=name;f:Hide();return f
end
local function edit(parent,w,h,multi)
    local e=CreateFrame("EditBox",nil,parent);size(e,w,h);e:SetAutoFocus(false);e:SetFontObject(ChatFontNormal)
    e:SetTextInsets(8,8,6,6);e:SetMultiLine(multi or false);e:SetMaxLetters(multi and 524288 or 100)
    e:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
    if not multi then skin(e,.035,.045,.065,1)end
    return e
end
local function slider(parent)
    local s=CreateFrame("Slider",nil,parent);s:SetOrientation("VERTICAL");s:SetMinMaxValues(0,1);s:SetValueStep(1)
    s:SetThumbTexture("Interface\\Buttons\\WHITE8X8");local t=s:GetThumbTexture();size(t,7,30);t:SetVertexColor(.45,.49,.58,1)
    return s
end
function A:Confirm(message,accept)
    if not UI.confirm then
        local f=dialog("EbonTomeFarmConfirm","Confirm",370,156);UI.confirm=f
        f.message=text(f,"",12,16,-52,338)
        f.yes=button(f,"Confirm",98,26,function()local fn=f.accept;f:Hide();if fn then fn()end end);f.yes:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-16,14)
        f.no=button(f,"Cancel",98,26,function()f:Hide()end);f.no:SetPoint("RIGHT",f.yes,"LEFT",-8,0)
    end
    UI.confirm.message:SetText(message);UI.confirm.accept=accept;UI.confirm:Show()
end
function A:Pick(title,items,callback)
    if not UI.picker then
        local f=dialog("EbonTomeFarmPicker","Choose build",390,400);UI.picker=f;f.rows={}
        for i=1,8 do
            local b=button(f,"",354,32,function(self)
                local item=f.items[(f.page-1)*8+self.index];if item then f:Hide();f.callback(item)end
            end);b.index=i;b:SetPoint("TOPLEFT",f,"TOPLEFT",18,-52-(i-1)*37);b.label:SetWidth(330);f.rows[i]=b
        end
        f.previous=button(f,"<",32,25,function()f.page=math.max(1,f.page-1);A:RenderPicker()end);f.previous:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",18,14)
        f.next=button(f,">",32,25,function()f.page=math.min(math.max(1,math.ceil(#f.items/8)),f.page+1);A:RenderPicker()end);f.next:SetPoint("LEFT",f.previous,"RIGHT",8,0)
        f.pageText=text(f,"",11,110,-366,252,C.muted)
    end
    local f=UI.picker;f.heading:SetText(title);f.items=items;f.callback=callback;f.page=1;self:RenderPicker();f:Show()
end
function A:RenderPicker()
    local f=UI.picker
    for i,b in ipairs(f.rows) do
        local item=f.items[(f.page-1)*8+i]
        if item then b.label:SetText(item.title or "Untitled");b:Show()else b:Hide()end
    end
    f.pageText:SetText(#f.items==0 and "No saved builds found." or string.format("Page %d / %d",f.page,math.ceil(#f.items/8)))
end
function A:ShowBuilds()
    local items={};for _,b in ipairs(self.db.builds)do items[#items+1]={id=b.id,title=b.title}end
    self:Pick("Your farming builds",items,function(b)A:SelectBuild(b.id)end)
end
function A:ShowImport()
    if not UI.import then
        local f=dialog("EbonTomeFarmImport","Import a farming build",520,440);UI.import=f
        text(f,"Paste an EbonholdHub export, EBH1 / EWL1 loadout, or echo names.\nUse Export on the build page, not the page URL.",11,18,-49,484,C.muted)
        local border=CreateFrame("Frame",nil,f);skin(border,.035,.045,.065,1);border:SetPoint("TOPLEFT",f,"TOPLEFT",18,-96);size(border,484,226)
        local scroll=CreateFrame("ScrollFrame","EbonTomeFarmImportScroll",border,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",border,"TOPLEFT",4,-4);scroll:SetPoint("BOTTOMRIGHT",border,"BOTTOMRIGHT",-26,4)
        f.input=edit(scroll,452,212,true);scroll:SetScrollChild(f.input)
        f.input:SetScript("OnCursorChanged",function(_,_,y,_,h)
            local offset=scroll:GetVerticalScroll();local bottom=-y+h
            if -y<offset then scroll:SetVerticalScroll(-y)elseif bottom>offset+scroll:GetHeight() then scroll:SetVerticalScroll(bottom-scroll:GetHeight())end
        end)
        f.input:SetScript("OnTextChanged",function()f.pending=nil;f.result:SetText("Preview before importing. Existing builds and collection marks are kept.")end)
        f.result=text(f,"",11,18,-333,482,C.muted)
        local function preview()
            local b,err=A:ParseImport(f.input:GetText());f.pending=b
            if not b then f.result:SetText("|cffff907b"..U.clean(err).."|r");return end
            A:PreviewImport(b)
        end
        f.preview=button(f,"Preview",86,28,preview);f.preview:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",18,18)
        f.hub=button(f,"From Hub",88,28,function()
            A:Pick("Copy an installed Hub build",A:GetHubBuilds(),function(item)
                local b,err=A:ParseHubData(item.data)
                if b then f.pending=b;A:PreviewImport(b)else f.result:SetText(U.clean(err))end
            end)
        end);f.hub:SetPoint("LEFT",f.preview,"RIGHT",8,0)
        f.save=button(f,"Import build",124,28,function()
            if not f.pending then preview();return end
            local b,err=A:SaveBuild(f.pending)
            if b then f:Hide();A:Print("Imported "..b.title..". Your permanent collection is scanned separately.")
            else f.result:SetText(U.clean(err))end
        end);f.save:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-18,18)
    end
    UI.import:Show();UI.import.input:SetFocus()
end
function A:PreviewImport(b)
    local seen,unique,mapped={},0,0
    for _,raw in ipairs(b.targets)do
        local t=self:ResolveTarget(raw)
        if not seen[t.key]then seen[t.key]=true;unique=unique+1
            for _,l in ipairs(self:TargetLocations(t))do if l.mapID and l.x then mapped=mapped+1;break end end
        end
    end
    UI.import.result:SetText(string.format("|cffd6b36a%s|r\n%d unique echoes  |  %d with native pins  |  %d need other guidance\nF-tier and pool entries excluded. Click Import build to save.",U.clean(b.title),unique,mapped,unique-mapped))
end
function A:ShowDetails(t,loc)
    if not t then return end
    if not UI.details then
        local f=dialog("EbonTomeFarmDetails","Tome details",434,490);UI.details=f
        f:SetPoint("CENTER",UIParent,"CENTER",220,0)
        f.status=text(f,"",11,16,-48,400,C.green);f.source=text(f,"",11,60,-83,302,C.muted)
        f.previous=button(f,"<",30,24,function()A:CycleSource(-1)end);f.previous:SetPoint("TOPLEFT",f,"TOPLEFT",16,-77)
        f.next=button(f,">",30,24,function()A:CycleSource(1)end);f.next:SetPoint("TOPRIGHT",f,"TOPRIGHT",-16,-77)
        f.map=button(f,"Open map",95,24,function()A:ShowLocation(f.target,f.loc)end);f.map:SetPoint("TOPLEFT",f,"TOPLEFT",16,-112)
        f.nav=button(f,"Farm this source",140,24,function()if f.loc then A:NavigateLocation(f.target,f.loc)end end);f.nav:SetPoint("LEFT",f.map,"RIGHT",8,0)
        local scroll=CreateFrame("ScrollFrame","EbonTomeFarmDetailScroll",f,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",f,"TOPLEFT",16,-151);scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-32,62)
        local content=CreateFrame("Frame",nil,scroll);size(content,380,260);scroll:SetScrollChild(content)
        f.description=text(content,"",12,0,0,375);f.content=content;f.scroll=scroll
        f.done=button(f,"Collected",92,27,function()A:SetManual(f.target.key,"done");A:ShowDetails(f.target,f.loc)end);f.done:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",16,18)
        f.auto=button(f,"Auto detect",95,27,function()A:SetManual(f.target.key,nil);A:ScanCollection();A:ShowDetails(f.target,f.loc)end);f.auto:SetPoint("LEFT",f.done,"RIGHT",8,0)
        f.record=button(f,"Record here",102,27,function()
            A:Confirm("Record your character's current outdoor position for this echo?",function()
                if WorldMapFrame and WorldMapFrame:IsShown() then HideUIPanel(WorldMapFrame)end
                local ok,err=A:RecordLocation(f.target)
                if ok then A:ShowDetails(f.target,A:TargetLocations(f.target)[1])else A:Print(err)end
            end)
        end);f.record:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-16,18)
    end
    local f=UI.details;f.target=t;f.loc=loc;f.locations=self:TargetLocations(t);f.index=1
    for i,l in ipairs(f.locations)do if loc and l.id==loc.id then f.index=i end end
    f.heading:SetText(t.name);f.heading:SetWordWrap(false);local _,status=self:Status(t);f.status:SetText(status.."  |  "..(t.locked and "Locked echo" or "Tier "..t.tier))
    f.source:SetText(#f.locations>0 and string.format("Source %d of %d",f.index,#f.locations)or "No source record")
    local lines={}
    local function add(label,value)lines[#lines+1]="|cffd6b36a"..label.."|r\n"..U.clean(value or "Unknown")end
    if loc then
        add("WHERE",loc.place..(loc.zone and "\n"..loc.zone or ""))
        if loc.x then add("MAP POSITION",string.format("%.1f, %.1f",loc.x*100,loc.y*100))end
        add((loc.kind=="raid" or loc.kind=="dungeon") and "BOSSES / MOBS" or "FARM THESE MOBS",table.concat(loc.mobs or {},"\n"))
        local accuracy={npc="Native NPC spawn. Representative farming point, not a guaranteed drop or exact community pin.",entrance="Exterior instance entrance. Kill the bosses/mobs listed above inside; the pin is not their room.",landmark="Nearby entrance / area landmark, not an exact mob position.",zone="Zone known; no verified pinpoint. This source is not auto-routed.",unmapped="No reliable coordinates. This source is not auto-routed.",custom="Your character's recorded position."}
        add("PIN CONFIDENCE",accuracy[loc.accuracy] or "Unverified")
        if loc.pinMob then add("NATIVE PIN NPC",loc.pinMob)end
        if loc.inferredNPC then add("NAME MATCH NOTE","Community shorthand was matched to a likely NPC name. Confirm the mob and tome drop in game.")end
        if loc.warning then add("SOURCE WARNING",loc.warning)end
        if loc.notes and loc.notes~="" then add("COMMUNITY NOTES",loc.notes)end
        if loc.kind=="raid" and not self.char.settings.raids then add("ROUTE FILTER","Raid stops are currently disabled in Settings.")end
        if loc.kind=="dungeon" and not self.char.settings.dungeons then add("ROUTE FILTER","Dungeon stops are currently disabled in Settings.")end
        for _,stop in ipairs(self.runtime.route)do
            if stop.targetLocs[t.key] and stop.targetLocs[t.key].id==loc.id and #stop.targets>1 then
                local related={}
                for _,other in ipairs(stop.targets)do if other.key~=t.key then
                    local source=stop.targetLocs[other.key];related[#related+1]=other.name..": "..table.concat(source.mobs or {},", ")
                end end
                if #related>0 then add("ALSO NEEDED AT THIS STOP",table.concat(related,"\n"))end
                break
            end
        end
        add("DATA","World of Echoes community reports + native PE-Questie map data. Snapshot: "..self.Data.meta.date..". No measured drop-rate data.")
    else
        add("NO MATCHING TOME",t.innate and "The native perk database identifies this as having no tome requirement." or "This echo is not matched to the bundled tome database. It remains in your checklist; no farm location has been invented.")
        add("WHAT YOU CAN DO","Check the spelling and native echo ID, or record a verified farming spot using Record here. You can also mark it collected manually.")
    end
    f.description:SetText(table.concat(lines,"\n\n"));f.content:SetHeight(math.max(270,f.description:GetStringHeight()+12));f.scroll:SetVerticalScroll(0);f:Show()
end
function A:CycleSource(delta)
    local f=UI.details;if #f.locations==0 then return end
    local index=(f.index-1+delta)%#f.locations+1;self:ShowLocation(f.target,f.locations[index])
end
function A:ShowSettings()
    if not UI.settings then
        local f=dialog("EbonTomeFarmSettings","Farming preferences",374,430);UI.settings=f;f.checks={}
        local entries={{"hideDone","Hide collected echoes"},{"dungeons","Include dungeon stops"},{"raids","Include raid stops"},{"tomtom","Use legacy TomTom when installed"},{"autoAdvance","Advance after collecting a stop's tomes"},{"minimap","Show minimap button"},{"locked","Lock tracker position"}}
        for i,e in ipairs(entries)do
            local cb=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate");size(cb,25,25);cb:SetPoint("TOPLEFT",f,"TOPLEFT",16,-48-(i-1)*31)
            text(cb,e[2],12,30,-6,300);cb.key=e[1];f.checks[#f.checks+1]=cb
            cb:SetScript("OnClick",function(self)A.char.settings[self.key]=not not self:GetChecked();A:Refresh()
                if self.key=="tomtom" and A:ActiveStop()then A:SetWaypoint(A:ActiveStop())end
            end)
        end
        f.tier=button(f,"",160,25,function()
            local tiers={C="B",B="A",A="S",S="C"};A.char.settings.minimumTier=tiers[A.char.settings.minimumTier]or"C";A:Refresh();A:ShowSettings()
        end);f.tier:SetPoint("TOPLEFT",f,"TOPLEFT",18,-273)
        f.minus=button(f,"Scale -",78,25,function()A.char.settings.scale=U.clamp(A.char.settings.scale-.05,.7,1.6);A:Render()end);f.minus:SetPoint("LEFT",f.tier,"RIGHT",10,0)
        f.plus=button(f,"+",28,25,function()A.char.settings.scale=U.clamp(A.char.settings.scale+.05,.7,1.6);A:Render()end);f.plus:SetPoint("LEFT",f.minus,"RIGHT",6,0)
        f.reset=button(f,"Reset positions",140,25,function()A:ResetPositions()end);f.reset:SetPoint("TOPLEFT",f,"TOPLEFT",18,-312)
        f.delete=button(f,"Delete this build",158,25,function()
            local b=A:GetBuild();if b then A:Confirm("Delete the farming build '"..b.title.."'? Collection marks are kept.",function()A:DeleteBuild(b.id)end)end
        end);f.delete:SetPoint("LEFT",f.reset,"RIGHT",10,0)
        text(f,"Right-click a tracker row to clear its manual override.\nArrival never marks a tome collected.\n/etf toggles the tracker; /etf help lists commands.",11,18,-355,335,C.muted)
    end
    for _,cb in ipairs(UI.settings.checks)do cb:SetChecked(self.char.settings[cb.key])end
    UI.settings.tier.label:SetText("Minimum tier: "..self.char.settings.minimumTier);UI.settings:Show()
end
function A:ResetPositions()
    self.char.position=nil;self.char.arrowPosition=nil;self.char.settings.scale=1
    self.char.settings.width=354;self.char.settings.height=500
    position(self.frame,"position","TOPRIGHT",-35,-200);position(self.arrow,"arrowPosition","TOP",0,-135);self:Render()
end
function A:CreateUI()
    local f=CreateFrame("Frame","EbonTomeFarmTracker",UIParent);self.frame=f;skin(f);f:SetFrameStrata("MEDIUM");movable(f,"position")
    position(f,"position","TOPRIGHT",-35,-200);f:SetResizable(true);f:SetMinResize(344,418);f:SetMaxResize(600,900)
    local accent=f:CreateTexture(nil,"OVERLAY");accent:SetTexture("Interface\\Buttons\\WHITE8X8");accent:SetVertexColor(unpack(C.gold));accent:SetHeight(2);accent:SetPoint("TOPLEFT",f,"TOPLEFT",1,-1);accent:SetPoint("TOPRIGHT",f,"TOPRIGHT",-1,-1)
    text(f,"EBON TOME FARM",14,13,-14,245,C.gold);text(f,"BUILD  /  COLLECT  /  EXPLORE",9,14,-35,265,C.muted)
    local close=button(f,"x",20,20,function()A.char.settings.show=false;A:Render()end);close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-9,-9)
    local collapse=button(f,"-",20,20,function()A.char.settings.collapsed=not A.char.settings.collapsed;A:Render()end);collapse:SetPoint("RIGHT",close,"LEFT",-4,0)
    UI.build=button(f,"Choose a build",240,24,function()A:ShowBuilds()end);UI.build:SetPoint("TOPLEFT",f,"TOPLEFT",12,-56)
    UI.importButton=button(f,"Import",66,24,function()A:ShowImport()end);UI.importButton:SetPoint("TOPRIGHT",f,"TOPRIGHT",-12,-56)
    UI.progressLabel=text(f,"",11,13,-89,310,C.muted)
    local track=CreateFrame("StatusBar",nil,f);UI.progress=track;track:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");track:SetStatusBarColor(unpack(C.gold));track:SetMinMaxValues(0,1);track:SetValue(0)
    track:SetPoint("TOPLEFT",f,"TOPLEFT",13,-109);track:SetPoint("TOPRIGHT",f,"TOPRIGHT",-13,-109);track:SetHeight(3)
    local bg=track:CreateTexture(nil,"BACKGROUND");bg:SetTexture("Interface\\Buttons\\WHITE8X8");bg:SetAllPoints();bg:SetVertexColor(.17,.20,.25,1)
    local body=CreateFrame("Frame",nil,f);UI.body=body;body:SetPoint("TOPLEFT",f,"TOPLEFT",12,-123);body:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-12,8)
    local card=CreateFrame("Button",nil,body);UI.card=card;skin(card,.085,.085,.12,1);card:SetPoint("TOPLEFT",body,"TOPLEFT");card:SetPoint("TOPRIGHT",body,"TOPRIGHT");card:SetHeight(62)
    card.caption=text(card,"NEXT FARM",9,10,-8,290,C.purple);card.title=text(card,"Import a build to get started",12,10,-23,290);card.info=text(card,"",10,10,-42,290,C.muted)
    card.title:SetWordWrap(false);card.info:SetWordWrap(false)
    card:SetScript("OnClick",function()local s=A:ActiveStop()or A.runtime.route[1];if s then A:ShowLocation(s.targets[1],s.loc)end end)
    UI.start=button(body,"Start route",92,25,function()if A.runtime.running then A:PauseRoute()else A:StartRoute()end end);UI.start:SetPoint("TOPLEFT",body,"TOPLEFT",0,-73)
    UI.next=button(body,"Skip",58,25,function()A:SkipStop()end);UI.next:SetPoint("LEFT",UI.start,"RIGHT",6,0);tip(UI.next,"Defer this stop","Keeps its tomes on your checklist. Replan restores deferred stops.")
    UI.replan=button(body,"Replan",66,25,function()A:Replan()end);UI.replan:SetPoint("LEFT",UI.next,"RIGHT",6,0)
    UI.settingsButton=button(body,"Settings",83,25,function()A:ShowSettings()end);UI.settingsButton:SetPoint("TOPRIGHT",body,"TOPRIGHT",0,-73)
    UI.search=edit(body,206,25,false);UI.search:SetPoint("TOPLEFT",body,"TOPLEFT",0,-108)
    UI.search:SetScript("OnTextChanged",function(self)A.runtime.search=self:GetText();A.runtime.scroll=0;A:RenderRows()end)
    UI.searchHint=text(UI.search,"Search echoes or zones...",10,8,-7,194,C.muted)
    UI.filter=button(body,"Needed",105,25,function()A.char.settings.hideDone=not A.char.settings.hideDone;A.runtime.scroll=0;A:Render()end);UI.filter:SetPoint("TOPRIGHT",body,"TOPRIGHT",0,-108)
    local list=CreateFrame("Frame",nil,body);UI.list=list;list:SetPoint("TOPLEFT",body,"TOPLEFT",0,-146);list:SetPoint("BOTTOMRIGHT",body,"BOTTOMRIGHT",0,27);list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel",function(_,d)A.runtime.scroll=math.max(0,(A.runtime.scroll or 0)-d*2);A:RenderRows()end)
    UI.rows={};UI.scroll=slider(list);UI.scroll:SetPoint("TOPRIGHT",list,"TOPRIGHT",0,-2);UI.scroll:SetPoint("BOTTOMRIGHT",list,"BOTTOMRIGHT",0,2);UI.scroll:SetWidth(9)
    UI.scroll:SetScript("OnValueChanged",function(_,v)if not UI.updating then A.runtime.scroll=math.floor(v+.5);A:RenderRows()end end)
    UI.empty=text(list,"",12,10,-22,285,C.muted)
    UI.footer=text(body,"",10,0,0,310,C.muted);UI.footer:ClearAllPoints();UI.footer:SetPoint("BOTTOMLEFT",body,"BOTTOMLEFT",0,2)
    local resize=CreateFrame("Button",nil,f);size(resize,17,17);resize:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-1,1)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");resize:SetScript("OnMouseDown",function()if not A.char.settings.locked and not A.char.settings.collapsed then UI.resizing=true;f:StartSizing("BOTTOMRIGHT")end end)
    resize:SetScript("OnMouseUp",function()f:StopMovingOrSizing();if UI.resizing then A.char.settings.width=f:GetWidth();A.char.settings.height=f:GetHeight()end;UI.resizing=false;A:Render()end)
    f:SetScript("OnSizeChanged",function()if A.db and not UI.sizing then A:LayoutRows()end end)
    self.arrow=CreateFrame("Frame","EbonTomeFarmArrow",UIParent);local arrow=self.arrow;size(arrow,316,60);skin(arrow,.045,.055,.075,.90);arrow:SetFrameStrata("MEDIUM");movable(arrow,"arrowPosition");position(arrow,"arrowPosition","TOP",0,-135)
    arrow.icon=arrow:CreateTexture(nil,"OVERLAY");size(arrow.icon,44,44);arrow.icon:SetPoint("LEFT",arrow,"LEFT",8,0);arrow.icon:SetTexture("Interface\\Minimap\\MinimapArrow")
    arrow.title=text(arrow,"",12,62,-13,244,C.gold);arrow.info=text(arrow,"",10,62,-34,244,C.muted);arrow.title:SetWordWrap(false);arrow.info:SetWordWrap(false);arrow:Hide()
    if Minimap then
        local m=CreateFrame("Button","EbonTomeFarmMinimap",Minimap);self.minimap=m;size(m,30,30);m:SetPoint("TOPLEFT",Minimap,"TOPLEFT",0,0);m:SetFrameLevel(Minimap:GetFrameLevel()+6)
        m:SetNormalTexture("Interface\\Icons\\INV_Misc_Book_09");m:RegisterForClicks("LeftButtonUp","RightButtonUp")
        m:SetScript("OnClick",function(_,which)if which=="RightButton"then A:ShowSettings()else A.char.settings.show=not A.char.settings.show;A:Render()end end)
        tip(m,"EbonTomeFarm","Left-click: show / hide tracker\nRight-click: preferences\n/etf import: import a build")
    end
    self:Render()
end
function A:LayoutRows()
    if not UI.list then return end
    local width=self.frame:GetWidth()-24
    UI.build:SetWidth(width-74);UI.build.label:SetWidth(width-94)
    UI.card.title:SetWidth(width-20);UI.card.info:SetWidth(width-20);UI.search:SetWidth(width-116);UI.searchHint:SetWidth(width-132)
    UI.progressLabel:SetWidth(width);UI.footer:SetWidth(width-6)
    local count=math.max(1,math.floor(UI.list:GetHeight()/44))
    for i=1,count do
        if not UI.rows[i] then
            local row=CreateFrame("Button",nil,UI.list);size(row,width-15,42);skin(row,.07,.085,.11,.96);row:RegisterForClicks("LeftButtonUp","RightButtonUp");UI.rows[i]=row
            row.check=CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate");size(row.check,24,24);row.check:SetPoint("LEFT",row,"LEFT",2,0)
            row.check:SetScript("OnClick",function(self)if row.target then A:SetManual(row.target.key,self:GetChecked()and"done"or"need")end end)
            row.name=text(row,"",12,32,-7,width-100);row.sub=text(row,"",10,32,-25,width-68,C.muted)
            row.name:SetWordWrap(false);row.sub:SetWordWrap(false)
            row.tier=text(row,"",10,0,0,34,C.purple);row.tier:ClearAllPoints();row.tier:SetPoint("TOPRIGHT",row,"TOPRIGHT",-7,-8);row.tier:SetJustifyH("RIGHT")
            row:SetScript("OnClick",function(self,which)
                if not self.target then return end
                if which=="RightButton"then A:SetManual(self.target.key,nil)else A:ShowLocation(self.target,A:BestLocation(self.target))end
            end)
            row:SetScript("OnEnter",function(self)
                if not self.target then return end
                self:SetBackdropBorderColor(unpack(C.gold));GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:AddLine(self.target.name,unpack(C.gold))
                local _,status=A:Status(self.target);GameTooltip:AddLine(status,1,1,1,true)
                GameTooltip:AddLine("Click: map and farming details\nCheckbox: manual collection mark\nRight-click: restore automatic detection",.65,.7,.78,true);GameTooltip:Show()
            end)
            row:SetScript("OnLeave",function(self)self:SetBackdropBorderColor(.22,.25,.31,1);GameTooltip:Hide()end)
        end
        local row=UI.rows[i];row:ClearAllPoints();row:SetPoint("TOPLEFT",UI.list,"TOPLEFT",0,-(i-1)*44);row:SetWidth(width-15)
        row.name:SetWidth(width-92);row.sub:SetWidth(width-56)
    end
    UI.visibleRows=count;self:RenderRows()
end
function A:RenderRows()
    if not UI.list then return end
    local b=self:GetBuild();local entries={};local search=U.trim(self.runtime.search or ""):lower()
    shown(UI.searchHint,search=="")
    local rank={};for i,s in ipairs(self.runtime.route)do for _,t in ipairs(s.targets)do if not rank[t.key]then rank[t.key]=i end end end
    for _,t in ipairs(b and b.targets or {})do
        local loc=self:BestLocation(t);local hay=(t.name.." "..(loc and loc.place or "").." "..(loc and loc.zone or "")):lower()
        if self:Eligible(t)and(not self.char.settings.hideDone or not self:IsDone(t))and(search==""or hay:find(search,1,true))then entries[#entries+1]={t=t,loc=loc}end
    end
    table.sort(entries,function(a,b)
        local ar,br=rank[a.t.key]or 9999,rank[b.t.key]or 9999
        if ar~=br then return ar<br end
        local at,bt=self.TierRank[a.t.tier]or 0,self.TierRank[b.t.tier]or 0
        if at~=bt then return at>bt end;return a.t.name<b.t.name
    end)
    local max=math.max(0,#entries-(UI.visibleRows or 1));self.runtime.scroll=U.clamp(self.runtime.scroll or 0,0,max)
    UI.updating=true;UI.scroll:SetMinMaxValues(0,max);UI.scroll:SetValue(self.runtime.scroll);shown(UI.scroll,max>0);UI.updating=false
    for i,row in ipairs(UI.rows)do
        local entry=entries[i+self.runtime.scroll]
        if i<=(UI.visibleRows or 1)and entry then
            local t,loc=entry.t,entry.loc;row.target=t;row.name:SetText(t.name);row.check:SetChecked(self:IsDone(t));row.tier:SetText(t.locked and "LOCK"or t.tier)
            local status,label=self:Status(t)
            row.name:SetTextColor(unpack(self:IsDone(t)and C.green or C.text))
            row.sub:SetText(self:IsDone(t)and label or loc and((loc.x and ""or "No pin: ")..(loc.zone or loc.place))or "Unmatched echo - click for options")
            row:SetBackdropBorderColor(.22,.25,.31,1);row:Show()
        else row.target=nil;row:Hide()end
    end
    shown(UI.empty,#entries==0)
    UI.empty:SetText(not b and "Turn your build into a farming checklist.\n\nClick Import above to paste your Hub export.\n\nCollection marks are saved per character."or search~=""and"No matches for this search."or"No outstanding echoes in this view.\n\nSwitch to All to review collected entries,\nor change the minimum tier in Settings.")
end
function A:Render()
    if not self.frame then return end
    UI.sizing=true;self.frame:SetScale(self.char.settings.scale)
    if not UI.resizing then self.frame:SetWidth(U.clamp(self.char.settings.width,344,600));self.frame:SetHeight(self.char.settings.collapsed and 119 or U.clamp(self.char.settings.height,418,900))end;UI.sizing=false
    shown(self.frame,self.char.settings.show);shown(UI.body,not self.char.settings.collapsed)
    if self.minimap then shown(self.minimap,self.char.settings.minimap)end
    local b=self:GetBuild();UI.build.label:SetText(b and b.title or "Choose a build")
    local total,done,noPin=0,0,0
    for _,t in ipairs(b and b.targets or {})do
        if self:Eligible(t)then total=total+1;if self:IsDone(t)then done=done+1 else
            local loc=self:BestLocation(t);if not self:LocationUsable(loc)then noPin=noPin+1 end
        end end
    end
    UI.progressLabel:SetText(string.format("%d / %d collected     %d still needed",done,total,total-done));UI.progress:SetValue(total>0 and done/total or 0)
    local s=self:ActiveStop()or self.runtime.route[1]
    UI.card.caption:SetText(self:ActiveStop()and "CURRENT FARM"or"NEXT FARM")
    UI.card.title:SetText(s and s.loc.place or b and "No routable stops remaining"or"Import a build to get started")
    UI.card.info:SetText(s and string.format("%s  |  %d tome%s",s.loc.zone or "",#s.targets,#s.targets==1 and ""or"s")or"Unmapped echoes stay in the checklist below.")
    UI.start.label:SetText(self.runtime.running and "Pause"or"Start route");UI.filter.label:SetText(self.char.settings.hideDone and "Needed"or"All echoes")
    local skipped=0;for _ in pairs(self.runtime.skipped)do skipped=skipped+1 end
    UI.footer:SetText(string.format("%d stops  /  %d no-pin  /  %d deferred",#self.runtime.route,noPin,skipped))
    self:LayoutRows();self:UpdateNavigation()
end
