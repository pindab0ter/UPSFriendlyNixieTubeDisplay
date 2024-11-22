local nixie_tube_gui = require("scripts.nixie_tube_gui")
local util = require("scripts.util")

--- @class NixieTubeController The aspect of a Nixie Tube responsible for controlling a series of Nixie Tubes. Always
---   the most eastern Nixie Tube (least significant digit) in a series of Nixie Tubes
--- @field entity LuaEntity

--- @class NixieTubeDisplay The aspect of a Nixie Tube responsible for displaying one or two digits
--- @field entity LuaEntity
--- @field arithmetic_combinators table<uint, LuaEntity>
--- @field next_display LuaEntity
--- @field remaining_value string?

storage = {
    --- @type table<uint, NixieTubeController> The 'controllers' are the rightmost Nixie tubes in a series of Nixie
    ---     tubes, which are responsible for updating the entire series
    controllers = {},

    --- @type uint? The unit number of the next controller, so we can continue iterating where we left off if the amount
    ---     of controllers is larger than the update speed
    next_controller = nil,

    --- @type table<uint, NixieTubeDisplay> The displays are the individual Nixie tubes in a series of Nixie tubes. A Nixie Tube can be a display and a controller at the same time
    displays = {},

    --- @type table<uint, NixieTubeGui>
    gui = {},

    --- @type number
    update_delay = tonumber(settings.global["nixie-update-delay"].value) or error("nixie-update-delay not set"),

    --- @type number
    update_speed = tonumber(settings.global["nixie-tube-update-speed"].value) or error("nixie-tube-update-speed not set"),
}

local digit_counts = {
    ['SNTD-old-nixie-tube'] = 1,
    ['SNTD-nixie-tube'] = 1,
    ['SNTD-nixie-tube-small'] = 2
}

local state_display = {
    ["-"] = "-",
    ["0"] = "*",
    ["1"] = "+",
    ["2"] = "/",
    ["3"] = "%",
    ["4"] = "^",
    ["5"] = "<<",
    ["6"] = ">>",
    ["7"] = "AND",
    ["8"] = "OR",
    ["9"] = "XOR",
}

----------------------
-- Nixie Tube logic --
----------------------

--- Set the digit(s) and update the sprite for a nixie tube
--- @param display NixieTubeDisplay
--- @param values table<string, string>
local function set_arithmetic_combinators(display, values)
    for key, value in pairs(values) do
        --- @type LuaEntity?
        local arithmetic_combinator = display.arithmetic_combinators[key]

        local has_enough_energy = display.entity.energy >= 50 or script.level.is_simulation
        if not value or value == "off" or not has_enough_energy then
            if arithmetic_combinator and arithmetic_combinator.valid then
                arithmetic_combinator.destroy()
            end
            display.arithmetic_combinators[key] = nil
            return
        end

        if not (arithmetic_combinator and arithmetic_combinator.valid) then
            arithmetic_combinator = display.entity.surface.create_entity {
                name = display.entity.name .. "-sprite",
                position = display.entity.position,
                force = display.entity.force,
            }
            display.arithmetic_combinators[key] = arithmetic_combinator
        end

        local control_behavior = arithmetic_combinator.get_or_create_control_behavior()
        local parameters = control_behavior.parameters
        parameters.operation = state_display[value]
        control_behavior.parameters = parameters
    end
end

--- Display the value on this and adjacent Nixie tubes
--- @param display NixieTubeDisplay
--- @param value string
local function draw_value(display, value)
    if not (display and display.entity and display.entity.valid) then
        return
    end

    local sprite_count = digit_counts[display.entity.name]

    if value == "off" then
        -- Set this display to 'off'
        set_arithmetic_combinators(display, (sprite_count == 1) and { "off" } or { "off", "off" })
    elseif #value < sprite_count then
        -- Display the last digit
        set_arithmetic_combinators(display, { "off", value:sub(-1) })
    elseif #value >= sprite_count then
        -- Display the rightmost `sprite_count` digits
        set_arithmetic_combinators(
            display,
            (sprite_count == 1) and { value:sub(-1) } or { value:sub(-2, -2), value:sub(-1) }
        )
    end

    -- Draw remainder on the next display
    if display.next_display then
        local next_display = storage.displays[display.next_display]

        if not (next_display and next_display.entity and next_display.entity.valid) then
            return
        end

        local remaining_value
        if value == "off" then
            remaining_value = "off"
        else
            remaining_value = value:sub(1, -(sprite_count + 1))
            if remaining_value == "" then
                remaining_value = "off"
            end
        end


        if next_display.remaining_value == remaining_value then
            return
        else
            next_display.remaining_value = remaining_value
        end

        if remaining_value == "off" then
            draw_value(next_display, "off")
        else
            draw_value(next_display, remaining_value)
        end
    end
end

--- @param controller NixieTubeController
local function update_controller(controller)
    if not controller.entity.valid then
        return
    end

    local display = storage.displays[controller.entity.unit_number]
    if not (display and display.entity.valid) then
        return
    end

    local selected_signal = util.get_selected_signal(controller.entity)
    local has_enough_energy = display.entity.energy >= 50 or script.level.is_simulation

    if not selected_signal or not has_enough_energy then
        draw_value(display, "off")
        return
    end

    local signal_value = controller.entity.get_signal(
        selected_signal,
        defines.wire_connector_id.circuit_red,
        defines.wire_connector_id.circuit_green
    )

    draw_value(display, ("%i"):format(signal_value))
end

--- Invalidate the remaining value cache for this and all adjacent Nixie tubes to the east
--- @param display NixieTubeDisplay
function invalidate_remaining_value_cache(display)
    if not display then
        return
    end

    display.remaining_value = nil

    for _, other_display in pairs(storage.displays) do
        if other_display.next_display == display.entity.unit_number then
            invalidate_remaining_value_cache(other_display)
        end
    end
end

--- @param nixie_tube LuaEntity
local function configure_nixie_tube(nixie_tube)
    -- Set up the Nixie Tube and its display
    nixie_tube.always_on = true

    local digit_count = digit_counts[nixie_tube.name]

    if not digit_count then
        return
    end

    util.storage_set_display(nixie_tube)

    -- Process the Nixie Tube to the west, if there is one
    local western_neighbors = nixie_tube.surface.find_entities_filtered {
        position = { x = nixie_tube.position.x - 1, y = nixie_tube.position.y },
        name = nixie_tube.name,
    }

    for _, neighbor in pairs(western_neighbors) do
        if neighbor.valid then
            if storage.next_controller == neighbor.unit_number then
                -- If it's currently the next controller, claim that
                storage.next_controller = nixie_tube.unit_number
            end

            local neighbor_control_behavior = neighbor.get_control_behavior()
            if neighbor_control_behavior then
                neighbor_control_behavior.circuit_condition = nil
            end

            storage.controllers[neighbor.unit_number] = nil
            local neighbor_display = util.storage_set_display(nixie_tube, {
                next_display = neighbor.unit_number
            })

            draw_value(neighbor_display, "off")
        end
    end

    -- Process the Nixie Tube to the east.
    eastern_neighbors = nixie_tube.surface.find_entities_filtered {
        position = { x = nixie_tube.position.x + 1, y = nixie_tube.position.y },
        name = nixie_tube.name,
    }

    local has_eastern_neighbor = false
    for _, neighbor in pairs(eastern_neighbors) do
        if neighbor.valid then
            has_eastern_neighbor = true
            local neighbor_display = util.storage_set_display(neighbor, {
                next_display = nixie_tube.unit_number,
            })

            -- Otherwise the display will not render until the value of the display to the east changes
            invalidate_remaining_value_cache(neighbor_display)
        end
    end

    -- If there is no eastern neighbor, set this as a controller
    if not has_eastern_neighbor then
        local controller = util.storage_set_controller(nixie_tube)

        update_controller(controller)
    end
end

--- Clears the storage, removes all Nixie Tubes and arithmetic combinators, and adds them back in
local function reconfigure_nixie_tubes()
    storage.controllers = {}
    storage.next_controller = nil
    storage.displays = {}
    storage.gui = {}

    for _, surface in pairs(game.surfaces) do
        local arithmetic_combinators = surface.find_entities_filtered {
            name = {
                "SNTD-old-nixie-tube-sprite",
                "SNTD-nixie-tube-sprite",
                "SNTD-nixie-tube-small-sprite"
            },
        }

        for _, arithmetic_combinator in pairs(arithmetic_combinators) do
            if arithmetic_combinator.valid then
                arithmetic_combinator.destroy()
            end
        end

        local nixie_tubes = surface.find_entities_filtered {
            name = {
                "SNTD-old-nixie-tube",
                "SNTD-nixie-tube",
                "SNTD-nixie-tube-small"
            }
        }

        for _, entity in pairs(nixie_tubes) do
            configure_nixie_tube(entity);
        end
    end
end

--------------
-- Commands --
--------------

commands.add_command(
    "reconfigure-nixie-tubes",
    "Reconfigure all Nixie Tubes",
    function ()
        game.player.opened = nil
        reconfigure_nixie_tubes()
    end
)

-------------
-- Filters --
-------------

local filters = {}
filters[#filters + 1] = { filter = "name", name = "nixie_tube" }
filters[#filters + 1] = { filter = "ghost_name", name = "nixie_tube" }

--------------------
-- Event handlers --
--------------------

--- @param event EventData.on_tick
local function on_tick(event)
    if storage.update_delay ~= 0 and event.tick % storage.update_delay ~= 0 then
        -- Only update every `update_delay` ticks
        return
    end

    for _ = 1, storage.update_speed do
        local controller

        if storage.next_controller and not storage.controllers[storage.next_controller] then
            -- Calling `next()` with `nil` as the second argument will return the first element of the table
            storage.next_controller = nil
        end

        storage.next_controller, controller = next(storage.controllers, storage.next_controller)

        if not (controller and controller.entity and controller.entity.valid) then
            return
        end

        update_controller(controller)
    end
end

--- Destroy all arithmetic combinators associated with the Nixie Tube
--- @param nixie_tube LuaEntity
local function destroy_arithmetic_combinators(nixie_tube)
    local display = storage.displays[nixie_tube.unit_number]
    if display == nil then
        return
    end

    for key, arithmetic_combinator in pairs(display.arithmetic_combinators) do
        if arithmetic_combinator.valid then
            arithmetic_combinator.destroy()
        end
        display.arithmetic_combinators[key] = nil
    end
end

--- @param event EventData.on_object_destroyed
local function on_object_destroyed(event)
    local entity = event.entity
    if not entity or not entity.valid or not util.is_nixie_tube(entity) then
        return
    end

    nixie_tube_gui.destroy_all_guis()

    destroy_arithmetic_combinators(entity)

    -- Promote the next display (to the west) to a controller if there is one
    display = storage.displays[entity.unit_number]

    if display and display.next_display then
        local next_display = storage.displays[display.next_display]

        if next_display then
            local controller = util.storage_set_controller(next_display.entity)
            storage.next_controller = controller.entity.unit_number
            update_controller(controller)
        else
            storage.next_controller = nil
        end
    else
        storage.next_controller = nil
    end

    storage.displays[entity.unit_number] = nil
    storage.controllers[entity.unit_number] = nil
end

--- @param event EventData.on_script_trigger_effect
local function on_script_trigger_effect(event)
    if event.effect_id ~= "nixie-tube-created" then
        return
    end

    local entity = event.cause_entity
    if entity then
        configure_nixie_tube(entity)
    end
end

--- @param event EventData.on_runtime_mod_setting_changed
local function on_runtime_mod_setting_changed(event)
    if event.setting == "nixie-update-delay" then
        storage.update_delay = tonumber(settings.global["nixie-update-delay"].value)
    elseif event.setting == "nixie-tube-update-speed" then
        storage.update_speed = tonumber(settings.global["nixie-tube-update-speed"].value)
    end
end

script.on_configuration_changed(function ()
    reconfigure_nixie_tubes()
end)

script.on_init(function ()
    storage.controllers = {}
    storage.next_controller = nil
    storage.displays = {}

    storage.gui = {}
end)

nixie_tube_gui.callbacks.on_nt_gui_elem_changed = function (self, event)
    local nixie_tube = self.entity
    local signal = event.element.elem_value
    local behavior = nixie_tube.get_or_create_control_behavior()

    behavior.circuit_condition = {
        comparator = "=",
        first_signal = signal,
        second_signal = signal,
    }

    local display = storage.displays[nixie_tube.unit_number]
    local controller = util.storage_set_controller(nixie_tube)

    update_controller(controller)
end

local nixie_tube = {
    events = {
        [defines.events.on_tick] = on_tick,
        [defines.events.on_script_trigger_effect] = on_script_trigger_effect,
        [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
        [defines.events.on_gui_opened] = nixie_tube_gui.on_gui_opened,

        [defines.events.on_entity_died] = on_object_destroyed,
        [defines.events.on_player_mined_entity] = on_object_destroyed,
        [defines.events.on_pre_player_mined_item] = on_object_destroyed,
        [defines.events.on_robot_mined_entity] = on_object_destroyed,
        [defines.events.script_raised_destroy] = on_object_destroyed,
    }
}

return nixie_tube
