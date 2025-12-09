local addonName = ...

-- Create main frame
local frame = CreateFrame("Frame", "HelloWorldCopyFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(300, 120)
frame:SetPoint("CENTER")
frame:Hide()

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
frame.title:SetText("Copy Text")

-- Edit box
local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
editBox:SetSize(260, 30)
editBox:SetPoint("TOP", 0, -40)
editBox:SetAutoFocus(false)
editBox:SetText("Hello World")

-- Copy button
local copyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
copyButton:SetSize(80, 22)
copyButton:SetPoint("BOTTOM", 0, 15)
copyButton:SetText("Copy")

copyButton:SetScript("OnClick", function()
    editBox:HighlightText()
    editBox:SetFocus()
end)

-- Slash command
SLASH_HELLOWORLDCOPY1 = "/hw"
SlashCmdList["HELLOWORLDCOPY"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        editBox:SetText("Hello World")
        editBox:HighlightText()
        editBox:SetFocus()
    end
end
