local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "PVPTalentHider" then
        -- Set hidden talents saved variable if none
        if not PTH_HiddenTalents then
            print("Setting up hidden talents database")
            PTH_HiddenTalents = {}
        end
    end

    -- Only filter pvp talents once the parent frame has loaded
    if event == "ADDON_LOADED" and arg1 == "Blizzard_PlayerSpells" then
        HookPvPTalentList()
    end
end)

function isTalentHidden(talentID)
    for _, id in ipairs(PTH_HiddenTalents) do
        if id == talentID then
            return true
        end
    end
    return false
end

-- Function to add a talent ID to the hidden list
function addTalentToHiddenList(talentID)
    if not isTalentHidden(talentID) then
        table.insert(PTH_HiddenTalents, talentID)
        print("|cffffcc00PVPTalentHider - TalentID " .. talentID .. " |cffff0000hidden|r.|r")
    else
        print("PVP Talent ID " .. talentID .. " is already hidden.")
    end
end

-- Function to remove a talent ID from the hidden list
function removeTalentFromHiddenList(talentID)
    for i, id in ipairs(PTH_HiddenTalents) do
        if id == talentID then
            table.remove(PTH_HiddenTalents, i)
            print("|cffffcc00PVPTalentFilter - TalentID " .. talentID .. " |cff33ff99shown|r.|r")
            return
        end
    end
    print("PVP Talent ID " .. talentID .. " not found in hidden list.")
end

-- Function to adjust visibility when the PvP talent list shows
function HookPvPTalentList()
    local pvpTalentList = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame and
        PlayerSpellsFrame.TalentsFrame.PvPTalentList

    if not pvpTalentList then
        print("PvP Talent List not found!")
        return
    end

    local scrollBox = pvpTalentList.ScrollBox

    if not scrollBox then
        print("PVP Talent List ScrollBox not found!")
        return
    end

    -- Hook the Update function of the ScrollBox
    hooksecurefunc(scrollBox, "Update", function(self)
        for _, talentButton in pairs(self:GetFrames()) do
            if talentButton.talentID then
                configureTalentButtonVisibility(talentButton, isTalentHidden(talentButton.talentID))
                createHideButton(talentButton)
            end
        end
    end)

    -- PlayerSpells is not nil as Blizzard_PlayerSpells has loaded
    local unhideButton = CreateFrame("Button", "PTHUnhide", pvpTalentList, "UIPanelButtonTemplate")
    unhideButton:SetSize(80, 30)
    unhideButton:SetText("Unhide")
    unhideButton:SetPoint("TOPRIGHT", 0, 25)

    unhideButton:SetScript("OnClick", function()
        for _, talentButton in pairs(scrollBox:GetFrames()) do
            if talentButton.talentID then
                configureTalentButtonVisibility(talentButton, false)
            end
        end
    end)
end

function configureTalentButtonVisibility(talentButton, shouldHide)
    if shouldHide then
        talentButton:Hide()

        if not isTalentHidden(talentButton.talentID) then
            addTalentToHiddenList(talentButton.talentID)
        end
    else
        talentButton:Show()

        if isTalentHidden(talentButton.talentID) then
            removeTalentFromHiddenList(talentButton.talentID)
        end
    end
end

function createHideButton(talentButton)
    -- Check if the button already exists to avoid creating a new one every time
    if talentButton.hideButton then
        return -- If the hide button exists, exit the function
    end

    -- PlayerSpells is not nil as Blizzard_PlayerSpells has loaded
    local button = CreateFrame("Button", talentButton.talentID, talentButton, "UIPanelButtonTemplate")
    button:SetSize(20, 20)
    button:SetText("x")
    button:SetPoint("RIGHT", 0, 0)

    -- Store the button reference in talentButton to reuse it next time
    talentButton.hideButton = button

    button:SetScript("OnClick", function()
        configureTalentButtonVisibility(talentButton, true)
    end)
end
