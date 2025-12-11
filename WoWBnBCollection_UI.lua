local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")

initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "WoWBnB" then return end

    -- Initialize saved variables
    WoWBnB_HousesDB = WoWBnB_HousesDB or {}
    WoWBnB_HousesDB.houses = WoWBnB_HousesDB.houses or {}

    local collapsedNeighborhoods = {}
    local selectedIndex = nil

    -- Main frame
    local frame = CreateFrame("Frame", "WoWBnBCollectionFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(450, 500)
    frame:Hide()
    frame:SetPoint("CENTER")

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", 0, -5)
    frame.title:SetText("My Favorite Houses")

    -- Modal overlay
    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints(frame)
    overlay:EnableMouse(true)
    overlay:Hide()
    overlay:SetFrameStrata("HIGH")

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "WoWBnBCollectionScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 100)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(400, 1)
    scrollFrame:SetScrollChild(content)

    -- Confirmation popup
    local confirmFrame = CreateFrame("Frame", "WoWBnBConfirmFrame", frame, "BasicFrameTemplateWithInset")
    confirmFrame:SetSize(300, 150)
    confirmFrame:SetPoint("CENTER", frame, "CENTER")
    confirmFrame:SetFrameStrata("DIALOG")
    confirmFrame:SetFrameLevel(frame:GetFrameLevel() + 50)
    confirmFrame:Hide()

    confirmFrame.title = confirmFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    confirmFrame.title:SetPoint("TOP", 0, -5)
    confirmFrame.title:SetText("Confirm Removal")

    local confirmText = confirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    confirmText:SetPoint("CENTER", 0, 0)
    confirmText:SetText("Are you sure you want to remove this house?")

    local yesBtn = CreateFrame("Button", nil, confirmFrame, "UIPanelButtonTemplate")
    yesBtn:SetSize(80, 24)
    yesBtn:SetPoint("BOTTOMLEFT", 30, 10)
    yesBtn:SetText("Yes")
    yesBtn:SetScript("OnClick", function()
        if selectedIndex then
            table.remove(WoWBnB_HousesDB.houses, selectedIndex)
            WoWBnB_RefreshUIList()
            selectedIndex = nil
        end
        confirmFrame:Hide()
    end)

    local noBtn = CreateFrame("Button", nil, confirmFrame, "UIPanelButtonTemplate")
    noBtn:SetSize(80, 24)
    noBtn:SetPoint("BOTTOMRIGHT", -30, 10)
    noBtn:SetText("No")
    noBtn:SetScript("OnClick", function()
        selectedIndex = nil
        confirmFrame:Hide()
    end)

    confirmFrame:SetScript("OnShow", function() overlay:Show() end)
    confirmFrame:SetScript("OnHide", function() overlay:Hide() end)

    -- Highlight for rows
    local function AddHoverHighlight(frame)
        local hl = frame:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints(frame)
        hl:SetColorTexture(1, 1, 0, 0.2)
        hl:Hide()

        frame:SetScript("OnEnter", function() hl:Show() end)
        frame:SetScript("OnLeave", function() hl:Hide() end)
    end

    -- Refresh list
    function WoWBnB_RefreshUIList()
        for _, child in ipairs({content:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end

        local yOffset = -10

        local grouped = {}
        for i, h in ipairs(WoWBnB_HousesDB.houses) do
            grouped[h.neighborhood] = grouped[h.neighborhood] or {}
            table.insert(grouped[h.neighborhood], {index = i, owner = h.owner})
        end

        local neighborhoods = {}
        for k in pairs(grouped) do table.insert(neighborhoods, k) end
        table.sort(neighborhoods)

        for _, neighborhood in ipairs(neighborhoods) do
            local houses = grouped[neighborhood]

            local neighborhoodRow = CreateFrame("Frame", nil, content)
            neighborhoodRow:SetSize(360, 25)
            neighborhoodRow:SetPoint("TOPLEFT", 10, yOffset)
            AddHoverHighlight(neighborhoodRow)

            local toggleBtn = CreateFrame("Button", nil, neighborhoodRow, "UIPanelButtonTemplate")
            toggleBtn:SetSize(25, 20)
            toggleBtn:SetPoint("LEFT", 0, 0)
            toggleBtn:SetText(collapsedNeighborhoods[neighborhood] and "+" or "-")
            toggleBtn:SetScript("OnClick", function()
                collapsedNeighborhoods[neighborhood] = not collapsedNeighborhoods[neighborhood]
                WoWBnB_RefreshUIList()
            end)

            neighborhoodRow.label = neighborhoodRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            neighborhoodRow.label:SetPoint("LEFT", 30, 0)
            neighborhoodRow.label:SetText(neighborhood)

            yOffset = yOffset - 30

            if not collapsedNeighborhoods[neighborhood] then
                for _, h in ipairs(houses) do
                    local ownerRow = CreateFrame("Frame", nil, content)
                    ownerRow:SetSize(340, 25)
                    ownerRow:SetPoint("TOPLEFT", 40, yOffset)
                    AddHoverHighlight(ownerRow)

                    ownerRow.label = ownerRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    ownerRow.label:SetPoint("LEFT", 0, 0)
                    ownerRow.label:SetText(h.owner)

                    local runBtn = CreateFrame("Button", nil, ownerRow, "UIPanelButtonTemplate")
                    runBtn:SetSize(60, 20)
                    runBtn:SetPoint("RIGHT", -65, 0)
                    runBtn:SetText("Go")
                    runBtn:SetScript("OnClick", function()
                        WoWBnB_RunHouseCommand(h.index)
                    end)

                    local removeBtn = CreateFrame("Button", nil, ownerRow, "UIPanelButtonTemplate")
                    removeBtn:SetSize(60, 20)
                    removeBtn:SetPoint("RIGHT", 0, 0)
                    removeBtn:SetText("Remove")
                    removeBtn:SetScript("OnClick", function()
                        selectedIndex = h.index
                        confirmFrame:Show()
                    end)

                    yOffset = yOffset - 30
                end
            end
        end

        content:SetHeight(-yOffset + 10)
    end

    WoWBnB_RefreshUIList = WoWBnB_RefreshUIList

    -- Bottom buttons
    local saveBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveBtn:SetSize(160, 30)
    saveBtn:SetPoint("BOTTOM", 0, 60)
    saveBtn:SetText("Save Current House")
    saveBtn:SetScript("OnClick", WoWBnB_SaveCurrentHouse)

    -- Export/Import remain largely unchanged
    -- But updated for new format with GUIDs
    local exportBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    exportBtn:SetSize(160, 30)
    exportBtn:SetPoint("BOTTOMLEFT", 20, 10)
    exportBtn:SetText("Export Houses")
    exportBtn:SetScript("OnClick", function()
        local exportStr = WoWBnB_ExportHouses()

        local exportFrame = CreateFrame("Frame", "WoWBnBExportFrame", frame, "BasicFrameTemplateWithInset")
        exportFrame:SetSize(400, 300)
        exportFrame:SetPoint("CENTER", frame, "CENTER")
        exportFrame:SetFrameStrata("DIALOG")
        exportFrame:SetFrameLevel(frame:GetFrameLevel() + 50)
        exportFrame:Hide()

        exportFrame.title = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        exportFrame.title:SetPoint("TOP", 0, -5)
        exportFrame.title:SetText("Exported Houses")

        local scroll = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 10, -40)
        scroll:SetPoint("BOTTOMRIGHT", -10, 40)

        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(360)
        edit:SetAutoFocus(false)
        edit:SetText(exportStr)
        scroll:SetScrollChild(edit)
        edit:HighlightText()

        local okBtn = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
        okBtn:SetSize(80, 24)
        okBtn:SetPoint("BOTTOM", 0, 10)
        okBtn:SetText("Close")
        okBtn:SetScript("OnClick", function() exportFrame:Hide() end)

        exportFrame:SetScript("OnShow", function() overlay:Show() end)
        exportFrame:SetScript("OnHide", function() overlay:Hide() end)

        exportFrame:Show()
    end)

    local importBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    importBtn:SetSize(160, 30)
    importBtn:SetPoint("BOTTOMRIGHT", -20, 10)
    importBtn:SetText("Import Houses")
    importBtn:SetScript("OnClick", function()
        local importFrame = CreateFrame("Frame", "WoWBnBImportFrame", frame, "BasicFrameTemplateWithInset")
        importFrame:SetSize(400, 300)
        importFrame:SetPoint("CENTER", frame, "CENTER")
        importFrame:SetFrameStrata("DIALOG")
        importFrame:SetFrameLevel(frame:GetFrameLevel() + 50)
        importFrame:Hide()

        importFrame.title = importFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        importFrame.title:SetPoint("TOP", 0, -5)
        importFrame.title:SetText("Import Houses")

        local scroll = CreateFrame("ScrollFrame", nil, importFrame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 10, -40)
        scroll:SetPoint("BOTTOMRIGHT", -10, 40)

        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(360)
        edit:SetAutoFocus(true)
        scroll:SetScrollChild(edit)

        local okBtn = CreateFrame("Button", nil, importFrame, "UIPanelButtonTemplate")
        okBtn:SetSize(80, 24)
        okBtn:SetPoint("BOTTOM", 0, 10)
        okBtn:SetText("Import")
        okBtn:SetScript("OnClick", function()
            local text = edit:GetText()
            WoWBnB_ImportHouses(text)
            importFrame:Hide()
        end)

        importFrame:SetScript("OnShow", function() overlay:Show() end)
        importFrame:SetScript("OnHide", function() overlay:Hide() end)

        importFrame:Show()
    end)

    -- Slash command
    SLASH_WOWBNBCOLLECTION1 = "/wowbnbc"
    SlashCmdList["WOWBNBCOLLECTION"] = function()
        if frame:IsShown() then
            frame:Hide()
        else
            frame:ClearAllPoints()
            frame:SetPoint("CENTER")
            frame:Show()
            WoWBnB_RefreshUIList()
        end
    end

    self:UnregisterEvent("ADDON_LOADED")
end)
