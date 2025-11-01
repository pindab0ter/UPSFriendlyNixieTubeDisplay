local nixie_tube_gui = require("scripts.nixie_tube_gui")
local helpers = require("scripts.helpers")

--- @class NixieTubeController The aspect of a Nixie Tube responsible for controlling a series of Nixie Tubes. Always
---   the most eastern Nixie Tube (least significant digit) in a series of Nixie Tubes
--- @field entity LuaEntity
--- @field control_behavior LuaLampControlBehavior?
--- @field previous_signal SignalID?
--- @field previous_value int?

--- @class NixieTubeDisplay The aspect of a Nixie Tube responsible for displaying one or two digits
--- @field entity LuaEntity
--- @field arithmetic_combinators table<uint, LuaEntity>
--- @field control_behaviors table<uint, LuaAccumulatorControlBehavior>
--- @field next_display uint?
--- @field remaining_value string?

storage = {
    --- @type table<uint, NixieTubeController> The 'controllers' are the rightmost Nixie tubes in a series of Nixie
    ---     tubes, which are responsible for updating the entire series
    controllers = {},

    --- @type uint? The unit number of the next controller, so we can continue iterating where we left off if the amount
    ---     of controllers is larger than the update speed
    next_controller_unit_number = nil,

    --- @type table<uint, NixieTubeDisplay> The displays are the individual Nixie tubes in a series of Nixie tubes. A Nixie Tube can be a display and a controller at the same time
    displays = {},

    --- @type table<uint, NixieTubeGui>
    gui = {},

    --- @type number
    controller_updates_per_tick = tonumber(settings.global["nixie-tube-group-updates-per-tick"].value) or
        error("nixie-tube-group-updates-per-tick not set"),

    --- @type table<uint, boolean>
    invalidated_this_tick = {}
}

local digit_counts = {
    ['classic-nixie-tube'] = 1,
    ['reinforced-nixie-tube'] = 1,
    ['small-reinforced-nixie-tube'] = 2
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


------------------------
-- Nixie Tube updates --
------------------------


--- Set the digit(s) and update the sprite for a nixie tube
--- @param display NixieTubeDisplay
--- @param values table<string, string>
local function set_arithmetic_combinators(display, values)
    for key, value in pairs(values) do
        --- @type LuaEntity?
        local arithmetic_combinator = display.arithmetic_combinators[key]

        if value == "off" then
            if arithmetic_combinator and arithmetic_combinator.valid then
                arithmetic_combinator.destroy()
            end
            display.arithmetic_combinators[key] = nil
            goto continue
        end

        if not (arithmetic_combinator and arithmetic_combinator.valid) then
            local position = display.entity.position

            -- Small Nixie Tube Display
            if #values == 2 then
                if key == 2 then
                    position.x = position.x + 12 / 32
                end
            end

            arithmetic_combinator = display.entity.surface.create_entity {
                name = display.entity.name .. "-sprite",
                position = position,
                force = display.entity.force,
            }

            if not arithmetic_combinator then
                error("Failed to create arithmetic combinator for Nixie Tube")
            end

            display.arithmetic_combinators[key] = arithmetic_combinator
        end

        local control_behavior = display.control_behaviors[key]
        if not (control_behavior and control_behavior.valid) then
            control_behavior = arithmetic_combinator.get_or_create_control_behavior() or
                error('Failed to get control behavior') --[[@as LuaAccumulatorControlBehavior]]
            display.control_behaviors[key] = control_behavior
        end
        local parameters = control_behavior.parameters
        parameters.operation = state_display[value]
        control_behavior.parameters = parameters

        ::continue::
    end
end

--- Display the characters on this and adjacent Nixie Tubes
--- @param display NixieTubeDisplay
--- @param characters string
local function display_characters(display, characters)
    if not (display and display.entity and display.entity.valid) then
        return
    end

    local digit_count = digit_counts[display.entity.name]

    if characters == "off" then
        -- Set this display to 'off'
        set_arithmetic_combinators(display, (digit_count == 1) and { "off" } or { "off", "off" })
    elseif #characters < digit_count then
        -- Display the last digit
        set_arithmetic_combinators(display, { "off", characters:sub(-1) })
    elseif #characters >= digit_count then
        -- Display the rightmost `sprite_count` digits
        set_arithmetic_combinators(
            display,
            (digit_count == 1) and { characters:sub(-1) } or { characters:sub(-2, -2), characters:sub(-1) }
        )
    end

    -- Draw remainder on the next display
    if display.next_display then
        local next_display = storage.displays[display.next_display]

        if not (next_display and next_display.entity and next_display.entity.valid) then
            return
        end

        local remaining_value
        if #characters <= digit_count or characters == "off" then
            remaining_value = "off"
        else
            remaining_value = characters:sub(1, -(digit_count + 1))
        end

        if next_display.remaining_value == remaining_value then
            return
        else
            next_display.remaining_value = remaining_value
        end

        display_characters(next_display, remaining_value)
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

    local control_behavior = controller.control_behavior
    if not control_behavior then
        control_behavior = controller.entity.get_or_create_control_behavior() or
            error('Failed to get control behavior') --[[@as LuaLampControlBehavior]]
    end

    local selected_signal = control_behavior
        .circuit_condition --[[@as CircuitCondition]]
        .first_signal

    if controller.previous_signal ~= selected_signal then
        controller.previous_signal = selected_signal
        controller.previous_value = nil
    end

    local has_enough_energy = display.entity.energy > 0

    if not selected_signal or not has_enough_energy then
        display_characters(display, "off")
        return
    end

    local signal_value = controller.entity.get_signal(
        selected_signal,
        defines.wire_connector_id.circuit_red,
        defines.wire_connector_id.circuit_green
    )

    if controller.previous_value == signal_value then
        return
    else
        controller.previous_value = signal_value
    end

    display_characters(display, ("%i"):format(signal_value))
end


------------------------------
-- Nixie Tube configuration --
------------------------------


--- Invalidate the remaining characters cache, causing the value(s) to be redrawn
--- @param display NixieTubeDisplay
--- @param direction "east"|"west"
local function invalidate_cache(display, direction)
    -- Validate that display and its entity exist and are valid
    if not display or not display.entity or not display.entity.valid then
        return
    end

    if storage.invalidated_this_tick[display.entity.unit_number] then
        return
    end

    display.remaining_value = nil
    storage.invalidated_this_tick[display.entity.unit_number] = true

    if direction == "west" and display.next_display then
        local next_display = storage.displays[display.next_display]
        if next_display then
            invalidate_cache(next_display, direction)
        end
    elseif direction == "east" then
        for _, other_display in pairs(storage.displays) do
            if other_display.next_display == display.entity.unit_number then
                invalidate_cache(other_display, direction)
            end
        end
    end
end

--- @param nixie_tube LuaEntity
--- @param invalidate_caches boolean?
local function configure_nixie_tube(nixie_tube, invalidate_caches)
    -- Set up the Nixie Tube and its display
    nixie_tube.always_on = true

    local digit_count = digit_counts[nixie_tube.name]

    if not digit_count then
        return
    end

    helpers.storage_set_display(nixie_tube)

    -- Process the Nixie Tube to the west, if there is one
    local western_neighbors = nixie_tube.surface.find_entities_filtered {
        position = { x = nixie_tube.position.x - 1, y = nixie_tube.position.y },
        name = nixie_tube.name,
    }

    for _, neighbor in pairs(western_neighbors) do
        if neighbor.valid then
            if storage.next_controller_unit_number == neighbor.unit_number then
                -- If it's currently the next controller, clear it
                storage.next_controller_unit_number = nil
            end

            local neighbor_control_behavior = neighbor.get_control_behavior() --[[@as LuaLampControlBehavior?]]
            if neighbor_control_behavior then
                neighbor_control_behavior.circuit_condition = nil
            end

            storage.controllers[neighbor.unit_number] = nil
            
            -- Ensure the western neighbor's display is properly set up
            local western_neighbor_display = helpers.storage_set_display(neighbor)
            
            -- Set the current nixie_tube's display to point to the western neighbor
            helpers.storage_set_display(nixie_tube, {
                next_display = neighbor.unit_number
            })

            if invalidate_caches ~= false then
                invalidate_cache(western_neighbor_display, "west")
            end
        end
    end

    -- Process the Nixie Tube to the east.
    local eastern_neighbors = nixie_tube.surface.find_entities_filtered {
        position = { x = nixie_tube.position.x + 1, y = nixie_tube.position.y },
        name = nixie_tube.name,
    }

    local has_eastern_neighbor = false
    for _, neighbor in pairs(eastern_neighbors) do
        if neighbor.valid then
            has_eastern_neighbor = true
            
            -- If the eastern neighbor was a controller, it should no longer be one
            -- since we're placing a tube to its west (making it not the rightmost anymore)
            if storage.controllers[neighbor.unit_number] then
                if storage.next_controller_unit_number == neighbor.unit_number then
                    storage.next_controller_unit_number = nil
                end
                
                local neighbor_control_behavior = neighbor.get_control_behavior() --[[@as LuaLampControlBehavior?]]
                if neighbor_control_behavior then
                    neighbor_control_behavior.circuit_condition = nil
                end
                
                storage.controllers[neighbor.unit_number] = nil
            end
            
            local neighbor_display = helpers.storage_set_display(neighbor, {
                next_display = nixie_tube.unit_number,
            })

            if invalidate_caches ~= false then
                invalidate_cache(neighbor_display, "east")
            end
        end
    end

    -- If there is no eastern neighbor, set this as a controller
    if not has_eastern_neighbor then
        helpers.storage_set_controller(nixie_tube)
    end
end

--- Clears the storage, removes all Nixie Tubes and arithmetic combinators, and adds them back in
local function reconfigure_nixie_tubes()
    storage.controllers = {}
    storage.next_controller_unit_number = nil
    storage.displays = {}
    storage.gui = {}
    storage.invalidated_this_tick = {}

    for _, surface in pairs(game.surfaces) do
        local arithmetic_combinators = surface.find_entities_filtered {
            name = {
                "classic-nixie-tube-sprite",
                "reinforced-nixie-tube-sprite",
                "small-reinforced-nixie-tube-sprite"
            },
        }

        for _, arithmetic_combinator in pairs(arithmetic_combinators) do
            if arithmetic_combinator.valid then
                arithmetic_combinator.destroy()
            end
        end

        local nixie_tubes = surface.find_entities_filtered {
            name = {
                "classic-nixie-tube",
                "reinforced-nixie-tube",
                "small-reinforced-nixie-tube"
            }
        }

        for _, entity in pairs(nixie_tubes) do
            configure_nixie_tube(entity, false);
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


--- @param _ EventData.on_tick
local function on_tick(_)
    storage.invalidated_this_tick = {}

    -- There are no controllers to update
    if next(storage.controllers) == nil then
        return
    end

    local first_unit_number_this_tick = storage.next_controller_unit_number

    -- Determine which surfaces have players that can see the Nixie Tubes
    local eyes_on_surface = {}
    for i = 1, #game.connected_players do
        local player = game.connected_players[i]
        if player.render_mode == defines.render_mode.game or player.render_mode == defines.render_mode.chart_zoomed_in then
            eyes_on_surface[player.surface_index] = (eyes_on_surface[player.surface_index] or 0) + 1
        end
    end

    --- @type NixieTubeController?
    local controller
    local i = 1

    while i <= storage.controller_updates_per_tick do
        -- If we've looped back to the first controller which was processed this tick, stop
        if storage.next_controller_unit_number ~= nil and storage.next_controller_unit_number == first_unit_number_this_tick and i ~= 1 then
            break
        end

        storage.next_controller_unit_number, controller = next(storage.controllers, storage.next_controller_unit_number)

        -- Wrap around to the start if we've reached the end
        if controller == nil then
            storage.next_controller_unit_number, controller = next(storage.controllers)
        end

        if not controller.entity.valid then
            reconfigure_nixie_tubes()
            break
        end

        -- If no player is abl see Nixie Tubes on this surface, skip the update
        if eyes_on_surface[controller.entity.surface_index] then
            update_controller(controller)
        end

        i = i + 1
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

--- @param event EventData.on_entity_died|EventData.on_player_mined_entity|EventData.on_robot_mined_entity|EventData.script_raised_destroy
local function on_object_destroyed(event)
    local entity = event.entity
    if not entity or not entity.valid or not helpers.is_nixie_tube(entity) then
        return
    end

    nixie_tube_gui.destroy_all_guis()

    destroy_arithmetic_combinators(entity)

    -- Check if the destroyed entity was a controller
    local was_controller = storage.controllers[entity.unit_number] ~= nil
    local old_controller_settings = nil
    
    if was_controller then
        -- Save the controller's circuit condition before removing it
        local control_behavior = entity.get_control_behavior() --[[@as LuaLampControlBehavior?]]
        if control_behavior and control_behavior.circuit_condition then
            old_controller_settings = control_behavior.circuit_condition
        end
    end

    -- Promote the next display (to the west) to a controller if there is one
    local display = storage.displays[entity.unit_number]

    if display and display.next_display then
        local next_display = storage.displays[display.next_display]

        if next_display and next_display.entity and next_display.entity.valid then
            local controller = helpers.storage_set_controller(next_display.entity)
            
            -- If the destroyed entity was a controller, transfer its settings to the new controller
            if was_controller and old_controller_settings then
                local new_control_behavior = next_display.entity.get_or_create_control_behavior() --[[@as LuaLampControlBehavior?]]
                if new_control_behavior then
                    new_control_behavior.circuit_condition = old_controller_settings
                    -- Reset the cached values so the controller will re-evaluate on next update
                    controller.previous_signal = nil
                    controller.previous_value = nil
                end
            end
            
            storage.next_controller_unit_number = controller.entity.unit_number
            update_controller(controller)
        else
            storage.next_controller_unit_number = nil
        end
    else
        storage.next_controller_unit_number = nil
    end

    storage.displays[entity.unit_number] = nil
    storage.controllers[entity.unit_number] = nil
end

--- @param event EventData.on_script_trigger_effect
local function on_script_trigger_effect(event)
    if event.effect_id ~= "nixie-tube-created" then
        return
    end

    local nixie_tube = event.cause_entity
    if not nixie_tube then
        return
    end

    -- Set up the Nixie Tube and its display
    nixie_tube.always_on = true

    local control_behavior = nixie_tube.get_or_create_control_behavior() --[[@as LuaLampControlBehavior?]]
    if control_behavior then
        control_behavior.circuit_enable_disable = true
    end

    configure_nixie_tube(nixie_tube)
end

--- @param event EventData.on_runtime_mod_setting_changed
local function on_runtime_mod_setting_changed(event)
    if event.setting == "nixie-tube-group-updates-per-tick" then
        storage.controller_updates_per_tick = tonumber(settings.global["nixie-tube-group-updates-per-tick"].value)
    end
end

script.on_configuration_changed(function ()
    storage.controller_updates_per_tick = tonumber(settings.global["nixie-tube-group-updates-per-tick"].value)

    reconfigure_nixie_tubes()
end)

script.on_init(function ()
    storage.controllers = {}
    storage.next_controller_unit_number = nil
    storage.displays = {}
    storage.gui = {}

    script.on_event(defines.events.on_tick, on_tick)
    script.on_event(defines.events.on_script_trigger_effect, on_script_trigger_effect)
    script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
    script.on_event(defines.events.on_gui_opened, nixie_tube_gui.on_gui_opened)

    script.on_event(defines.events.on_entity_died, on_object_destroyed)
    script.on_event(defines.events.on_player_mined_entity, on_object_destroyed)
    script.on_event(defines.events.on_robot_mined_entity, on_object_destroyed)
    script.on_event(defines.events.script_raised_destroy, on_object_destroyed)
end)

nixie_tube_gui.callbacks.on_nt_gui_elem_changed = function (self, event)
    local nixie_tube = self.entity
    local signal = event.element.elem_value --[[@as SignalID]]
    local behavior = nixie_tube.get_or_create_control_behavior() or
        error('Failed to get control behavior') --[[@as LuaLampControlBehavior]]

    -- See https://lua-api.factorio.com/stable/concepts/CircuitConditionDefinition.html
    ---@diagnostic disable-next-line: missing-fields
    behavior.circuit_condition = {
        comparator = "=",
        first_signal = signal,
        second_signal = signal,
    }

    local controller = helpers.storage_set_controller(nixie_tube)

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
        [defines.events.on_robot_mined_entity] = on_object_destroyed,
        [defines.events.on_space_platform_mined_entity] = on_object_destroyed,
        [defines.events.script_raised_destroy] = on_object_destroyed,
    }
}

return nixie_tube
