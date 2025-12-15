------------------------------------------------------------
-- SavedVariables
------------------------------------------------------------
WoWBnB_HousesDB = WoWBnB_HousesDB or { houses = {} }

------------------------------------------------------------
-- Add a house
------------------------------------------------------------
function WoWBnB_AddHouse(owner, neighborhood, neighborhoodGUID, houseGUID, plotID)
    if not owner or not neighborhood or not neighborhoodGUID or not plotID then
        print("WoWBnB: Cannot save house, missing data.")
        return false
    end

    for _, h in ipairs(WoWBnB_HousesDB.houses) do
        if h.owner == owner and h.neighborhood == neighborhood and h.plotID == plotID then
            print("House already saved: " .. neighborhood .. " - " .. owner .. " plot " .. plotID)
            return false
        end
    end

    table.insert(WoWBnB_HousesDB.houses, {
        owner = owner,
        neighborhood = neighborhood,
        neighborhoodGUID = neighborhoodGUID,
        houseGUID = houseGUID,
        plotID = plotID,

        addedAt = time(),
        lastVisited = nil,
        visitCount = 0,
    })

    print("Saved house: " .. neighborhood .. " - " .. owner .. " plot " .. plotID)

    if WoWBnB_RefreshUIList then
        WoWBnB_RefreshUIList()
    end

    return true
end

------------------------------------------------------------
-- Teleport using saved GUID first, then brute-force Opaque-1..20
-- Detect casting with OnUpdate
------------------------------------------------------------
function WoWBnB_RunHouseCommand(index)
    local h = WoWBnB_HousesDB.houses[index]
    if not h or not (h.neighborhoodGUID and h.plotID) then
        print("WoWBnB: House info incomplete.")
        return
    end

    print("WoWBnB: Attempting teleport to " .. h.neighborhood .. " plot " .. h.plotID)

    -- Build attempt list: saved GUID first, then fallback Opaque-1..20
    local attempts = {}
    if h.houseGUID then
        table.insert(attempts, h.houseGUID)
    end
    for i = 1, 20 do
        table.insert(attempts, "Opaque-" .. i)
    end

    local attemptIndex = 1
    local isCasting = false
    local successHandled = false

    -- Frame to handle retries and spell events
    local frame = CreateFrame("Frame")
    
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")

    frame:SetScript("OnEvent", function(self, event, unit, _, spellID)
        if unit ~= "player" then return end

        local spellInfo = C_Spell.GetSpellInfo(spellID)
        local spellName = spellInfo.name

        if spellName ~= "House Visit" then return end

        if event == "UNIT_SPELLCAST_START" then
            isCasting = true
        elseif event == "UNIT_SPELLCAST_STOP" then
            isCasting = false
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" and not successHandled then
            successHandled = true
            h.lastVisited = time()
            h.visitCount = (h.visitCount or 0) + 1
            print("WoWBnB: Successfully visited house: " .. h.neighborhood)

            self:UnregisterAllEvents()
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
    end)

    frame:SetScript("OnUpdate", function(self, elapsed)
        if successHandled then
            self:SetScript("OnUpdate", nil)
            return
        end

        -- Only attempt a new VisitHouse if not currently casting
        if not isCasting and attemptIndex <= #attempts then
            local guid = attempts[attemptIndex]
            print("WoWBnB: Trying houseGUID " .. guid)
            C_Housing.VisitHouse(h.neighborhoodGUID, guid, h.plotID)
            attemptIndex = attemptIndex + 1
        end
    end)
end

------------------------------------------------------------
-- "DEBUG"
------------------------------------------------------------
function WoWBnB_DebugHouses()
    local t = {}
    for _, h in ipairs(WoWBnB_HousesDB.houses) do
        table.insert(t,
            h.neighborhood .. "|" ..
            h.owner .. "|" ..
            h.neighborhoodGUID .. "|" ..
            (h.houseGUID or "") .. "|" ..
            h.plotID
        )
    end
    return table.concat(t, "\n")
end

------------------------------------------------------------
-- Save current house
------------------------------------------------------------
function WoWBnB_SaveCurrentHouse()
    local houseInfo = C_Housing.GetCurrentHouseInfo()
    if not houseInfo then
        print("You must be standing on a house plot to save it.")
        return
    end

    WoWBnB_AddHouse(
        houseInfo.ownerName or "Unknown",
        houseInfo.neighborhoodName or "Unknown",
        houseInfo.neighborhoodGUID,
        houseInfo.houseGUID,
        houseInfo.plotID
    )
end
