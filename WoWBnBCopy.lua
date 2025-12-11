-- Main frame
local frame = CreateFrame("Frame", "WoWBnBCopyFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(400, 200)
frame:SetPoint("CENTER")
frame:Hide()

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
frame.title:SetText("WoWBnB ~ Share your house with everyone!")

-- Multiline edit box
local scrollFrame = CreateFrame("ScrollFrame", "WoWBnBCopyScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 16, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

local editBox = CreateFrame("EditBox", "WoWBnBCopyEditBox", scrollFrame)
editBox:SetMultiLine(true)
editBox:SetFontObject(ChatFontNormal)
editBox:SetWidth(340)
editBox:SetAutoFocus(true)
editBox:SetText("How-to: 1. be on your house plot before running /wowbnb. 2. copy and share the command that will appear here")

scrollFrame:SetScrollChild(editBox)

-- Close on Ctrl+C (similar to how /simc handles clipboard)
editBox:SetScript("OnKeyDown", function(self, key)
  if key == "C" and IsControlKeyDown() then
    frame:Hide()
  end
end)

-- Okay button
local okButton = CreateFrame("Button", "WoWBnBCopyOkButton", frame, "UIPanelButtonTemplate")
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
    houseInfo = C_Housing.GetCurrentHouseInfo()
    -- /run C_Housing.VisitHouse(houseInfo.neighborehoodGUID, houseInfo.houseGUID, houseInfo.plotID)
    editBox:SetText("/run C_Housing.VisitHouse(\"" .. houseInfo.neighborhoodGUID .. "\", \"" .. houseInfo.houseGUID .. "\", " .. houseInfo.plotID .. ")")
    editBox:HighlightText()
    editBox:SetFocus()
  end
end
