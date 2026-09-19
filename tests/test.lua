local M=dofile("tests/wow_mock.lua")
for _,file in ipairs({"Core","Data","Codec","Import","Collection","Route","Navigation","UI","Events"})do dofile("EbonTomeFarm/"..file..".lua")end
local A=EbonTomeFarm;local passed=0
local function eq(a,b,why)assert(a==b,(why or "Mismatch")..": expected "..tostring(b)..", got "..tostring(a))end
local function test(name,fn)
    local ok,err=pcall(fn);if not ok then print("FAIL "..name.."\n"..err);os.exit(1)end
    passed=passed+1;print("PASS "..name)
end
local function reset()
    if WorldMapFrame:IsShown()then WorldMapFrame:Hide()end
    A:ClearTomeAlerts();A.runtime.route={};A.runtime.routeZone=nil;A.runtime.lastOutdoorPosition=nil
    A.runtime.waitingForPosition=false;A.runtime.pendingReplan=nil;A.runtime.bagSeen={};A.runtime.bagBaselineReady=false;A.runtime.bagWarmup=nil
    A.char.settings.tomeAlerts=true;A.char.settings.tomeSound=true;A.char.settings.show=true;M.sounds={};M.messages={}
    A.runtime.skipped={};A.runtime.active=nil;A.runtime.running=false;A.runtime.owned={};A.runtime.bags={};A.runtime.position=nil
    A.char.manual={};A.char.locations={};A.char.settings.minimumTier="C";A.char.settings.raids=true;A.char.settings.dungeons=true;A.char.settings.hideDone=true;A.char.settings.autoAdvance=true
    A.db.builds={};A.db.nextID=1;A.char.activeBuild=nil;M.discovered={};M.bags={};M.book={};M.inside=false
    M.player={mapID=479,x=.48,y=.54};M.facing=0
    ProjectEbonhold={PerkDatabase={
        [200001]={comment="Adaptive Power - Rare",requiredSpell=300001,quality=3},
        [200002]={comment="Adaptive Power - Epic",requiredSpell=300001,quality=4},
        [200003]={comment="Arcane Cadence - Rare",requiredSpell=300003,quality=3},
        [200004]={comment="Unlisted Test Echo - Rare",requiredSpell=0,quality=3},
        [200005]={comment="Unknown Requirement - Rare",quality=3}
    },PerkService={GetDiscoveredEchoes=function()return M.discovered end},Perks={grantedPerks={},lockedPerks={}}}
    A:BuildPerkIndex()
end
M.Emit("ADDON_LOADED","EbonTomeFarm")
test("full addon boots with original-client API mock",function()assert(A.ready);eq(#A.Data.tomes,128);eq(#A.Data.locations,173);assert(A.frame:IsShown())end)
test("no modern frame methods are assumed",function()eq(A.frame.SetShown,nil);eq(A.frame.SetSize,nil);assert(A.UI.visibleRows>=1)end)
test("Base64 byte roundtrips and URL-safe alphabet",function()
    for n=1,257 do local s={};for i=1,n do s[i]=string.char((i*41)%256)end;s=table.concat(s);eq(A.Codec.Base64Decode(A.Codec.Base64Encode(s)),s)end
    eq(A.Codec.Base64Decode("SGVsbG8"),"Hello");eq(A.Codec.Base64Decode("SGVs\nbG8="),"Hello")
end)
test("Base64 rejects truncation and malformed padding",function()
    for _,s in ipairs({"A","!!!!","Z===","=m9v","Zg=a","Zh==","Zm9=","Zg==Zg=="})do eq(A.Codec.Base64Decode(s),nil,s)end
end)
test("JSON unicode, null, booleans and numbers",function()
    local o=assert(A.Codec.JSONDecode('{"x":[true,false,null,-1.25e2],"s":"\\u0041\\ud83d\\ude00"}'))
    eq(o.x[1],true);eq(o.x[2],false);eq(o.x[3],A.Codec.NULL);eq(o.x[4],-125);eq(o.s,"A"..string.char(240,159,152,128))
end)
test("JSON parser rejects executable, malformed, deep and huge input",function()
    for _,s in ipairs({'{"a":1,"a":2}','{"a":01}','{"a":1,}','[1,]','{"a":1e999}','{"a":"\\ud800"}','{"x":function()end}','{} trailing','{"a":.2}'})do eq(A.Codec.JSONDecode(s),nil,s)end
    eq(A.Codec.JSONDecode(string.rep('[',41)..'0'..string.rep(']',41)),nil)
    eq(A.Codec.JSONDecode(string.rep(' ',524289)),nil)
end)
test("Hub Base64 imports wanted tiers, deduplicates qualities, retains locked",function()
    reset()
    local source='{"title":"Tomb test","lockedEchoes":[200001,null],"echoTiers":{"Adaptive Power|3":"B","Adaptive Power|4":"S","Arcane Cadence|3":"A","Arcane Hazard|3":"F","Arcane Ward|3":"pool"},"loadoutEchoSpellIds":{"Adaptive Power|3":200001,"Adaptive Power|4":200002}}'
    local b=assert(A:Import(A.Codec.Base64Encode(source)));eq(#b.targets,2);eq(b.targets[1].name,"Adaptive Power");assert(b.targets[1].locked);eq(b.targets[1].tier,"Locked")
end)
test("F-tier-only imports fail without changing active build",function()
    local old=A:GetBuild();eq(A:Import('{"echoTiers":{"Arcane Hazard|3":"F"}}'),nil);eq(A:GetBuild(),old)
end)
test("unknown echoes remain in checklist without fabricated pins",function()
    reset();local b=assert(A:Import('{"echoTiers":{"Completely New Echo|4":"S"}}'));eq(#b.targets,1);eq(A:Status(b.targets[1]),"unknown");eq(#A.runtime.route,0)
end)
test("explicit innate and absent requirements are distinguished",function()
    reset();local b=assert(A:Import('EWL1:MAGE:200004:0,200005:0'));local by={};for _,t in ipairs(b.targets)do by[t.name]=t end
    eq(A:Status(by["Unlisted Test Echo"]),"innate");eq(A:Status(by["Unknown Requirement"]),"unknown")
end)
test("journal EBH1 and EWL1 formats resolve native spell IDs",function()
    reset();local b=assert(A:Import("EBH1:200001.3.5,200002.2.2,200003.1.1:MAGE:My loadout"));eq(#b.targets,2);eq(b.title,"My loadout")
    b=assert(A:Import("EWL1:MAGE:200001:1,200003:0"));eq(#b.targets,2);assert(b.targets[1].locked)
    for _,s in ipairs({"EBH2:200001.3.5:MAGE:x","EBH1:200001.7.2:MAGE:x","EWL1:MAGE:99999999999:0","EWL1:MAGE:200001:2"})do eq(A:ParseImport(s),nil)end
end)
test("plain name wishlist and URLs handled explicitly",function()
    reset();local b=assert(A:Import("Adaptive Power\nArcane Cadence"));eq(#b.targets,2)
    eq(A:ParseImport("https://ebonholdhub.icu/build/123"),nil)
end)
test("native current-run echoes never count as permanent unlocks",function()
    reset();local b=assert(A:Import("Adaptive Power\nArcane Cadence"));ProjectEbonhold.Perks.grantedPerks[200001]=3;ProjectEbonhold.Perks.lockedPerks[200003]=true
    A:ScanCollection();for _,t in ipairs(b.targets)do eq(A:Status(t),"needed")end
end)
test("discovered permanent echoes resolve quality families",function()
    M.discovered[200002]=true;A:ScanCollection();eq(A:Status(A:TargetByKey("adaptivepower")),"learned")
    M.discovered={};A:ScanCollection();eq(A:Status(A:TargetByKey("adaptivepower")),"needed")
end)
test("dedicated Echoes spellbook maps permanent tome requirements",function()
    M.book={300001};A:ScanCollection();eq(A:Status(A:TargetByKey("adaptivepower")),"learned");M.book={}
end)
test("bag tomes are obtained but not falsely called learned",function()
    M.bags[0]={"|cff0070dd|Hitem:300001:0:0:0:0:0:0:0|h[Tome of Echo: Adaptive Power]|h|r"};A:ScanCollection()
    eq(A:Status(A:TargetByKey("adaptivepower")),"bag");assert(A:IsDone(A:TargetByKey("adaptivepower")))
    M.bags={};A:ScanCollection();eq(A:Status(A:TargetByKey("adaptivepower")),"needed")
end)
test("manual done/needed overrides and automatic reset",function()
    M.discovered[200001]=true;A:ScanCollection();local t=A:TargetByKey("adaptivepower")
    A:SetManual(t.key,"need");eq(A:Status(t),"needed");A:SetManual(t.key,"done");eq(A:Status(t),"manual");A:SetManual(t.key,nil);eq(A:Status(t),"learned")
end)
test("grouped stops cover shared camps without duplicate targets",function()
    reset();assert(A:Import("Adaptive Power\nArcane Cadence"));A:SamplePosition();A:Replan();local seen={}
    for _,s in ipairs(A.runtime.route)do for _,t in ipairs(s.targets)do assert(not seen[t.key]);seen[t.key]=true end end
    assert(seen.adaptivepower and seen.arcanecadence);eq(#A.runtime.route,1,"Shared Tomb of Lights camp")
end)
test("arriving does not complete target; collection advances",function()
    reset();assert(A:Import("Adaptive Power\nArcane Cadence"));A:StartRoute();local s=assert(A:ActiveStop());M.player={mapID=s.mapID,x=s.x,y=s.y};M.Tick(25)
    eq(A.runtime.active,s.id);for _,t in ipairs(s.targets)do assert(not A:IsDone(t))end
    for _,t in ipairs(s.targets)do A.char.manual[t.key]="done"end;A:Refresh();assert(A.runtime.active~=s.id)
end)
test("skip defers, replan restores, never marks collected",function()
    reset();assert(A:Import("Adaptive Power\nArcane Cadence"));A:StartRoute();local s=A:ActiveStop();A:SkipStop();assert(A.runtime.skipped[s.id])
    for _,t in ipairs(A:GetBuild().targets)do assert(not A:IsDone(t))end
    A:Replan();eq(next(A.runtime.skipped),nil);assert(#A.runtime.route>0)
end)
test("instance filters do not erase required echoes",function()
    reset();local names={};for _,t in ipairs(A.Data.tomes)do names[#names+1]=t.name end;assert(A:Import(table.concat(names,"\n")))
    local count=#A:GetBuild().targets;A.char.settings.raids=false;A.char.settings.dungeons=false;A:Refresh()
    eq(#A:GetBuild().targets,count);for _,s in ipairs(A.runtime.route)do assert(s.loc.kind~="raid"and s.loc.kind~="dungeon")end
end)
test("all generated coordinates are native, bounded and linked",function()
    local ids={};for _,t in ipairs(A.Data.tomes)do assert(not ids[t.id]);ids[t.id]=true end
    for _,l in ipairs(A.Data.locations)do
        assert(ids[l.tomeID]);if l.x then assert(l.x>0 and l.x<1 and l.y>0 and l.y<1);assert(A.Data.zones[l.mapID])end
        if l.kind=="unknown"or l.kind=="generic"then assert(not l.x)end
    end
end)
test("source contradictions are annotated rather than silently misrouted",function()
    local found=0;for _,l in ipairs(A.Data.locations)do if l.warning and l.warning:find("different instance",1,true)then eq(l.place,"Naxxramas");eq(l.instanceArea,3456);found=found+1 end end;eq(found,2)
end)
test("legacy TomTom gets percent coordinates and cleans only its own waypoint",function()
    reset();assert(A:Import("Adaptive Power\nArcane Cadence"));local added,removed={},{}
    TomTom={AddZWaypoint=function(_,c,z,x,y,title)table.insert(added,{c=c,z=z,x=x,y=y,title=title});return "ETF-"..#added end,
        RemoveWaypoint=function(_,id)table.insert(removed,id)end,SetCrazyArrow=function()end}
    A:StartRoute();local stop=A:ActiveStop();assert(#added>0);eq(added[1].x,stop.x*100);eq(added[1].y,stop.y*100);assert(added[1].z>0)
    A:PauseRoute();eq(removed[1],"ETF-1");TomTom=nil
end)
test("build switching clears stale navigation",function()
    A:StartRoute();assert(A.runtime.running);local b=assert(A:Import('{"echoTiers":{"Arcane Surge|3":"A"}}'));eq(A.runtime.running,false);eq(A.runtime.active,nil)
end)
test("sampling preserves an open map, invalidates position in instance",function()
    WorldMapFrame:Show();M.map=476;local n=M.mapSwitches;eq(A:SamplePosition(),false);eq(M.map,476);eq(M.mapSwitches,n)
    WorldMapFrame:Hide();M.inside=true;eq(A:SamplePosition(),false);eq(A.runtime.position,nil);M.inside=false
end)
test("bearing cardinal directions and cross-continent rejection",function()
    local p={mapID=479,x=.5,y=.5};local angle=A:Bearing(p,{mapID=479,x=.5,y=.4},0);eq(angle,0)
    angle=A:Bearing(p,{mapID=479,x=.6,y=.5},0);assert(math.abs(angle-math.pi/2)<.0001)
    angle=A:Bearing(p,{mapID=479,x=.4,y=.5},math.pi/2);assert(math.abs(angle)<.0001)
    eq(A:Bearing(p,{mapID=23,x=.5,y=.5},0),nil)
end)
test("clicking a source opens native map and creates pins",function()
    reset();local b=assert(A:Import("Adaptive Power\nArcane Cadence"));local t=b.targets[1];local loc=A:BestLocation(t)
    A:ShowLocation(t,loc);assert(WorldMapFrame:IsShown());eq(M.map,loc.mapID);assert(A.mapPins[1]:IsShown());assert(A.UI.details:IsShown())
end)
test("every source detail, including raid and unknown, renders",function()
    for _,l in ipairs(A.Data.locations)do local t=A:ResolveTarget({name=A.tomesByID[l.tomeID].name,tier="S"});A:ShowDetails(t,l)end
    A:ShowDetails(A:ResolveTarget({name="Completely New",tier="S"}),nil)
end)
test("UI import preview, direct Hub copy and save preserve originals",function()
    reset();A:ShowImport();A.UI.import.input:SetText('{"title":"UI build","echoTiers":{"Adaptive Power|3":"S"}}')
    M.Click(A.UI.import.preview);assert(A.UI.import.pending);M.Click(A.UI.import.save);eq(A:GetBuild().title,"UI build")
    EbonholdHubDB={builds={{title="Hub original",echoTiers={["Arcane Cadence|3"]="A"}}}}
    local choices=A:GetHubBuilds();eq(#choices,1);local copy=assert(A:ParseHubData(choices[1].data));A:SaveBuild(copy)
    A:GetBuild().targets[1].name="changed";eq(EbonholdHubDB.builds[1].echoTiers["Arcane Cadence|3"],"A")
end)
test("checkbox and row reset actions update collection",function()
    reset();assert(A:Import("Adaptive Power\nArcane Cadence"));local row=A.UI.rows[1];local key=row.target.key;M.Click(row.check);eq(A.char.manual[key],"done")
    A.char.settings.hideDone=false;A:Render();for _,r in ipairs(A.UI.rows)do if r.target and r.target.key==key then M.Click(r,"RightButton");break end end;eq(A.char.manual[key],nil)
end)
test("scroll/search/resize/collapse/preferences do not throw",function()
    reset();local names={};for _,t in ipairs(A.Data.tomes)do names[#names+1]=t.name end;assert(A:Import(table.concat(names,"\n")))
    A.UI.list.scripts.OnMouseWheel(A.UI.list,-20);assert(A.runtime.scroll>0)
    A.UI.search:SetText("adaptive");eq(A.runtime.scroll,0);eq(A.UI.rows[1].target.name,"Adaptive Power");A.UI.search:SetText("")
    A.char.settings.width=540;A.char.settings.height=680;A:Render();assert(A.UI.visibleRows>4)
    A.char.settings.collapsed=true;A:Render();eq(A.UI.body:IsShown(),false);A.char.settings.collapsed=false;A:Render()
    A:ShowSettings();for _,cb in ipairs(A.UI.settings.checks)do M.Click(cb);M.Click(cb)end
    A:ResetPositions();eq(A.frame:GetWidth(),354)
end)
test("custom positions are character-scoped and usable",function()
    reset();local b=assert(A:Import('{"echoTiers":{"New Test Echo":"S"}}'));local t=b.targets[1]
    assert(A:RecordLocation(t));A:Refresh();assert(#A.runtime.route==1);eq(A:TargetLocations(t)[1].accuracy,"custom");assert(A.char.locations[t.key]);eq(A.db.locations,nil)
end)
test("all slash commands and late addon events are safe",function()
    for _,c in ipairs({"show","hide","toggle","import","settings","scan","route","next","pause","replan","resetpos","debug","help"})do SlashCmdList.EBONTOMEFARM(c)end
    M.Emit("ADDON_LOADED","ProjectEbonhold");M.Emit("SPELLS_CHANGED");M.Emit("BAG_UPDATE",0);M.Tick(20)
end)
test("storage survives reinitialisation and limits saved builds",function()
    reset();local b=assert(A:Import("Adaptive Power\nArcane Cadence"));A:SetManual("adaptivepower","done");A:InitStorage();eq(A:GetBuild().id,b.id);eq(A.char.manual.adaptivepower,"done")
    for i=2,30 do assert(A:Import("Adaptive Power\nArcane Cadence"))end
    eq(A:Import("Adaptive Power\nArcane Cadence"),nil);eq(#A.db.builds,30)
end)
test("active resize survives polling and saves dimensions on release",function()
    reset();A:Render();local handle
    for _,f in ipairs(M.frames)do if f.parent==A.frame and type(f.normal)=="string" and f.normal:find("SizeGrabber",1,true)then handle=f end end
    assert(handle);handle.scripts.OnMouseDown(handle);A.frame:SetWidth(420);A.frame:SetHeight(560);A:Refresh()
    eq(A.frame:GetWidth(),420);eq(A.frame:GetHeight(),560);handle.scripts.OnMouseUp(handle)
    eq(A.char.settings.width,420);eq(A.char.settings.height,560);A:ResetPositions()
end)
test("inside-instance navigation suppresses outdoor direction",function()
    reset();assert(A:Import("Adaptive Power\nArcane Cadence"));A.char.settings.show=true;A:StartRoute();M.inside=true
    A:SamplePosition();A:UpdateNavigation();eq(A.arrow.icon:IsShown(),false);assert(A.arrow.info:GetText():find("Inside instance",1,true));M.inside=false
end)
test("every known single echo name bypasses false Base64 detection",function()
    reset()
    for _,t in ipairs(A.Data.tomes)do
        local b,err=A:ParseImport(t.name);assert(b,t.name..": "..tostring(err))
        eq(#b.targets,1);eq(b.targets[1].name,t.name)
    end
end)
test("wrapped Base64 remains valid and names have bounded lengths",function()
    local code=A.Codec.Base64Encode('{"title":"  ","echoTiers":{"Arcane Hazard|3":"S"}}')
    code=code:gsub("(........)","%1\n")
    local b=assert(A:ParseImport(code));eq(b.title,"Imported build");eq(#b.targets,1)
    local names=assert(A:ParseImport("Arcane Hazard\nArmor Mastery"));eq(#names.targets,2)
    eq(A:ParseImport(string.rep("X",201).."\nAdaptive Power"),nil)
end)
test("native map setter receives DBC ID, getter returns ID plus one",function()
    reset();local b=assert(A:Import("Adaptive Power"));local t=b.targets[1];local loc=A:BestLocation(t)
    A:ShowLocation(t,loc);eq(M.lastSetMapID,loc.mapID-1);eq(GetCurrentMapAreaID(),loc.mapID)
    for _,source in ipairs(A.Data.locations)do
        if source.mapID then
            A:ShowLocation(A:ResolveTarget({name=A.tomesByID[source.tomeID].name}),source)
            eq(M.lastSetMapID,source.mapID-1);eq(GetCurrentMapAreaID(),source.mapID)
        end
    end
end)
test("single-target guide and farm card identify Armor Mastery",function()
    reset();assert(A:Import("Armor Mastery"));A.char.settings.show=true;A:StartRoute()
    eq(A:ActiveStop().loc.place,"The Grinding Quarry - Blackrock Mountain")
    eq(A.UI.card.targets:GetText(),"Collect: Armor Mastery")
    eq(A.arrow.targets:GetText(),"Collect: Armor Mastery")
    M.Click(A.UI.card);eq(A.UI.details.target.key,"armormastery");WorldMapFrame:Hide()
end)
test("shared farms show bounded names and the full target tooltip",function()
    reset();assert(A:Import("Adaptive Power\nArcane Cadence"));A:StartRoute();local stop=A:ActiveStop()
    eq(#stop.targets,2)
    assert(A.UI.card.targets:GetText():find("Adaptive Power",1,true))
    assert(A.arrow.targets:GetText():find("Adaptive Power",1,true))
    assert(A.arrow.targets:GetStringWidth()<=A.arrow.targets:GetWidth())
    assert(A.arrow.targets:GetText():find("Arcane Cadence",1,true))
    A.arrow.targets:SetWidth(190);A:SetStopTargetLabel(A.arrow.targets,stop)
    assert(A.arrow.targets:GetText():find("+1 more",1,true))
    A.arrow.targets:SetWidth(244);A:SetStopTargetLabel(A.arrow.targets,stop)
    for _,frame in ipairs({A.UI.card,A.arrow})do
        GameTooltip.lines={};frame.scripts.OnEnter(frame)
        local tooltip=table.concat(GameTooltip.lines,"\n")
        for _,t in ipairs(stop.targets)do assert(tooltip:find(t.name,1,true))end
        assert(tooltip:find("Collect at this stop:",1,true))
        frame.scripts.OnLeave(frame);eq(GameTooltip:IsShown(),false)
    end
end)
test("shared-farm picker opens each tome's own source details",function()
    reset();assert(A:Import("Adaptive Power\nArcane Cadence"));A:StartRoute();local stop=A:ActiveStop()
    M.Click(A.UI.card);local picker=A.UI.picker;eq(#picker.items,2)
    local expected=picker.items[2].key;M.Click(picker.rows[2])
    eq(A.UI.details.target.key,expected)
    eq(A.UI.details.loc,stop.targetLocs[expected]);WorldMapFrame:Hide()
end)
test("collecting part of a shared camp refreshes names without moving on",function()
    reset();assert(A:Import("Adaptive Power\nArcane Cadence"));A:StartRoute();local id=A:ActiveStop().id
    A:SetManual("adaptivepower","done")
    eq(A:ActiveStop().id,id);eq(A.UI.card.targets:GetText(),"Collect: Arcane Cadence")
    eq(A.arrow.targets:GetText(),"Collect: Arcane Cadence")
    A:SetManual("arcanecadence","done");eq(A.UI.card.targets:GetText(),"");eq(A.arrow:IsShown(),false)
end)
test("target names remain visible on arrival and without live outdoor direction",function()
    reset();assert(A:Import("Armor Mastery"));A.char.settings.show=true;A:StartRoute();local stop=A:ActiveStop()
    A.runtime.position={mapID=stop.mapID,x=stop.x,y=stop.y};A:UpdateNavigation()
    assert(A.arrow.info:GetText():find("Farm here",1,true));eq(A.arrow.targets:GetText(),"Collect: Armor Mastery")
    WorldMapFrame:Show();A:UpdateNavigation();eq(A.arrow.targets:GetText(),"Collect: Armor Mastery");WorldMapFrame:Hide()
    M.inside=true;A:UpdateNavigation();eq(A.arrow.targets:GetText(),"Collect: Armor Mastery");M.inside=false
    A.runtime.position=nil;A:UpdateNavigation();eq(A.arrow.targets:GetText(),"Collect: Armor Mastery")
end)
test("only current farm targets stay highlighted including after mouse leave",function()
    reset();assert(A:Import("Armor Mastery\nBattle Rhythm\nAdaptive Power"));A:StartRoute()
    local function check()
        local active=A:ActiveStop();local keys={};for _,t in ipairs(active and active.targets or {})do keys[t.key]=true end
        for _,row in ipairs(A.UI.rows)do if row.target then
            eq(row.activeFarm,keys[row.target.key]or false)
            row.scripts.OnEnter(row);row.scripts.OnLeave(row)
            eq(row.border[1],row.activeFarm and .84 or .22)
            eq(row.sub:GetText():find("Farm now: ",1,true)~=nil,row.activeFarm)
        end end
    end
    check();A:SkipStop();check();A:PauseRoute();check()
end)
test("farm-card controls and rows do not overlap at supported sizes",function()
    reset();assert(A:Import("Armor Mastery"));A:StartRoute()
    local function below(upper,lower)
        local _,y,_,h=upper:Rect();local _,yy=lower:Rect();assert(yy>=y+h,"Overlapping vertical regions")
    end
    for _,dims in ipairs({{344,418},{354,500},{540,680},{600,900}})do
        A.char.settings.width=dims[1];A.char.settings.height=dims[2];A:Render()
        below(A.UI.card.title,A.UI.card.targets);below(A.UI.card.targets,A.UI.card.info)
        below(A.UI.card,A.UI.start);below(A.UI.start,A.UI.search);below(A.UI.search,A.UI.list)
        below(A.arrow.title,A.arrow.targets);below(A.arrow.targets,A.arrow.info)
        local _,y,_,h=A.arrow.info:Rect();local _,ay,_,ah=A.arrow:Rect();assert(y+h<=ay+ah)
        assert(A.UI.visibleRows>=1)
    end
    A:ResetPositions()
end)
test("many shared targets stay compact without dropping the full picker list",function()
    reset();local b=assert(A:Import("Adaptive Power\nArcane Cadence"));A:StartRoute()
    local stop={loc=A:ActiveStop().loc,targets={},targetLocs={}}
    for i=1,22 do stop.targets[i]={name="A long wanted echo name "..i,key="test"..i}end
    local before=stop.targets[22].name
    A:SetStopTargetLabel(A.arrow.targets,stop)
    assert(A.arrow.targets:GetText():find("+21 more",1,true))
    GameTooltip.lines={};A:ShowStopTooltip(A.arrow,stop)
    assert(table.concat(GameTooltip.lines,"\n"):find("12 more",1,true))
    A:OpenStopDetails(stop);eq(#A.UI.picker.items,22);eq(stop.targets[22].name,before)
    A.UI.picker:Hide();GameTooltip:Hide()
end)
local function tomeLink(name,id)
    return "|cff0070dd|Hitem:"..(id or 300001)..":0:0:0:0:0:0:0|h[Tome of Echo: "..name.."]|h|r"
end
local function alertMessages()
    local n=0;for _,m in ipairs(M.messages)do if m:find("TOME FOUND:",1,true)then n=n+1 end end;return n
end
local function withStops(specs,fn)
    local saved=A.RouteCandidates;local names,seen={},{}
    for _,s in ipairs(specs)do for _,name in ipairs(s[5])do if not seen[name]then names[#names+1]=name;seen[name]=true end end end
    A.RouteCandidates=function(self)
        local out,by={},{}
        for _,s in ipairs(specs)do
            local z=self.Data.zones[s[2]]
            local loc={id=s[1],mapID=s[2],x=s[3],y=s[4],c=z.c,zone=z.name,place=s[1],kind=s[6]or"world",mobs={"Test mob"}}
            local stop={id=s[1],loc=loc,mapID=loc.mapID,x=loc.x,y=loc.y,c=z.c,targets={},targetLocs={}}
            for _,name in ipairs(s[5])do
                local t=self:TargetByKey(self.util.key(name))
                if t and self:Eligible(t)and not self:IsDone(t)and self:LocationUsable(loc)then stop.targets[#stop.targets+1]=t;stop.targetLocs[t.key]=loc end
            end
            if #stop.targets>0 then out[#out+1]=stop;by[stop.id]=stop end
        end
        return out,by
    end
    local ok,err=pcall(function()assert(A:Import(table.concat(names,"\n")));fn()end)
    A.RouteCandidates=saved;if not ok then error(err)end
end
test("reset all accidental ticks restores the same imported build",function()
    reset();local b=assert(A:Import("Adaptive Power\nArcane Cadence\nArmor Mastery"));local source=A.util.copy(b.sourceTargets)
    for _,t in ipairs(b.targets)do A:SetManual(t.key,"done")end
    eq(#A.runtime.route,0);A:Replan();eq(#A.runtime.route,0)
    assert(A:ResetBuild(b.id));eq(#A.db.builds,1);eq(A:GetBuild(),b);eq(#b.sourceTargets,#source)
    for i,t in ipairs(source)do eq(b.sourceTargets[i].name,t.name)end
    for _,t in ipairs(b.targets)do eq(A:IsDone(t),false);eq(A.char.manual[t.key],nil)end
    assert(#A.runtime.route>0);eq(A.runtime.running,false)
end)
test("reset rescans real learned and bag tomes while preserving other marks and pins",function()
    reset();local b=assert(A:Import("Adaptive Power\nArcane Cadence\nArmor Mastery"))
    for _,t in ipairs(b.targets)do A.char.manual[t.key]="need"end
    A.char.manual.battlerhythm="done";local pins={armormastery={mapID=29,x=.4,y=.6}};A.char.locations=pins
    M.discovered[200002]=true;M.bags[0]={tomeLink("Arcane Cadence",300003)};A.runtime.skipped.fake=true
    A.UI.search:SetText("nothing matches");assert(A:ResetBuild(b.id))
    eq(A:Status(A:TargetByKey("adaptivepower")),"learned");eq(A:Status(A:TargetByKey("arcanecadence")),"bag")
    eq(A:Status(A:TargetByKey("armormastery")),"needed");eq(A.char.manual.battlerhythm,"done")
    eq(A.char.locations,pins);eq(next(A.runtime.skipped),nil);eq(A.UI.search:GetText(),"");eq(A.runtime.scroll,0)
end)
test("reset requires confirmation and Cancel leaves marks and skips intact",function()
    reset();assert(A:Import("Adaptive Power\nArcane Cadence"));A:SetManual("adaptivepower","done");A.runtime.skipped.test=true
    M.Click(A.UI.resetBuild);assert(A.UI.confirm:IsShown());M.Click(A.UI.confirm.no)
    eq(A.char.manual.adaptivepower,"done");eq(A.runtime.skipped.test,true)
    M.Click(A.UI.resetBuild);M.Click(A.UI.confirm.yes);eq(A.char.manual.adaptivepower,nil);eq(next(A.runtime.skipped),nil)
end)
test("reset confirmation cannot reset a different newly selected build",function()
    reset();local old=assert(A:Import("Adaptive Power\nArcane Cadence"));A:ShowResetBuild()
    local new=assert(A:Import("Armor Mastery"));A:SetManual("armormastery","done");M.Click(A.UI.confirm.yes)
    eq(A:GetBuild(),new);eq(A.char.manual.armormastery,"done");eq(#A.db.builds,2)
end)
test("reset and reroute aliases are usable without deleting ownership",function()
    reset();assert(A:Import("Adaptive Power\nArcane Cadence"));A:SetManual("adaptivepower","done")
    SlashCmdList.EBONTOMEFARM("scan");eq(A.char.manual.adaptivepower,"done")
    SlashCmdList.EBONTOMEFARM("reset");M.Click(A.UI.confirm.yes);eq(A.char.manual.adaptivepower,nil)
    SlashCmdList.EBONTOMEFARM("reroute");assert(A:ActiveStop())
end)
test("first farm is nearest even when a farther raid covers more high-tier targets",function()
    reset();M.player={mapID=29,x=.5,y=.5}
    withStops({{"near",29,.501,.5,{"Nearby Tome"}},{"many",29,.8,.8,{"Raid One","Raid Two","Raid Three"},"raid"}},function()
        for _,t in ipairs(A:GetBuild().sourceTargets)do t.tier=t.name=="Nearby Tome"and"C"or"S"end
        A:Replan();eq(A:ActiveStop().id,"near")
    end)
end)
test("closest source wins across all alternatives for the same tome",function()
    reset();M.player={mapID=29,x=.5,y=.5}
    withStops({{"far-source",29,.8,.8,{"Shared Tome"}},{"close-source",29,.501,.5,{"Shared Tome"}},{"another",29,.7,.6,{"Second Tome"}}},function()
        A:Replan();eq(A:ActiveStop().id,"close-source");eq(#A.runtime.route,2)
        local n=0;for _,s in ipairs(A.runtime.route)do for _,t in ipairs(s.targets)do if t.key=="sharedtome"then n=n+1 end end end;eq(n,1)
    end)
end)
test("nearest-first completes the selected zone before an adjacent closer stop",function()
    reset();M.player={mapID=29,x=.5,y=.85}
    local wx,wy=A:WorldPoint(29,.5,.85);local z=A.Data.zones[30]
    local x,y=(z.left-wx-50)/z.width,(z.top-wy)/z.height
    assert(x>0 and x<1 and y>0 and y<1)
    withStops({{"first",29,.5,.85,{"First Tome"}},{"same-zone",29,.8,.85,{"Same Zone Tome"}},{"other-zone",30,x,y,{"Other Zone Tome"}}},function()
        A:Replan();eq(A.runtime.route[1].id,"first");eq(A.runtime.route[2].id,"same-zone");eq(A.runtime.route[3].id,"other-zone")
        A:SetManual("firsttome","done");eq(A:ActiveStop().id,"same-zone")
        A:SetManual("samezonetome","done");eq(A:ActiveStop().id,"other-zone")
    end)
end)
test("completion chooses the next closest from actual player position not the old plan",function()
    reset();M.player={mapID=29,x=.1,y=.5}
    withStops({{"first",29,.1,.5,{"First Tome"}},{"middle",29,.3,.5,{"Middle Tome"}},{"end",29,.9,.5,{"Last Tome"}}},function()
        A:Replan();eq(A.runtime.route[2].id,"middle")
        M.player.x=.89;A:SetManual("firsttome","done");eq(A:ActiveStop().id,"end")
    end)
end)
test("Replan restores skipped stops and chooses afresh without clearing manual ticks",function()
    reset();M.player={mapID=29,x=.1,y=.5}
    withStops({{"near",29,.1,.5,{"First Tome"}},{"far",29,.9,.5,{"Last Tome"}}},function()
        A:Replan();A:SkipStop();eq(A:ActiveStop().id,"far")
        A:Replan();eq(A:ActiveStop().id,"near");eq(next(A.runtime.skipped),nil)
        M.player.x=.89;A:Replan();eq(A:ActiveStop().id,"far")
        A:SetManual("lasttome","done");A:Replan();eq(A.char.manual.lasttome,"done");eq(A:ActiveStop().id,"near")
    end)
end)
test("no position never creates an arbitrary raid destination and resumes when sampled",function()
    reset();M.player={mapID=0,x=0,y=0}
    withStops({{"near",29,.5,.5,{"Local Tome"}},{"icc",493,.5,.5,{"Raid Tome"},"raid"}},function()
        A:Replan();eq(A:ActiveStop(),nil);eq(#A.runtime.route,0);assert(A.runtime.waitingForPosition)
        assert(A.UI.card.title:GetText():find("Waiting",1,true))
        M.player={mapID=29,x=.49,y=.5};M.Tick(2);eq(A:ActiveStop().id,"near")
    end)
end)
test("replan while browsing the map waits without moving it then uses current position",function()
    reset();M.player={mapID=29,x=.1,y=.5}
    withStops({{"old",29,.1,.5,{"First Tome"}},{"new",29,.9,.5,{"Last Tome"}}},function()
        A:Replan();WorldMapFrame:Show();M.map=493;M.player.x=.89;local n=M.mapSwitches
        A:Replan();eq(A:ActiveStop(),nil);eq(M.map,493);eq(M.mapSwitches,n)
        WorldMapFrame:Hide();M.Tick(2);eq(A:ActiveStop().id,"new")
    end)
end)
test("current continent is exhausted before ICC or Crystalsong",function()
    reset();M.player={mapID=37,x=.5,y=.5}
    local names={};for _,t in ipairs(A.Data.tomes)do names[#names+1]=t.name end
    assert(A:Import(table.concat(names,"\n")));A:Replan();local first=assert(A:ActiveStop());eq(first.c,2)
    local candidates=A:RouteCandidates();local distance=A:Distance(A.runtime.position,first)
    for _,s in ipairs(candidates)do if s.c==2 then assert(distance<=A:Distance(A.runtime.position,s)+.001)end end
    local left=false;local zones={};local current
    for _,s in ipairs(A.runtime.route)do
        if s.c~=2 then left=true else assert(not left,"Returned to Eastern Kingdoms after leaving")end
        if current~=s.mapID then assert(not zones[s.mapID],"Zone split across the route");zones[s.mapID]=true;current=s.mapID end
    end
end)
test("native-map scan precedes destination choice after zone event",function()
    reset();M.player={mapID=493,x=.5,y=.5}
    withStops({{"local",29,.5,.5,{"Local Tome"}},{"icc",493,.5,.5,{"Raid Tome"},"raid"}},function()
        A:SamplePosition();M.player={mapID=29,x=.49,y=.5};M.Emit("ZONE_CHANGED_NEW_AREA")
        A:Replan();eq(A:ActiveStop().id,"local")
    end)
end)
test("automatic advance can still be disabled",function()
    reset();M.player={mapID=29,x=.1,y=.5};A.char.settings.autoAdvance=false
    withStops({{"first",29,.1,.5,{"First Tome"}},{"last",29,.9,.5,{"Last Tome"}}},function()
        A:Replan();A:SetManual("firsttome","done");eq(A.runtime.running,false);eq(A:ActiveStop(),nil);eq(#A.runtime.route,1)
    end)
end)
test("existing login bags silently seed notifications including late login data",function()
    reset();A:BeginBagBaseline();A:ScanBags();M.bags[0]={tomeLink("Adaptive Power")};M.Tick(20)
    eq(alertMessages(),0);eq(A.runtime.tomeAlertActive,nil);assert(A.runtime.bagBaselineReady)
    M.bags[0][2]=tomeLink("Arcane Cadence",300003);M.Tick(6)
    eq(alertMessages(),1);eq(A.runtime.tomeAlertActive.name,"Arcane Cadence")
end)
test("bag polling alone finds new tomes even with tracker hidden and route paused",function()
    reset();assert(A:Import("Armor Mastery"));A:ScanBags();A.char.settings.show=false;A:Render();A:PauseRoute()
    M.bags[0]={tomeLink("Armor Mastery")};M.Tick(6)
    eq(alertMessages(),1);assert(A.UI.tomeAlert:IsShown());eq(A.UI.tomeAlert.name:GetText(),"Armor Mastery")
    eq(A:Status(A:TargetByKey("armormastery")),"bag");eq(A.frame:IsShown(),false);eq(A.runtime.running,false)
end)
test("loot events debounce to prompt confirmed bag notification",function()
    reset();A:ScanBags();M.bags[0]={tomeLink("Adaptive Power")};M.Emit("BAG_UPDATE",0);M.Tick(3)
    eq(alertMessages(),1);eq(A.runtime.tomeAlertActive.name,"Adaptive Power")
end)
test("bag moves rescans and using/reacquiring the same tome do not spam",function()
    reset();A:ScanBags();M.bags[0]={tomeLink("Adaptive Power")};A:ScanBags();eq(alertMessages(),1)
    M.bags[1]=M.bags[0];M.bags[0]={};A:ScanBags();A:ScanCollection();M.Tick(40);eq(alertMessages(),1)
    M.bags={};A:ScanBags();M.bags[2]={tomeLink("Adaptive Power")};A:ScanBags();eq(alertMessages(),1)
end)
test("multiple new tomes queue separate banners and sound once each",function()
    reset();A:ScanBags();M.bags[0]={tomeLink("Adaptive Power"),tomeLink("Arcane Cadence",300003)};A:ScanBags()
    eq(alertMessages(),2);eq(A.runtime.tomeAlertActive.name,"Adaptive Power");eq(#A.runtime.tomeAlertQueue,1);eq(#M.sounds,1)
    M.Tick(27);eq(A.runtime.tomeAlertActive.name,"Arcane Cadence");eq(#M.sounds,2)
    M.Tick(27);eq(A.runtime.tomeAlertActive,nil);eq(A.UI.tomeAlert:IsShown(),false);eq(alertMessages(),2)
end)
test("disabled notifications do not backlog old drops and sound has its own switch",function()
    reset();A:ScanBags();A.char.settings.tomeAlerts=false;M.bags[0]={tomeLink("Adaptive Power")};A:ScanBags();eq(alertMessages(),0)
    A.char.settings.tomeAlerts=true;A.char.settings.tomeSound=false;A:ScanBags();eq(alertMessages(),0)
    M.bags[0][2]=tomeLink("Arcane Cadence",300003);A:ScanBags();eq(alertMessages(),1);eq(#M.sounds,0)
    A.char.settings.tomeAlerts=false;M.Tick(1);eq(A.runtime.tomeAlertActive,nil);eq(A.UI.tomeAlert:IsShown(),false)
end)
test("reset build and scan never manufacture a new tome-found notification",function()
    reset();local b=assert(A:Import("Adaptive Power\nArcane Cadence"));M.bags[0]={tomeLink("Adaptive Power")};A:ScanBags()
    A:SetManual("adaptivepower","need");A:ResetBuild(b.id);A:ScanCollection();A:Replan();eq(alertMessages(),0)
    eq(A:Status(A:TargetByKey("adaptivepower")),"bag")
end)
test("notifications accept unlisted tomes but never count as learned",function()
    reset();A:ScanBags();M.bags[0]={tomeLink("New Server Echo")};A:ScanBags()
    eq(A.runtime.tomeAlertActive.name,"New Server Echo");eq(A.runtime.owned.newserverecho,nil)
    assert(A.runtime.bags.newserverecho);eq(alertMessages(),1)
end)
test("preview notification is labelled and changes neither bags nor manual marks",function()
    reset();assert(A:Import("Armor Mastery"));SlashCmdList.EBONTOMEFARM("testalert")
    assert(A.UI.tomeAlert.heading:GetText():find("PREVIEW",1,true));eq(A:Status(A:TargetByKey("armormastery")),"needed")
    eq(next(A.runtime.bags),nil);eq(next(A.char.manual),nil);eq(alertMessages(),0)
end)
test("reset button and notification/settings contents fit their frames",function()
    reset();assert(A:Import("Armor Mastery"));A:ShowSettings()
    for _,dims in ipairs({{344,418},{354,500},{600,900}})do
        A.char.settings.width=dims[1];A.char.settings.height=dims[2];A:Render()
        local x,y,w,h=A.UI.footer:Rect();local bx,by,bw,bh=A.UI.resetBuild:Rect();assert(x+w<=bx);assert(y+h<=by+bh+2)
        local _,ly,_,lh=A.UI.list:Rect();assert(ly+lh<=by)
    end
    local function inside(parent,child)
        local x,y,w,h=parent:Rect();local a,b,c,d=child:Rect();assert(a>=x and b>=y and a+c<=x+w and b+d<=y+h)
    end
    for _,cb in ipairs(A.UI.settings.checks)do inside(A.UI.settings,cb)end
    inside(A.UI.settings,A.UI.settings.resetBuild);inside(A.UI.settings,A.UI.settings.testAlert)
    A:ShowTomeFound({key="long",name=string.rep("Long echo ",18),test=true})
    inside(A.UI.tomeAlert,A.UI.tomeAlert.name);inside(A.UI.tomeAlert,A.UI.tomeAlert.info)
    A:ShowResetBuild();inside(A.UI.confirm,A.UI.confirm.message)
    local _,y,_,h=A.UI.confirm.message:Rect();local _,by=A.UI.confirm.yes:Rect();assert(y+h<=by)
    A:ResetPositions()
end)

print(string.format("\n%d tests passed under %s",passed,_VERSION))
