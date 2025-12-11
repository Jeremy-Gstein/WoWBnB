-- SavedVariables
WoWBnB_HousesDB = WoWBnB_HousesDB or { houses = {} }

-- Add a house
function WoWBnB_AddHouse(owner, neighborhood, neighborhoodGUID, houseGUID, plotID)
    if not owner or not neighborhood or not neighborhoodGUID or not houseGUID or not plotID then
        print("WoWBnB: Cannot save house, missing data.")
        return false
    end

    for _, h in ipairs(WoWBnB_HousesDB.houses) do
        if h.owner == owner and h.neighborhood == neighborhood and h.houseGUID == houseGUID then
            print("House already saved: " .. neighborhood .. " - " .. owner)
            return false
        end
    end

    print("owner:" .. owner .. "   hoodName:" .. neighborhood .. "   hoodId:" .. neighborhoodGUID .. "   house:" .. houseGUID .. "   plot:" .. plotID)
    table.insert(WoWBnB_HousesDB.houses, {
        owner = owner,
        neighborhood = neighborhood,
        neighborhoodGUID = neighborhoodGUID,
        houseGUID = houseGUID,
        plotID = plotID,
    })
    print("Saved house: " .. neighborhood .. " - " .. owner)

    if WoWBnB_RefreshUIList then
        WoWBnB_RefreshUIList()
    end

    return true
end


-- Run saved house
function WoWBnB_RunHouseCommand(index)
    local h = WoWBnB_HousesDB.houses[index]
    if not h or not (h.neighborhoodGUID and h.houseGUID and h.plotID) then
        print("WoWBnB: House info incomplete.")
        return
    end
    C_Housing.VisitHouse(h.neighborhoodGUID, h.houseGUID, h.plotID)
end

-- Export
function WoWBnB_ExportHouses()
    local t = {}
    for _, h in ipairs(WoWBnB_HousesDB.houses) do
        table.insert(t, h.neighborhood .. "|" .. h.owner .. "|" .. h.neighborhoodGUID .. "|" .. h.houseGUID .. "|" .. h.plotID)
    end
    return table.concat(t, "\n")
end

-- Import
function WoWBnB_ImportHouses(text)
    for line in string.gmatch(text, "[^\n]+") do
        local n, o, ng, hg, p = strsplit("|", line)
        if n and o and ng and hg and p then
            WoWBnB_AddHouse(o, n, ng, hg, tonumber(p))
        end
    end
end

-- Save current house
function WoWBnB_SaveCurrentHouse()
    local houseInfo = C_Housing.GetCurrentHouseInfo()
    if not houseInfo then
        print("You must be standing on a house plot to save it.")
        return
    end
    local owner = houseInfo.ownerName or "Unknown"
    local neighborhood = houseInfo.neighborhoodName or "Unknown"
    local neighborhoodGUID = houseInfo.neighborhoodGUID
    local houseGUID = houseInfo.houseGUID
    local plotID = houseInfo.plotID

    WoWBnB_AddHouse(owner, neighborhood, neighborhoodGUID, houseGUID, plotID)
end
