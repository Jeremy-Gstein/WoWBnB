-- Main frame
local frame = CreateFrame("Frame", "WoWBnBCoreFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(400, 200)
frame:SetPoint("CENTER")
frame:Hide()

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
frame.title:SetText("WoWBnB - Share your house with everyone!")

-- Multiline edit box
local scrollFrame = CreateFrame("ScrollFrame", "WoWBnBCoreScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 16, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

local editBox = CreateFrame("EditBox", "WoWBnBCoreEditBox", scrollFrame)
editBox:SetMultiLine(true)
editBox:SetFontObject(ChatFontNormal)
editBox:SetWidth(340)
editBox:SetAutoFocus(true)
-- Default message appears in box when not currently at a housing plot.
editBox:SetText("Thank you for checking out WoWBnB (:\n\n\nHow-to:\n\n1. be on your house plot before running /wowbnb.\n\n2. copy and share the command that will appear here")

scrollFrame:SetScrollChild(editBox)

-- Close on Ctrl+C (similar to how /simc handles clipboard)
editBox:SetScript("OnKeyDown", function(self, key)
  if key == "C" and IsControlKeyDown() then
    frame:Hide()
  end
end)

-- Okay button
local okButton = CreateFrame("Button", "WoWBnBCoreOkButton", frame, "UIPanelButtonTemplate")
okButton:SetSize(80, 24)
okButton:SetPoint("BOTTOM", 0, 12)
okButton:SetText("Okay")

okButton:SetScript("OnClick", function()
  frame:Hide()
end)

-- Slash command to toggle frame
SLASH_WOWBNBCOPY1 = "/wowbnb"
SLASH_WOWBNBCOPY2 = "/wbnb"
SlashCmdList["WOWBNBCOPY"] = function()
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
    local houseInfo = C_Housing.GetCurrentHouseInfo()
    editBox:SetText("/run C_Housing.VisitHouse(\"" .. houseInfo.neighborhoodGUID .. "\", \"" .. houseInfo.houseGUID .. "\", " .. houseInfo.plotID .. ")")
    editBox:HighlightText()
    editBox:SetFocus()
  end
end
