local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")

initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "WoWBnB" then return end

    WoWBnB_HousesDB = WoWBnB_HousesDB or {}
    WoWBnB_HousesDB.houses = WoWBnB_HousesDB.houses or {}

    local selectedIndex = nil
    local searchText = ""

    ------------------------------------------------------------
    -- Main Frame
    ------------------------------------------------------------
    local frame = CreateFrame("Frame", "WoWBnBCollectionFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(700, 540) -- increased width to fit table
    frame:SetPoint("CENTER")
    frame:Hide()
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", 0, -5)
    frame.title:SetText("My Favorite Houses")

    ------------------------------------------------------------
    -- Overlay (for modals)
    ------------------------------------------------------------
    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints(frame)
    overlay:EnableMouse(true)
    overlay:Hide()
    overlay:SetFrameStrata("HIGH")

    ------------------------------------------------------------
    -- Confirmation Frame
    ------------------------------------------------------------
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

    ------------------------------------------------------------
    -- Search Box + Clear Button
    ------------------------------------------------------------
    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetSize(200, 24)
    local clearButtonWidth = 22
    local padding = 4
    searchBox:SetTextInsets(4, clearButtonWidth + padding, 0, 0)
    searchBox:SetPoint("TOPLEFT", 20, -32)
    searchBox:SetAutoFocus(false)

    local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholder:SetPoint("LEFT", 8, 0)
    placeholder:SetText("Search...")
    placeholder:Show()

    local clearBtn = CreateFrame("Button", nil, searchBox)
    clearBtn:SetSize(18, 18)
    clearBtn:SetPoint("RIGHT", -4, 0)
    clearBtn:SetFrameLevel(searchBox:GetFrameLevel() + 10)
    clearBtn:SetAlpha(0.6)
    clearBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    clearBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    clearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    clearBtn:GetNormalTexture():SetAllPoints()
    clearBtn:GetPushedTexture():SetAllPoints()
    clearBtn:GetHighlightTexture():SetAllPoints()
    clearBtn:SetHitRectInsets(-6, -6, -6, -6)
    clearBtn:Hide()

    clearBtn:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Clear search")
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave", function(self)
        self:SetAlpha(0.6)
        GameTooltip:Hide()
    end)
    clearBtn:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
        placeholder:Show()
        clearBtn:Hide()
    end)

    searchBox:SetScript("OnTextChanged", function(self)
        searchText = self:GetText():lower()
        if searchText == "" then
            placeholder:Show()
            clearBtn:Hide()
        else
            placeholder:Hide()
            clearBtn:Show()
        end
        WoWBnB_RefreshUIList()
    end)

    searchBox:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then placeholder:Show() end
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    ------------------------------------------------------------
    -- Results Counter
    ------------------------------------------------------------
    local resultsText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    resultsText:SetPoint("TOPLEFT", 20, -60)
    resultsText:SetHeight(32)
    resultsText:SetJustifyH("LEFT")
    resultsText:SetText("")

    ------------------------------------------------------------
    -- Scroll Frame
    ------------------------------------------------------------
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -92)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 110)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(frame:GetWidth() - 40, 1)
    scrollFrame:SetScrollChild(content)

    ------------------------------------------------------------
    -- Table Header with Sorting
    ------------------------------------------------------------
    local columnNames = { "Owner", "Neighborhood", "Times Visited", "Actions" }
    local columnWidths = { Owner = 160, Neighborhood = 180, ["Times Visited"] = 120, Actions = 140 }

    local headerRow = CreateFrame("Frame", nil, content)
    headerRow:SetSize(content:GetWidth(), 28)
    headerRow:SetPoint("TOPLEFT", 0, 0)

    local headerFS = {}
    local headerArrows = {}

    -- Sorting state
    local sortColumn = "Owner"
    local sortAscending = true

    local xOffset = 0
    for _, colName in ipairs(columnNames) do
        -- Header fontstring
        headerFS[colName] = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerFS[colName]:SetPoint("TOPLEFT", xOffset + 4, -2)
        headerFS[colName]:SetText(colName)
        headerFS[colName]:SetJustifyH("LEFT")
        headerFS[colName]:SetFont(headerFS[colName]:GetFont(), 14, "OUTLINE")

        -- Arrow texture (right of text)
        headerArrows[colName] = headerRow:CreateTexture(nil, "OVERLAY")
        headerArrows[colName]:SetSize(28, 28)
        headerArrows[colName]:SetPoint("LEFT", headerFS[colName], "RIGHT", 6, 0)
        headerArrows[colName]:Hide()

        -- Clickable button overlay for sorting
        local btn = CreateFrame("Button", nil, headerRow)
        btn:SetSize(columnWidths[colName], 28)
        btn:SetPoint("TOPLEFT", xOffset, 0)
        btn:SetScript("OnClick", function()
            if sortColumn == colName then
                sortAscending = not sortAscending
            else
                sortColumn = colName
                sortAscending = true
            end
            WoWBnB_RefreshUIList()
        end)

        xOffset = xOffset + columnWidths[colName]
    end

    -- Function to update arrows based on sort state
    local function UpdateHeaderArrows()
        for _, colName in ipairs(columnNames) do
            if colName == sortColumn then
                headerArrows[colName]:Show()
                if sortAscending then
                    headerArrows[colName]:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up") -- up arrow
                else
                    headerArrows[colName]:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up") -- down arrow
                end
            else
                headerArrows[colName]:Hide()
            end
        end
    end

    ------------------------------------------------------------
    -- Refresh UI List
    ------------------------------------------------------------
    function WoWBnB_RefreshUIList()
        -- Clear existing rows except header
        for _, child in ipairs({content:GetChildren()}) do
            if child ~= headerRow then
                child:Hide()
                child:SetParent(nil)
            end
        end

        -- Filter houses
        local filteredHouses = {}
        for i, h in ipairs(WoWBnB_HousesDB.houses) do
            local owner = (h.owner or ""):lower()
            local neighborhood = (h.neighborhood or ""):lower()
            if searchText == "" or owner:find(searchText, 1, true) or neighborhood:find(searchText, 1, true) then
                table.insert(filteredHouses, {
                    index = i,
                    owner = h.owner or "",
                    neighborhood = h.neighborhood or "",
                    visits = h.visitCount or 0,
                    data = h
                })
            end
        end

        -- Sort
        table.sort(filteredHouses, function(a, b)
            local col = sortColumn
            local asc = sortAscending
            local valA, valB
            if col == "Owner" then valA, valB = a.owner, b.owner
            elseif col == "Neighborhood" then valA, valB = a.neighborhood, b.neighborhood
            elseif col == "Times Visited" then valA, valB = a.visits, b.visits
            else valA, valB = 0, 0 end
            valA = valA or ""
            valB = valB or ""
            if valA == valB then return a.index < b.index end
            if asc then return valA < valB else return valA > valB end
        end)

        -- Build rows
        local headerHeight = 28
        local rowHeight = 24
        local yOffset = -headerHeight
        local rowIndex = 0
        for _, h in ipairs(filteredHouses) do
            local row = CreateFrame("Frame", nil, content)
            row:SetSize(content:GetWidth(), rowHeight)
            row:SetPoint("TOPLEFT", 0, yOffset)

            -- Alternating background
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            if rowIndex % 2 == 0 then
                bg:SetColorTexture(1, 1, 1, 0.05)
            else
                bg:SetColorTexture(0, 0, 0, 0.05)
            end
            rowIndex = rowIndex + 1

            -- Helper to add cell
            local xOffsetCell = 0
            local function AddCell(text, columnName)
                local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                fs:SetPoint("TOPLEFT", xOffsetCell + 4, -2)
                fs:SetSize(columnWidths[columnName] - 8, rowHeight)
                fs:SetJustifyH("LEFT")
                fs:SetText(text)
                xOffsetCell = xOffsetCell + columnWidths[columnName]
                return fs
            end

            AddCell(h.owner, "Owner")
            AddCell(h.neighborhood, "Neighborhood")
            AddCell(h.visits, "Times Visited")

            -- Actions
            local actionsFrame = CreateFrame("Frame", nil, row)
            actionsFrame:SetSize(columnWidths.Actions, rowHeight)
            actionsFrame:SetPoint("TOPLEFT", xOffsetCell, 0)

            local goBtn = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
            goBtn:SetSize(50, 20)
            goBtn:SetPoint("LEFT", 0, 0)
            goBtn:SetText("Go")
            goBtn:SetScript("OnClick", function() WoWBnB_RunHouseCommand(h.index) end)

            local removeBtn = CreateFrame("Button", nil, actionsFrame, "UIPanelButtonTemplate")
            removeBtn:SetSize(60, 20)
            removeBtn:SetPoint("LEFT", 55, 0)
            removeBtn:SetText("Remove")
            removeBtn:SetScript("OnClick", function()
                selectedIndex = h.index
                confirmFrame:Show()
            end)

            yOffset = yOffset - rowHeight
        end

        content:SetHeight(-yOffset + 20)

        -- Update results text
        resultsText:SetText(string.format("%d / %d Houses shown", #filteredHouses, #WoWBnB_HousesDB.houses))

        -- Update header arrows for sorted column
        UpdateHeaderArrows()
    end

    ------------------------------------------------------------
    -- Bottom Buttons
    ------------------------------------------------------------
    local saveBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveBtn:SetSize(160, 30)
    saveBtn:SetPoint("BOTTOM", 0, 60)
    saveBtn:SetText("Save Current House")
    saveBtn:SetScript("OnClick", WoWBnB_SaveCurrentHouse)

    local exportBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    exportBtn:SetSize(160, 30)
    exportBtn:SetPoint("BOTTOMLEFT", 20, 10)
    exportBtn:SetText("Debug")
    exportBtn:SetScript("OnClick", function()
        local exportStr = WoWBnB_DebugHouses()
        local exportFrame = CreateFrame("Frame", "WoWBnBDebugFrame", frame, "BasicFrameTemplateWithInset")
        exportFrame:SetSize(400, 300)
        exportFrame:SetPoint("CENTER", frame, "CENTER")
        exportFrame:SetFrameStrata("DIALOG")
        exportFrame:SetFrameLevel(frame:GetFrameLevel() + 50)
        exportFrame:Hide()

        exportFrame.title = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        exportFrame.title:SetPoint("TOP", 0, -5)
        exportFrame.title:SetText("Debug Saved Houses")

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

    ------------------------------------------------------------
    -- Slash Command
    ------------------------------------------------------------
    SLASH_WOWBNBCOLLECTION1 = "/wowbnbc"
    SLASH_WOWBNBCOLLECTION2 = "/bnb"
    SlashCmdList["WOWBNBCOLLECTION"] = function()
        frame:SetShown(not frame:IsShown())
        WoWBnB_RefreshUIList()
    end

    self:UnregisterEvent("ADDON_LOADED")
end)
