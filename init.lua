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

local function string2bool(s)
    if s == nil then return nil end

    if s == "true" or newval == "1" or newval == "on" then
        return true
    elseif newval == "false" or newval == "0" or newval == "off" then
        return false
    else return nil end
end

local function confcmd_getbool(settingname, param)
    newval = param:match("set%s+" ..settingname.."%s+(.+)")
    if newval then
        if newval == "true" or newval == "1" or newval == "on" then
            return true
        elseif newval == "false" or newval == "0" or newval == "off" then
            return false
        else
            minetest.display_chat_message(string.format(
                "'%s' setting must be one of 'true', '1', 'on', 'false', '0', or 'off'",
                settingname
            ))
            return nil
        end
    end
end

local function set_vertical(newstate)
    vertical = newstate
    modstorage:set_string("vertical", tostring(newstate))
    vertical = getbool(modstorage, "vertical", "true")
    return
end

local function set_paused(newstate)
    paused = newstate
    modstorage:set_string("paused", tostring(newstate))
    paused = getbool(modstorage, "paused", "false")
    currpos = nil
    prevpos = nil
    return
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
                newval = confcmd_getbool("vertical", param)
                if newval ~= nil then 
                    set_vertical(newval)
                return end
            end

            newval = param:match("set%s+paused%s+(.+)")
            if newval then
                newval = confcmd_getbool("paused", param)
                if newval ~= nil then 
                    set_paused(newval)
                return end
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

local function wheel_save(param)
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

minetest.register_chatcommand("wheel_save", {
    params = "wheel",
    description = "Save your wheel info to storage for later resumption: rotation distance, total distance, grand total distance and paused status.",
    func = function(param)
        wheel_save(param)
        minetest.display_chat_message("Saved trundle wheel!")
    end,
})

local function wheel_load(param)
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
end

minetest.register_chatcommand("wheel_load", {
    params = "wheel",
    description = "Load a previously saved wheel from storage",
    func = function(param)
        wheel_load(param)
        show_wheel_info()
    end
})

local function wheel_list_formspec_get()
    local wheels = minetest.deserialize(
            modstorage:get("saved_wheels")) or {}

    local result = ""
    for k,_ in pairs(wheels) do
        local key = k
        if key == "" then key = '<trundle wheel with no name>' end
        key = minetest.formspec_escape(key)
        result = result .. key .. ","
    end
    
    -- trim trailing ','
    return result:sub(1,-2)
end

local formspectext = [=[
formspec_version[5]
size[13,11]
button_exit[12.2,0.1;0.7,0.7;exeunt;x]
label[1,0.4;Wheel statistics and configuration]
field[1,1.2;3.5,0.8;rotationdist;Nodes per rotation;%f]
tooltip[rotationdist;The trundle wheel will click every time you travel
this many nodes. Must be > 0.]
field[1,2.7;3.5,0.8;totaldist;Distance this rotation;%f]
tooltip[totaldist;The distance that the trundle wheel has gone so far this 
rotation - you can (re)set it yourself. Must be >= 0]
field[1,4.2;3.5,0.8;grandtotaldist;Grand total;%f]
tooltip[grandtotaldist;The distance that the trundle wheel has gone across all
rotations - you can (re)set it yourself. Must be >= 0]
field_close_on_enter[totaldist;false]
field_close_on_enter[rotationdist;false]
field_close_on_enter[grandtotaldist;false]
checkbox[1,5.6;vertical;Counting vertical?;%s]
tooltip[vertical;Whether the tooltip counts your vertical
movement, or just horizontal]
checkbox[1,6.3;paused;Paused?;%s]
tooltip[paused;Whether your trundle wheel is paused. If it's paused, it will
stop counting distance until you unpause it.]
button[1,7;4,0.8;update;Update configuration]
label[6.4,0.4;Saved wheels]
field[6.4,1.2;4.2,0.8;wheel_name;Wheel name;]
tooltip[wheel_name;This is the name you will save your wheel to, which may
override other existing wheels.]
field_close_on_enter[wheel_name;false]
textlist[6.4,2.2;5,4;wheel_list;%s;1;false]
button[6.4,6.5;4,0.8;save;Save current wheel]
tooltip[save;Save the current wheel with the above specified name. Overwrite
any other wheel with that name.]
button[6.4,7.6;4,0.8;load;Load selected wheel]
tooltip[load;Load the selected wheel from the list,
overwriting your current wheel]
button[6.4,8.7;4,0.8;delete;Delete selected wheel]
tooltip[delete;Delete the selected wheel from the list. Be careful!]
label[1,9.8;Loading will overwrite your current wheel!]
label[1,10.3;Save your wheel before loading unless you want to discard it.]
]=]

minetest.register_chatcommand("wheel_gui", {
    params = "",
    description = "Open a GUI to configure your trundlewheel",
    func = function(param)
        local formspectext =
            string.format(formspectext,
                    rotationdist,
                    totaldist,
                    grandtotaldist,
                    tostring(vertical),
                    tostring(paused),
                    wheel_list_formspec_get()
            )
        minetest.show_formspec("trundlewheel:wheel_gui", formspectext)
    end
})


--[[
fields = {
    -- These 4 are guaranteed except for the esc key event
    totaldist = <float>,
    rotationdist = <float>,
    grandtotaldist = <float>,
    wheel_name = <string>,

    key_enter = "true",
    key_enter_field = <string fieldname>,
    quit = true | nil -- set true unless field_close_on_enter is false for that element
    exeunt = <string>? -- present when X button pressed

    -- Following are present if that button is pressed
    update = <const string label>
    save = <const string label>
    load = <const string label>

    wheel_list = "CHG:<idx>" | nil --set when the list was interacted with
}

-- Esc key
fields = {
    quit = "true"
}
--]]

--TODO: Select sets wheel_name
minetest.register_on_formspec_input(function(formname, fields)
    if formname ~= "trundlewheel:wheel_gui" then return end

    minetest.display_chat_message(dump(fields))

    -- Select
    if fields.wheel_list ~= nil then
        local evt = minetest.explode_table_event(fields.wheel_list)
        if evt.type ~= "CHG" then return end

        -- TODO: get list from storage, set wheel_name, (set selected index?)
        return
    end

    -- Enter keys
    local res
    if fields.key_enter ~= nil then
        if key_enter_field == "totaldist" then
            res = tonumber(fields.totaldist)
            if res and res > 0 and res < rotationdist then
                totaldist = res
            end
        elseif key_enter_field == "rotationdist" then
            res = tonumber(fields.rotationdist)
            if res and res >= 0 then rotationdist = res end
        elseif key_enter_field == "grandtotaldist" then
            res = tonumber(fields.grandtotaldist)
            if res and res >= 0 then grandtotaldist = res end
        end
        -- no handler for wheel_name as we don't want to be
        -- able to override saved wheels that easily
        return
    end

    -- Checkboxes
    if fields.vertical ~= nil then
        set_vertical(fields.vertical == "true")
        return
    elseif fields.paused ~= nil then
        set_paused(fields.paused == "true")
        return
    end

    -- Buttons
    if fields.update ~= nil then
        totaldist = fields.totaldist
        rotationdist = fields.rotationdist
        grandtotaldist = fields.grandtotaldist
        -- Vertical and paused: Already handled in their own events
        return
    elseif fields.save ~= nil then
        wheel_save(fields.wheel_name)
        return
    elseif fields.load ~= nil then
        wheel_load(fields.wheel_name)
        return
    end

    if fields.quit ~= "true" then
        minetest.display_chat_message("Unhandled input on trundlewheel GUI.")
    end

end)

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
