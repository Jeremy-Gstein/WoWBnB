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

    local attempts = {}

    -- Saved GUID first
    if h.houseGUID then
        table.insert(attempts, h.houseGUID)
    end

    -- Brute-force Opaque-1..20 *MAY REQURE TUNING IF <20 Exists
    for i = 1, 20 do
        table.insert(attempts, "Opaque-" .. i)
    end

    local frame = CreateFrame("Frame")
    local attemptIndex = 1

    frame:SetScript("OnUpdate", function(self)
        if attemptIndex > #attempts then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            return
        end

        if UnitCastingInfo("player") or UnitChannelInfo("player") then
            h.lastVisited = time()
            h.visitCount = (h.visitCount or 0) + 1
            self:SetScript("OnUpdate", nil)
            self:Hide()
            return
        end

        -- Try next attempt
        local guid = attempts[attemptIndex]
        C_Housing.VisitHouse(h.neighborhoodGUID, guid, h.plotID)

        if attemptIndex > 1 and attemptIndex % 5 == 0 then
            -- print("WoWBnB: Tried " .. attemptIndex .. " houseGUIDs")
        end

        C_Housing.VisitHouse(h.neighborhoodGUID, attempts[attemptIndex], h.plotID)
        attemptIndex = attemptIndex + 1
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
