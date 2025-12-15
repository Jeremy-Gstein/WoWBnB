local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")

initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "WoWBnB" then return end

    WoWBnB_HousesDB = WoWBnB_HousesDB or {}
    WoWBnB_HousesDB.houses = WoWBnB_HousesDB.houses or {}

    local collapsedNeighborhoods = {}
    local selectedIndex = nil

    local searchText = ""
    local sortMode = "NEIGHBORHOOD"

    ------------------------------------------------------------
    -- Main Frame
    ------------------------------------------------------------
    local frame = CreateFrame("Frame", "WoWBnBCollectionFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(450, 540)
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
    -- Debug Frame
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
    -- Search Box
    ------------------------------------------------------------
    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetSize(200, 24)
    local clearButtonWidth = 22
    local padding = 4
    searchBox:SetTextInsets(4, clearButtonWidth + padding, 0, 0)

    searchBox:SetPoint("TOPLEFT", 20, -32)
    searchBox:SetAutoFocus(false)

    -- Placeholder text (visual only)
    local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholder:SetPoint("LEFT", 8, 0)
    placeholder:SetText("Search...")
    placeholder:Show()

    local clearBtn
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

    searchBox:SetScript("OnEditFocusGained", function()
        placeholder:Hide()
    end)

    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            placeholder:Show()
        end
    end)

    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    ------------------------------------------------------------
    -- Clear Search Button
    ------------------------------------------------------------
    -- Clear Search Button (inside EditBox)
    clearBtn = CreateFrame("Button", nil, searchBox)
    clearBtn:SetSize(18, 18)
    clearBtn:SetPoint("RIGHT", -4, 0)

    -- Ensure it sits ABOVE the EditBox
    clearBtn:SetFrameLevel(searchBox:GetFrameLevel() + 10)

    clearBtn:SetAlpha(0.6)

    clearBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    clearBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    clearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")

    -- Force textures to fill the button
    clearBtn:GetNormalTexture():SetAllPoints()
    clearBtn:GetPushedTexture():SetAllPoints()
    clearBtn:GetHighlightTexture():SetAllPoints()

    -- Slightly bigger clickable area
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
        self:Hide()
    end)

    ------------------------------------------------------------
    -- Sort Dropdown
    ------------------------------------------------------------
    local sortDropdown = CreateFrame("Frame", "WoWBnBSortDropdown", frame, "UIDropDownMenuTemplate")
    sortDropdown:SetPoint("TOPRIGHT", -20, -31)

    UIDropDownMenu_SetWidth(sortDropdown, 150)
    UIDropDownMenu_SetText(sortDropdown, "Sort: Neighborhood")

    UIDropDownMenu_Initialize(sortDropdown, function()
        local function Add(text, value)
            UIDropDownMenu_AddButton({
                text = text,
                checked = (sortMode == value),
                func = function()
                    sortMode = value
                    UIDropDownMenu_SetText(sortDropdown, "Sort: " .. text)
                    WoWBnB_RefreshUIList()
                end
            })
        end

        Add("Neighborhood", "NEIGHBORHOOD")
        Add("Owner", "OWNER")
        Add("Recently Added", "RECENT")
        Add("Most Visited", "MOST_VISITED")
    end)

    ------------------------------------------------------------
    -- Results Counter (X / Y houses shown)
    ------------------------------------------------------------
    local resultsText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    resultsText:SetPoint("TOPLEFT", 20, -60)
    resultsText:SetHeight(32) -- allow two lines
    resultsText:SetJustifyH("LEFT")
    resultsText:SetText("")

    ------------------------------------------------------------
    -- Scroll Frame
    ------------------------------------------------------------
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -92)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 110)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(400, 1)
    scrollFrame:SetScrollChild(content)

    ------------------------------------------------------------
    -- Hover Highlight
    ------------------------------------------------------------
    local function AddHoverHighlight(row)
        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 0, 0.15)
        hl:Hide()
        row:SetScript("OnEnter", function() hl:Show() end)
        row:SetScript("OnLeave", function() hl:Hide() end)
    end

    ------------------------------------------------------------
    -- Refresh List (SEARCH + SORT)
    ------------------------------------------------------------
    function WoWBnB_RefreshUIList()
        for _, child in ipairs({ content:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end

        local filtered = {}

        for i, h in ipairs(WoWBnB_HousesDB.houses) do
            local owner = (h.owner or ""):lower()
            local neighborhood = (h.neighborhood or ""):lower()

            if searchText == ""
                or owner:find(searchText, 1, true)
                or neighborhood:find(searchText, 1, true) then

                table.insert(filtered, {
                    index = i,
                    owner = h.owner,
                    neighborhood = h.neighborhood,
                    data = h,
                })
            end
        end

        -- Group filtered houses by neighborhood
        local grouped = {}
        for _, h in ipairs(filtered) do
            grouped[h.neighborhood] = grouped[h.neighborhood] or {}
            table.insert(grouped[h.neighborhood], h)
        end

        -- Count neighborhoods
        local filteredNeighborhoodCount = 0
        for _, hlist in pairs(grouped) do
            if #hlist > 0 then
                filteredNeighborhoodCount = filteredNeighborhoodCount + 1
            end
        end

        local totalNeighborhoodCount = 0
        local allNeighborhoods = {}
        for _, h in ipairs(WoWBnB_HousesDB.houses) do
            allNeighborhoods[h.neighborhood] = true
        end
        for _ in pairs(allNeighborhoods) do totalNeighborhoodCount = totalNeighborhoodCount + 1 end

        -- Update results counter
        resultsText:SetText(
            string.format("%d / %d Houses shown\n%d / %d Neighborhoods shown",
                #filtered,
                #WoWBnB_HousesDB.houses,
                filteredNeighborhoodCount,
                totalNeighborhoodCount
            )
        )

        -- Sorting logic (same as before)
        table.sort(filtered, function(a, b)
            if sortMode == "OWNER" then
                return a.owner < b.owner
            elseif sortMode == "RECENT" then
                return (a.data.addedAt or 0) > (b.data.addedAt or 0)
            elseif sortMode == "MOST_VISITED" then
                return (a.data.visitCount or 0) > (b.data.visitCount or 0)
            else
                if a.neighborhood == b.neighborhood then
                    return a.owner < b.owner
                end
                return a.neighborhood < b.neighborhood
            end
        end)

        -- Build UI rows (same as before)
        local yOffset = -10
        local neighborhoods = {}
        for k in pairs(grouped) do table.insert(neighborhoods, k) end
        table.sort(neighborhoods)

        for _, neighborhood in ipairs(neighborhoods) do
            local header = CreateFrame("Frame", nil, content)
            header:SetSize(360, 24)
            header:SetPoint("TOPLEFT", 10, yOffset)
            AddHoverHighlight(header)

            local toggle = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
            toggle:SetSize(22, 20)
            toggle:SetPoint("LEFT", 0, 0)
            toggle:SetText(collapsedNeighborhoods[neighborhood] and "+" or "-")
            toggle:SetScript("OnClick", function()
                collapsedNeighborhoods[neighborhood] = not collapsedNeighborhoods[neighborhood]
                WoWBnB_RefreshUIList()
            end)

            header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            header.text:SetPoint("LEFT", 28, 0)
            header.text:SetText(neighborhood)

            yOffset = yOffset - 28

            if not collapsedNeighborhoods[neighborhood] then
                for _, h in ipairs(grouped[neighborhood]) do
                    local row = CreateFrame("Frame", nil, content)
                    row:SetSize(330, 22)
                    row:SetPoint("TOPLEFT", 40, yOffset)
                    AddHoverHighlight(row)

                    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    row.text:SetPoint("LEFT", 0, 0)
                    row.text:SetText(h.owner)

                    local go = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    go:SetSize(50, 20)
                    go:SetPoint("RIGHT", -60, 0)
                    go:SetText("Go")
                    go:SetScript("OnClick", function()
                        WoWBnB_RunHouseCommand(h.index)
                    end)

                    local remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    remove:SetSize(60, 20)
                    remove:SetPoint("RIGHT", 0, 0)
                    remove:SetText("Remove")
                    remove:SetScript("OnClick", function()
                        selectedIndex = h.index
                        confirmFrame:Show()
                    end)

                    yOffset = yOffset - 26
                end
            end
        end

        content:SetHeight(-yOffset + 20)
    end

    ------------------------------------------------------------
    -- Bottom Button
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
        exportFrame.title:SetText("Debug Saved Housed")

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
