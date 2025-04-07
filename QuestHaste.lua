QuestHaste_EventHandler = CreateFrame("FRAME")
QuestHaste_EventHandler:RegisterEvent("ADDON_LOADED")

local QuestHaste_EventList = {
    "QUEST_PROGRESS",
    "QUEST_COMPLETE",
    "QUEST_DETAIL",
    "GOSSIP_SHOW",
    "QUEST_GREETING"
}

local QuestHaste_Usage = [[
|cffffff00## QuestHaste Usage:

* Quest (active and available) opening/progress modifiers
    * Control   auto complete/accept and save
    * Alt   forget
    * Shift   complete/accept if not saved, hold if saved
    * No Modifier   complete/accept if saved
* Gossip opening modifiers
    * Shift   auto complete/accept quest in gossip
        (priority: completed, available saved,
        active saved, available, active)
* Command line options (/qhaste, /questhaste):
    * usage   display usage instructions
    * add   saves current quest
    * list   list all saved quests
    * pause   disable QuestHaste
    * resume   activate QuestHaste
    * complete   complete/accept current quest
    * reset   clears all saved quests|r
]]

function QuestHaste_RegisterEvents()
    for _,e in QuestHaste_EventList do
        QuestHaste_EventHandler:RegisterEvent(e)
    end
end

function QuestHaste_UnregisterEvents()
    for _,e in QuestHaste_EventList do
        QuestHaste_EventHandler:UnregisterEvent(e)
    end
end

local function filterEvens(t)
    local r = {}
    for k,v in t do
        if math.mod(k,2) ~= 0 then
            r[(k+1)/2] = v
        end
    end
    return r
end

local function contained(t,val)
    for _,v in t do
        if v == val then
            return true
        end
    end
    return false
end

local function menuHandler(available, active, name, accept, complete)
    local function SetupBackground(b)
        b:SetAllPoints(b:GetParent()) b:SetDrawLayer("BACKGROUND",-1) b:SetTexture(1,1,1) b:SetGradientAlpha("HORIZONTAL", 0.5, 1, 0, 0.5, 1, 1, 0, 0)
    end
    
    for i = 1,32 do
        local f = getglobal(name..i)
        
        if f.QHaste == nil then
            f.QHaste = {background = f:CreateTexture(), oldScript = f:GetScript("OnClick")}
            SetupBackground(f.QHaste.background)
            local function OnClick(...)
                local title = f:GetText()
                if IsAltKeyDown() and QuestHaste.autolist[title] then
                    if contained(available, title) then
                        QuestHaste_RemoveAutoAccept(title)
                    else
                        QuestHaste_RemoveAutoComplete(title)
                    end
                    f.QHaste.background:Hide()
                else
                    f.QHaste.oldScript(unpack(arg))
                end
            end
            f:SetScript("OnClick",OnClick)
        end
        if QuestHaste.autolist[f:GetText()] then
            f.QHaste.background:Show()
        else
            f.QHaste.background:Hide()
        end
    end
    if IsShiftKeyDown() then
        local logCompleted = {}
        for k = 1,GetNumQuestLogEntries() do
            local title, _, _, _, _, completed = GetQuestLogTitle(k)
            if completed then
                logCompleted[title] = true
            end
        end
        for k,v in active do
            if logCompleted[v] then
                QuestHaste.currentQuest = v
                complete(k)
                return
            end
        end
        
        for k,v in available do
            if QuestHaste_IsAutoAccept(v) then
                QuestHaste.currentQuest = v
                accept(k)
                return
            end
        end

        for k,v in active do
            if QuestHaste_IsAutoComplete(v) then
                QuestHaste.currentQuest = v
                complete(k)
                return
            end
        end
        
        if next(available) then
            QuestHaste.currentQuest = available[1]
            accept(1)
            return
        end
        if next(active) then
            QuestHaste.currentQuest = active[1]
            complete(1)
            return
        end
    end
end
    
function QuestHaste_EventHandler.GOSSIP_SHOW()
    local available = filterEvens({GetGossipAvailableQuests()})
    local active = filterEvens({GetGossipActiveQuests()})
    local name = "GossipTitleButton"
    menuHandler(available, active, name, SelectGossipAvailableQuest, SelectGossipActiveQuest)
end

function QuestHaste_EventHandler.QUEST_GREETING()
    local available = {}
    local active = {}
    for k = 1, GetNumAvailableQuests() do
        table.insert(available, GetAvailableTitle(k))
    end
    for k = 1, GetNumActiveQuests() do
        table.insert(active, GetActiveTitle(k))
    end
    local name = "QuestTitleButton"
    menuHandler(available, active, name, SelectAvailableQuest, SelectActiveQuest)
end
    

function QuestHaste_EventHandler.QUEST_PROGRESS()
    local title = GetTitleText()
    
    if IsControlKeyDown() then
        QuestHaste_AddAutoComplete(title)
    elseif IsAltKeyDown() then
        QuestHaste_RemoveAutoComplete(title) return
    end

    if (QuestHaste.currentQuest == title or QuestHaste_IsAutoComplete(title) ~= (IsShiftKeyDown() ~= nil)) and IsQuestCompletable() then
        QuestHaste.currentQuest = title
        CompleteQuest()
    else
        QuestHaste.currentQuest = ""
    end
end

function QuestHaste_EventHandler.QUEST_COMPLETE()
    local title = GetTitleText()
    
    if IsControlKeyDown() then QuestHaste_AddAutoComplete(title)
    elseif IsAltKeyDown() then QuestHaste_RemoveAutoComplete(title) return end
    
    if (QuestHaste.currentQuest == title or QuestHaste_IsAutoComplete(title) ~= (IsShiftKeyDown() ~= nil)) and GetNumQuestChoices() == 0 then
        GetQuestReward()
    end
    QuestHaste.currentQuest = ""
end

function QuestHaste_EventHandler.QUEST_DETAIL()
    local title = GetTitleText()
    
    if IsControlKeyDown() then QuestHaste_AddAutoAccept(title)
    elseif IsAltKeyDown() then QuestHaste_RemoveAutoAccept(title) return end

    if QuestHaste.currentQuest == title or QuestHaste_IsAutoAccept(title) ~= (IsShiftKeyDown() ~= nil) then
        AcceptQuest()
    else
        QuestHaste.currentQuest = ""
    end
end

function QuestHaste_EventHandler.ADDON_LOADED()
    if arg1 == "QuestHaste" then
        QuestHaste_Session = {}
        if QuestHaste == nil or QuestHaste.autolist == nil then
            QuestHaste = {autolist = {}, dataVersion = "1.0.0"}
        end
        if QuestHaste.dataVersion == nil then
            local tmp = {}
            for k,_ in QuestHaste.autolist do
                tmp[k] = {complete=true}
            end
            QuestHaste.autolist = tmp
            QuestHaste.dataVersion = "1.0.0"
        end
        QuestHaste_RegisterEvents()
        QuestHaste_EventHandler:UnregisterEvent("ADDON_LOADED")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff88QuestHaste|r loaded. See /qhaste usage")
    end
end

QuestHaste_EventHandler:SetScript("OnEvent",
    function ()
        if QuestHaste_EventHandler[event]
        then QuestHaste_EventHandler[event]()
        end
    end
)

function QuestHaste_IsAutoComplete(title)
    return (QuestHaste.autolist[title] or false) and QuestHaste.autolist[title].complete
end

function QuestHaste_IsAutoAccept(title)
    return (QuestHaste.autolist[title] or false) and QuestHaste.autolist[title].accept
end

function QuestHaste_AddAutoComplete(title)
    if QuestHaste_IsAutoComplete(title) then return end
    if QuestHaste.autolist[title] == nil then QuestHaste.autolist[title] = {} end
    QuestHaste.autolist[title].complete = true
    local msg = "|cffffff88QuestHaste|r: |cffffff00"..title.."|r |cff00ff00added|r."
    UIErrorsFrame:AddMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function QuestHaste_AddAutoAccept(title)
    if QuestHaste_IsAutoAccept(title) then return end
    if QuestHaste.autolist[title] == nil then QuestHaste.autolist[title] = {} end
    QuestHaste.autolist[title].accept = true
    local msg = "|cffffff88QuestHaste|r: |cffffff00"..title.."|r |cff00ff00added|r."
    UIErrorsFrame:AddMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function QuestHaste_RemoveAutoComplete(title)
    if not QuestHaste_IsAutoComplete(title) then return end
    if QuestHaste_IsAutoAccept(title) then
        QuestHaste.autolist[title].complete = false
    else 
        QuestHaste.autolist[title] = nil
    end
    local msg = "|cffffff88QuestHaste|r: |cffffff00"..title.."|r |cffff0000removed|r."
    UIErrorsFrame:AddMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function QuestHaste_RemoveAutoAccept(title)
    if not QuestHaste_IsAutoAccept(title) then return end
    if QuestHaste_IsComplete(title) then
        QuestHaste.autolist[title].accept = false
    else
        QuestHaste.autolist[title] = nil
    end
    local msg = "|cffffff88QuestHaste|r: |cffffff00"..title.."|r |cffff0000removed|r."
    UIErrorsFrame:AddMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function QuestHaste_Proceed()
    if GossipFrame:IsShown() then
        QuestHaste.currentQuest = GetGossipActiveQuests()
        SelectGossipActiveQuest(1)
    elseif QuestFrame:IsShown() then
        local title = GetTitleText()
        if QuestFrameAcceptButton:IsShown() then
            AcceptQuest()
        elseif QuestFrameCompleteButton:IsShown() and IsQuestCompletable() then
            QuestHaste.currentQuest = title
            CompleteQuest()
        elseif QuestFrameCompleteQuestButton:IsShown() and IsQuestCompletable() then
            GetQuestReward()
        end
    end
end

local function CommandParser(msg, editbox)
    local _,_,command, rest = string.find(msg,"^(%S*)%s*(.-)$")
    if command == "usage" then
        DEFAULT_CHAT_FRAME:AddMessage(QuestHaste_Usage)
    elseif command == "add" then
        if QuestFrame:IsShown() then
            local title = GetTitleText()
            QuestHaste_AddAutoComplete(title)
        else
            UIErrorsFrame:AddMessage("QuestHaste: no active quest.",1,0,0)
        end
        QuestHaste_Proceed()
    --elseif command == "remove" then
    --    QuestHaste.autolist[title] = nil
    elseif command == "list" then
        DEFAULT_CHAT_FRAME:AddMessage("QuestHaste quest list:")
        for k,v in QuestHaste.autolist do
            DEFAULT_CHAT_FRAME:AddMessage("    "..k)
            local opts = "        ("
            if QuestHaste_IsAutoAccept(k) then
                opts = opts .. "|cff00ff00"
            else
                opts = opts .. "|cffff0000"
            end
            opts = opts .. "accept|r | "
            if QuestHaste_IsAutoComplete(k) then
                opts = opts .. "|cff00ff00"
            else
                opts = opts .. "|cffff0000"
            end
            opts = opts .. "complete|r)"
            DEFAULT_CHAT_FRAME:AddMessage(opts)
        end
    elseif command == "pause" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff88QuestHaste|r: |cffff0000paused|r.")
        QuestHaste_UnregisterEvents()
    elseif command == "resume" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff88QuestHaste|r: |cff00ff00active|r.")
        QuestHaste_RegisterEvents()
    elseif command == "complete" then
        QuestHaste_Proceed()
    elseif command == "reset" then
        QuestHaste.autolist = {}
    else
        DEFAULT_CHAT_FRAME:AddMessage("Syntax:\n/qhaste usage\n/qhaste add\n/qhaste list\n/qhaste complete\n/qhaste pause\n/qhaste resume\n/qhaste reset");
    end
end
SLASH_QUESTHASTE1 = "/questhaste"
SLASH_QUESTHASTE2 = "/qhaste"
SlashCmdList["QUESTHASTE"] = CommandParser
