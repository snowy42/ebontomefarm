local A=EbonTomeFarm
local boot=CreateFrame("Frame")
local function initialise()
    if A.ready then return end
    A:InitStorage();A:LoadData();A:BuildPerkIndex()
    if not (WorldMapFrame and WorldMapFrame:IsShown())then A:InitMaps()end
    A:SamplePosition();A:IndexTargets();A:RebuildRoute();A:CreateUI();A.ready=true;A:ScanCollection()
    A:Print("Loaded v"..A.VERSION..". /etf to show or hide; /etf import to paste a build.")
end
A.eventFrame=boot
boot:RegisterEvent("ADDON_LOADED");boot:RegisterEvent("PLAYER_LOGIN");boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:RegisterEvent("BAG_UPDATE");boot:RegisterEvent("SPELLS_CHANGED");boot:RegisterEvent("LEARNED_SPELL_IN_TAB")
boot:RegisterEvent("ZONE_CHANGED_NEW_AREA");boot:RegisterEvent("CHAT_MSG_LOOT");boot:RegisterEvent("WORLD_MAP_UPDATE")
boot:SetScript("OnEvent",function(_,event,arg1)
    if event=="ADDON_LOADED" then
        if arg1=="EbonTomeFarm" then initialise()
        elseif A.ready and (arg1=="ProjectEbonhold" or arg1=="EbonholdHub")then A:BuildPerkIndex();A.scanDue=.5 end
    elseif event=="PLAYER_LOGIN"then initialise()
    elseif A.ready then
        if event=="WORLD_MAP_UPDATE"then A.pinsDue=true
        elseif event=="SPELLS_CHANGED"or event=="LEARNED_SPELL_IN_TAB"then A.perksDirty=true;A.scanDue=.4
        elseif event=="PLAYER_ENTERING_WORLD"then A.perksDirty=true;A.scanDue=1;A.runtime.position=nil
        elseif event=="ZONE_CHANGED_NEW_AREA"then A.runtime.position=nil;A.scanDue=.5
        else A.scanDue=.3 end
    end
end)
local elapsedNav,elapsedScan=0,0
boot:SetScript("OnUpdate",function(_,elapsed)
    if not A.ready then return end
    elapsedNav=elapsedNav+elapsed;elapsedScan=elapsedScan+elapsed
    if A.scanDue then A.scanDue=A.scanDue-elapsed end
    if elapsedScan>=3 or (A.scanDue and A.scanDue<=0)then
        elapsedScan=0;A.scanDue=nil
        if A.perksDirty or not next(A.perksByID)then A:BuildPerkIndex();A.perksDirty=false end
        if not A.mapCZ and not(WorldMapFrame and WorldMapFrame:IsShown())then A:InitMaps()end
        A:ScanCollection()
    end
    if elapsedNav>=.2 then
        elapsedNav=0
        if A.runtime.running then A:SamplePosition();A:UpdateNavigation()end
        if WorldMapFrame and WorldMapFrame:IsShown()then A:DrawPins()end
    end
end)
SLASH_EBONTOMEFARM1="/etf";SLASH_EBONTOMEFARM2="/ebontomefarm"
SlashCmdList["EBONTOMEFARM"]=function(message)
    if not A.ready then initialise()end
    local command=(message or ""):match("^%s*(%S*)"):lower()
    if command==""or command=="toggle"then A.char.settings.show=not A.char.settings.show;A:Render()
    elseif command=="show"then A.char.settings.show=true;A:Render()
    elseif command=="hide"then A.char.settings.show=false;A:Render()
    elseif command=="import"then A:ShowImport()
    elseif command=="route"or command=="start"then A:StartRoute()
    elseif command=="next"or command=="skip"then A:SkipStop()
    elseif command=="pause"then A:PauseRoute()
    elseif command=="replan"then A:Replan()
    elseif command=="scan"then A:BuildPerkIndex();A:ScanCollection();A:Print("Permanent unlocks and bags rescanned.")
    elseif command=="settings"then A:ShowSettings()
    elseif command=="resetpos"then A:ResetPositions();A.char.settings.show=true;A:Render()
    elseif command=="debug"then
        local perks=0;for _ in pairs(A.perksByID)do perks=perks+1 end
        A:Print(string.format("v%s; %d tome records; %d native perk IDs; discovery API: %s; legacy TomTom: %s; route stops: %d",A.VERSION,#A.Data.tomes,perks,tostring(A.runtime.collectionAPI),tostring(TomTom and type(TomTom.AddZWaypoint)=="function"or false),#A.runtime.route))
    else A:Print("Commands: /etf show, hide, import, route, next, pause, replan, scan, settings, resetpos, debug. Drag the header to move; resize from the lower-right corner.")end
end
