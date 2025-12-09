WoWBnB = CreateFrame("Frame")

function WoWBnB:OnEvent(event, ...)
	self[event](self, event, ...)
end
WoWBnB:SetScript("OnEvent", WoWBnB.OnEvent)
WoWBnB:RegisterEvent("ADDON_LOADED")

function WoWBnB:ADDON_LOADED(event, addOnName)
	if addOnName == "WoWBnB" then
		WoWBnBDB = WoWBnBDB or {}
		self.db = WoWBnBDB
		for k, v in pairs(self.defaults) do
			if self.db[k] == nil then
				self.db[k] = v
			end
		end
		self.db.sessions = self.db.sessions + 1
		print("You loaded this addon "..self.db.sessions.." times")

		local version, build, _, tocversion = GetBuildInfo()
		print(format("The current WoW build is %s (%d) and TOC is %d", version, build, tocversion))

		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		hooksecurefunc("JumpOrAscendStart", self.JumpOrAscendStart)

		self:InitializeOptions()
		self:UnregisterEvent(event)
	end
end

function WoWBnB:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
	if isLogin and self.db.hello then
		DoEmote("HELLO")
	end
end

-- note we don't pass `self` here because of hooksecurefunc, hence the dot instead of colon
function WoWBnB.JumpOrAscendStart()
	if WoWBnB.db.jump then
		print("Your character jumped.")
	end
end

function WoWBnB:COMBAT_LOG_EVENT_UNFILTERED(event)
	-- it's more convenient to work with the CLEU params as a vararg
	self:CLEU(CombatLogGetCurrentEventInfo())
end

local playerGUID = UnitGUID("player")
local MSG_DAMAGE = "Your %s hit %s for %d damage."

function WoWBnB:CLEU(...)
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
	local spellId, spellName, spellSchool
	local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
	local isDamageEvent

	if subevent == "SWING_DAMAGE" then
		amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
		isDamageEvent = true
	elseif subevent == "SPELL_DAMAGE" then
		spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
		isDamageEvent = true
	end

	if isDamageEvent and sourceGUID == playerGUID then
		-- get the link of the spell or the MELEE globalstring
		local action = spellId and GetSpellLink(spellId) or MELEE
		print(MSG_DAMAGE:format(action, destName, amount))
	end
end

SLASH_HELLOW1 = "/hw"
SLASH_HELLOW2 = "/helloworld"

SlashCmdList.HELLOW = function(msg, editBox)
	InterfaceOptionsFrame_OpenToCategory(WoWBnB.panel_main)
end
