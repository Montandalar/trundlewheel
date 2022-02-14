local DEBUG = false

local prevpos = nil
local currpos = nil

local vertical = true
local rotationdist = nil
local totaldist = 0
local grandtotaldist = 0
local paused = false

local sumdtime = 0

local modstorage

local function getbool(storage, key, s_default)
    local val = storage:get(tostring(key))
    if val == nil then
        return s_default
    else
        return (val == "true" and true) or false
    end
end

function loadstorage()
    modstorage = minetest.get_mod_storage()

    rotationdist = tonumber(modstorage:get("rotationdist")) or 10
    grandtotaldist = tonumber(modstorage:get("grandtotaldist")) or 0
    totaldist = tonumber(modstorage:get("totaldist")) or 0

    vertical = getbool(modstorage, "vertical", "true") --modstorage:get("vertical")
    paused = getbool(modstorage, "paused", "false")
    --[[if vert ~= nil and vert == "false" then
        vertical = false
    else
        vertical = true
    end--]]

end
loadstorage()

local function show_wheel_info()
    minetest.display_chat_message("Trundlewheel is " .. ((paused and "paused" or "active")))
    minetest.display_chat_message("Each rotation: " .. rotationdist)
    minetest.display_chat_message(string.format(
                "Total distance this rotation: %.3f", totaldist))
    minetest.display_chat_message(string.format("Grand total distance: %.3f", grandtotaldist))
end

minetest.register_chatcommand("wheel_info", {
    params = "",
    description = "Print trundlewheel info",
    func = show_wheel_info
})

local function printconf()
    minetest.display_chat_message("Paused? " .. tostring(paused) .. " (paused)")
    minetest.display_chat_message("Vertical being counted? " .. tostring(vertical) .. " (vertical)")
    minetest.display_chat_message("Each rotation: " .. rotationdist .. " (rotationdist)")
end

local function setbool(settingname, param)
    newval = param:match("set%s+" ..settingname.."%s+(.+)")
    if newval then
        if newval == "true" or newval == "1" or newval == "on" then
            vertical = true
            modstorage:set_string(settingname, "true")
        elseif newval == "false" or newval == "0" or newval == "off" then
            vertical = false
            modstorage:set_string(settingname, "false")
        else
            minetest.display_chat_message(string.format(
                "'%s' setting must be one of 'true', '1', 'on', 'false', '0', or 'off'",
                settingname
            ))
        end
    end
end

minetest.register_chatcommand("wheel_conf", {
    params = "(set | get) ([] | rotationdist | vertical | paused)",
    description = "Configure your trundlewheel",
    func = function(param)
        if param:sub(1,3) == "get" then
            if param == "get" then
                printconf()
                return
            elseif param:sub(5) == "rotationdist" then
                minetest.display_chat_message("rotationdist = " .. rotationdist)
            elseif param:sub(5) == "vertical" then
                minetest.display_chat_message("vertical = " .. tostring(vertical))
            elseif param:sub(5) == "paused" then
                minetest.display_chat_message("paused = " .. tostring(vertical))
            else
                minetest.display_chat_message("No such configuration option / bad syntax")
            end
        elseif param:sub(1,3) == "set" then
            local newval
            newval = param:match("set%s+rotationdist%s+(.+)")
            if newval then
                newval = tonumber(newval)
                if newval == nil then
                    minetest.display_chat_message("Invalid number")
                elseif newval <= 0 then
                    minetest.display_chat_message("Rotation distance must be greater than zero")
                else
                    rotationdist = newval
                    modstorage:set_float("rotationdist", tonumber(param:sub(17)))
                end
                return
            end

            newval = param:match("set%s+vertical%s+(.+)")
            if newval then
                setbool("vertical", param)
                vertical = getbool(modstorage, "vertical", "true")
                return
            end

            newval = param:match("set%s+paused%s+(.+)")
            if newval then
                setbool("paused", param)
                paused = getbool(modstorage, "paused", "false")
                currpos = nil
                prevpos = nil
                return
            end

            -- else no matches
            minetest.display_chat_message("Set what? / No such configuration option")
        elseif param == "" then
            printconf()
        else
            minetest.display_chat_message(".wheel_conf (set | get) ([] | rotationdist | vertical)")
        end
    end
})

minetest.register_chatcommand("wheel_reset", {
    params = "[<val>] [grand]",
    description = "Set/reset your trundlewheel's current or grand total distance. val must be greater than or equal to 0.",
    func = function(param)
        if param:find("grand") ~= nil then
            local n = tonumber(param:match("(%d+)%s+grand"))
            if n ~= nil then
                grandtotaldist = n
                return
            end

            local n = tonumber(param:match("grand%s+(%d+)"))
            if n ~= nil then
                grandtotaldist = n
                return
            end

            -- else
            grandtotaldist = 0
        else
            local n = tonumber(param)
            if n ~= nil and n >= 0 then
                if n >= 0 and n < rotationdist then
                    totaldist = n
                else
                    minetest.display_chat_message("The wheel can't be set at or higher than it's rotation distance")
                    return true
                end
                totaldist = n
            else
                totaldist = 0
            end
        end
    end
})

minetest.register_chatcommand("wheels", {
    params = "",
    description = "List all your saved trundlewheels",
    func = function(param)
        local wheels = minetest.deserialize(
                modstorage:get("saved_wheels")) or {}
        for k, _ in pairs(wheels) do
            if k == "" then k = '<trundle wheel with no name>' end
            minetest.display_chat_message(k)
        end
    end
})

minetest.register_chatcommand("wheel_delete", {
    params = "",
    description = "Delete a named wheel",
    func = function(param)
        local wheels = minetest.deserialize(
                modstorage:get("saved_wheels")) or {}
        wheels[param] = nil
        local anykeys = false
        for k,v in pairs(wheels) do
            anykeys = true
            break
        end
        if anykeys then
            modstorage:set_string("saved_wheels", minetest.serialize(wheels))
        else
            modstorage:set_string("saved_wheels", nil)
        end
    end
})

minetest.register_chatcommand("wheel_save", {
    params = "wheel",
    description = "Save your wheel info to storage for later resumption: rotation distance, total distance, grand total distance and paused status.",
    func = function(param)
        local wheels = minetest.deserialize(
                modstorage:get("saved_wheels")) or {}
        local current_wheel = {
            rotationdist = rotationdist,
            totaldist = totaldist,
            grandtotaldist = grandtotaldist,
            paused = paused,
        }
        wheels[param] = current_wheel

        modstorage:set_string("saved_wheels", minetest.serialize(wheels))
    end
})

minetest.register_chatcommand("wheel_load", {
    params = "wheel",
    description = "Load a previously saved wheel from storage",
    func = function(param)
        local wheels = minetest.deserialize(
                modstorage:get("saved_wheels")) or {}
        if wheels[param] == nil then
            minetest.display_chat_message("No such wheel! For a list use .wheels")
            return
        end
        rotationdist = wheels[param].rotationdist
        totaldist = wheels[param].totaldist
        grandtotaldist = wheels[param].totaldist
        paused = wheels[param].paused
        show_wheel_info()
    end
})

function deltadist(prevpos, currpos)
    if not vertical then
        prevpos.y = 0
        currpos.y = 0
    end
    return vector.distance(prevpos, currpos)
end

-- Counting, clicking and resetting
minetest.register_globalstep(function(dtime)
    if paused then return end

    sumdtime = sumdtime + dtime
    if sumdtime < 0.05 then 
        return
    else
        sumdtime = 0
    end
    prevpos = currpos or minetest.localplayer:get_pos()
    currpos = minetest.localplayer:get_pos()

    local deltapos = deltadist(prevpos, currpos)
    totaldist = totaldist + deltapos
    grandtotaldist = grandtotaldist + deltapos
    if DEBUG then
        minetest.display_chat_message("dtime = " .. tonumber(dtime))
        minetest.display_chat_message("deltapos = " .. tonumber(deltapos))
        minetest.display_chat_message("totaldist = " .. tonumber(totaldist))
    end

    if (totaldist >= rotationdist) then
        minetest.display_chat_message("Click.")
        minetest.sound_play("trundlewheel_click", {gain = 1.0, loop = false}, true)
        totaldist = totaldist - rotationdist
    end

end)

minetest.register_on_shutdown(function()
    modstorage:set_string("vertical", tostring(vertical))

    modstorage:set_float("rotationdist", rotationdist)
    modstorage:set_float("grandtotaldist", grandtotaldist)
    modstorage:set_float("totaldist", totaldist)
end)
