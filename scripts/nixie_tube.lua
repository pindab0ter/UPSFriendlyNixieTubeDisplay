local nixie_tube_gui = require("scripts.nixie_tube_gui")
local helpers = require("scripts.helpers")

--- @class NixieTubeController The aspect of a Nixie Tube responsible for controlling a series of Nixie Tubes. Always
---   the most eastern Nixie Tube (least significant digit) in a series of Nixie Tubes
--- @field entity LuaEntity
--- @field surface_index uint Cached so the per-surface index can be cleaned up after the entity is gone
--- @field selected_signal SignalID|false|nil Cached signal from the lamp's circuit condition. nil means unknown
---   (re-read on the next update), false means no signal is selected
--- @field previous_value int?
--- @field total_digits int? Cached total digit count for the display chain (for overflow detection)

--- @class NixieTubeDisplay The aspect of a Nixie Tube responsible for displaying one or two digits
--- @field entity LuaEntity
--- @field arithmetic_combinators table<uint, LuaEntity>
--- @field control_behaviors table<uint, LuaArithmeticCombinatorControlBehavior>
--- @field next_display uint? The unit number of the Nixie Tube to the west (the next more significant digits)
--- @field remaining_value string?

local digit_counts = helpers.digit_counts

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

            -- Stray area damage would otherwise pop the digit while the Nixie Tube itself survives
            arithmetic_combinator.destructible = false

            display.arithmetic_combinators[key] = arithmetic_combinator
        end

        local control_behavior = display.control_behaviors[key]
        if not (control_behavior and control_behavior.valid) then
            control_behavior = arithmetic_combinator.get_or_create_control_behavior() or
                error('Failed to get control behavior') --[[@as LuaArithmeticCombinatorControlBehavior]]
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
        set_arithmetic_combinators(display, (digit_count == 1) and { "off" } or { "off", "off" })
    else
        if #characters < digit_count then
            set_arithmetic_combinators(display, { "off", characters:sub(-1) })
        elseif #characters >= digit_count then
            set_arithmetic_combinators(
                display,
                (digit_count == 1) and { characters:sub(-1) } or { characters:sub(-2, -2), characters:sub(-1) }
            )
        end
    end

    if display.next_display then
        local next_display = storage.displays[display.next_display]
        if not (next_display and next_display.entity.valid) then return end

        local remaining_value = (#characters <= digit_count or characters == "off") and "off"
            or characters:sub(1, -(digit_count + 1))

        if next_display.remaining_value ~= remaining_value then
            next_display.remaining_value = remaining_value
            display_characters(next_display, remaining_value)
        end
    end
end

--- Cache the signal from the lamp's circuit condition, so it doesn't have to be read every update
--- @param controller NixieTubeController
local function refresh_selected_signal(controller)
    local control_behavior = controller.entity.get_control_behavior() --[[@as LuaLampControlBehavior?]]
    local circuit_condition = control_behavior and control_behavior.circuit_condition
    controller.selected_signal = circuit_condition and circuit_condition.first_signal or false
    controller.previous_value = nil
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

    local selected_signal = controller.selected_signal
    if selected_signal == nil then
        refresh_selected_signal(controller)
        selected_signal = controller.selected_signal
    end

    local has_enough_energy = display.entity.energy > 0

    if not selected_signal or not has_enough_energy then
        -- Forget the last value so the display is redrawn when it comes back on
        controller.previous_value = nil
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

    local value_str = ("%i"):format(signal_value)

    -- Check for overflow if the setting is enabled
    if storage.use_overflow_notation then
        -- Calculate total digits available in the display chain (cached on controller)
        if not controller.total_digits then
            local total_digits = 0
            local current_display = display
            while current_display do
                total_digits = total_digits + digit_counts[current_display.entity.name]
                current_display = current_display.next_display and storage.displays[current_display.next_display]
            end
            controller.total_digits = total_digits
        end

        -- If the value is too large, replace with the largest value that fits
        if #value_str > controller.total_digits then
            if signal_value < 0 then
                -- The minus sign occupies a digit slot; a single tube shows just "-"
                value_str = "-" .. string.rep("9", controller.total_digits - 1)
            else
                value_str = string.rep("9", controller.total_digits)
            end
        end
    end

    display_characters(display, value_str)
end


------------------------------
-- Nixie Tube configuration --
------------------------------


--- Invalidate the remaining characters cache, causing the value(s) to be redrawn
--- @param display NixieTubeDisplay
--- @param direction "east"|"west"
local function invalidate_cache(display, direction)
    if not display or not display.entity.valid or storage.invalidated_this_tick[display.entity.unit_number] then
        return
    end

    display.remaining_value = nil
    storage.invalidated_this_tick[display.entity.unit_number] = true

    if direction == "west" and display.next_display then
        invalidate_cache(storage.displays[display.next_display], direction)
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
    local digit_count = digit_counts[nixie_tube.name]

    if not digit_count then
        return
    end

    -- So that on_object_destroyed is raised however the Nixie Tube is removed
    script.register_on_object_destroyed(nixie_tube)

    helpers.storage_set_display(nixie_tube)

    -- Process the Nixie Tube to the west, if there is one
    local western_neighbors = nixie_tube.surface.find_entities_filtered {
        position = { x = nixie_tube.position.x - 1, y = nixie_tube.position.y },
        name = nixie_tube.name,
    }

    for _, neighbor in pairs(western_neighbors) do
        if neighbor.valid then
            local neighbor_control_behavior = neighbor.get_control_behavior() --[[@as LuaLampControlBehavior?]]
            if neighbor_control_behavior then
                neighbor_control_behavior.circuit_condition = nil
            end

            helpers.remove_controller(neighbor.unit_number)

            local own_display = helpers.storage_set_display(nixie_tube, {
                next_display = neighbor.unit_number
            })

            if invalidate_caches ~= false then
                invalidate_cache(own_display, "west")
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

    -- Invalidate controller caches since the chain structure may have changed
    helpers.invalidate_all_controller_caches()
end

--- Clears the storage, removes all Nixie Tubes and arithmetic combinators, and adds them back in
local function reconfigure_nixie_tubes()
    nixie_tube_gui.destroy_all_guis()

    storage.controllers = {}
    storage.controllers_by_surface = {}
    storage.next_controller_by_surface = {}
    storage.displays = {}
    storage.invalidated_this_tick = {}

    for _, surface in pairs(game.surfaces) do
        local arithmetic_combinators = surface.find_entities_filtered {
            name = helpers.sprite_names,
        }

        for _, arithmetic_combinator in pairs(arithmetic_combinators) do
            if arithmetic_combinator.valid then
                arithmetic_combinator.destroy()
            end
        end

        local nixie_tubes = surface.find_entities_filtered {
            name = helpers.entity_names,
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
        reconfigure_nixie_tubes()
    end
)


--------------------
-- Event handlers --
--------------------


--- Destroy all arithmetic combinators associated with the Nixie Tube
--- @param unit_number uint
local function destroy_arithmetic_combinators(unit_number)
    local display = storage.displays[unit_number]
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

--- Clean up after a Nixie Tube was removed by any means (mined, died, script, surface deletion)
--- @param unit_number uint?
local function clean_up_nixie_tube(unit_number)
    if not unit_number then
        return
    end

    local display = storage.displays[unit_number]
    if not display and not storage.controllers[unit_number] then
        return
    end

    nixie_tube_gui.destroy_guis_for_entity()

    destroy_arithmetic_combinators(unit_number)

    -- Promote the next display (to the west) to a controller if there is one
    if display and display.next_display then
        local next_display = storage.displays[display.next_display]

        if next_display and next_display.entity.valid then
            local controller = helpers.storage_set_controller(next_display.entity)
            update_controller(controller)
        end
    end

    storage.displays[unit_number] = nil
    helpers.remove_controller(unit_number)

    -- Invalidate controller caches since the chain structure has changed
    helpers.invalidate_all_controller_caches()
end

--- Rebuild the per-surface controller index, for saves from before it existed
local function rebuild_indexes()
    storage.controllers_by_surface = {}
    storage.next_controller_by_surface = {}

    local invalid_controllers = {}
    for unit_number, controller in pairs(storage.controllers) do
        if controller.entity.valid then
            controller.surface_index = controller.entity.surface_index

            local surface_controllers = storage.controllers_by_surface[controller.surface_index]
            if not surface_controllers then
                surface_controllers = {}
                storage.controllers_by_surface[controller.surface_index] = surface_controllers
            end
            surface_controllers[unit_number] = controller
        else
            invalid_controllers[#invalid_controllers + 1] = unit_number
        end
    end

    for _, unit_number in pairs(invalid_controllers) do
        clean_up_nixie_tube(unit_number)
    end
end

--- Update up to `budget` controllers on this surface, continuing where the previous sweep stopped
--- @param surface_index uint
--- @param budget number
local function update_controllers_on_surface(surface_index, budget)
    local surface_controllers = storage.controllers_by_surface[surface_index]
    if not surface_controllers then
        return
    end

    local pointer = storage.next_controller_by_surface[surface_index]
    --- @type uint? The first controller visited in this sweep, to stop after one full cycle
    local first_visited
    local used = 0

    while used < budget do
        local key, controller = next(surface_controllers, pointer)

        -- Wrap around to the start if we've reached the end
        if key == nil then
            key, controller = next(surface_controllers)
        end

        if key == nil or key == first_visited then
            break
        end
        --- @cast controller NixieTubeController

        if first_visited == nil then
            first_visited = key
        end
        pointer = key

        if not controller.entity.valid then
            -- Destroyed, but on_object_destroyed has not fired yet (it can arrive a tick later),
            -- or the save predates destruction registration. Resume on the next tick
            storage.next_controller_by_surface[surface_index] = nil
            clean_up_nixie_tube(key)
            return
        end

        update_controller(controller)
        used = used + 1
    end

    storage.next_controller_by_surface[surface_index] = pointer
end

--- @param _ EventData.on_tick
local function on_tick(_)
    storage.invalidated_this_tick = {}

    -- There are no controllers to update
    if next(storage.controllers) == nil then
        return
    end

    if not storage.controllers_by_surface then
        rebuild_indexes()
    end

    -- Determine which surfaces are being watched. player.surface_index follows the remote view, so looking
    -- at another surface through the zoomed-in map counts as watching it
    local watched_surfaces = {}
    local watched_count = 0
    for _, player in pairs(game.connected_players) do
        if player.render_mode == defines.render_mode.game or player.render_mode == defines.render_mode.chart_zoomed_in then
            local surface_index = player.surface_index
            if not watched_surfaces[surface_index] and storage.controllers_by_surface[surface_index] then
                watched_surfaces[surface_index] = true
                watched_count = watched_count + 1
            end
        end
    end

    if watched_count == 0 then
        return
    end

    -- Split the update budget between watched surfaces, so displays on one cannot starve the others
    local budget = math.ceil(storage.controller_updates_per_tick / watched_count)
    for surface_index in pairs(watched_surfaces) do
        update_controllers_on_surface(surface_index, budget)
    end
end

--- @param event EventData.on_object_destroyed
local function on_object_destroyed(event)
    if event.type ~= defines.target_type.entity then
        return
    end

    -- For entities, the useful_id is the unit number
    clean_up_nixie_tube(event.useful_id)
end

--- @param event EventData.on_entity_cloned
local function on_entity_cloned(event)
    local destination = event.destination
    if not (destination and destination.valid) then
        return
    end

    -- Cloning an area also clones the hidden digit sprites; the display will recreate its own
    if helpers.is_nixie_tube_sprite(destination) then
        destination.destroy()
        return
    end

    if helpers.is_nixie_tube(destination) then
        configure_nixie_tube(destination)
    end
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

    local control_behavior = nixie_tube.get_or_create_control_behavior() --[[@as LuaLampControlBehavior?]]
    if control_behavior then
        control_behavior.circuit_enable_disable = true
    end

    configure_nixie_tube(nixie_tube)
end

--- Invalidate the cached signal of a Nixie Tube controller so it is re-read on its next update
--- @param entity LuaEntity
local function invalidate_selected_signal(entity)
    local controller = storage.controllers[entity.unit_number]
    if controller then
        controller.selected_signal = nil
        controller.previous_value = nil
    end
end

--- @param event EventData.on_entity_settings_pasted
local function on_entity_settings_pasted(event)
    invalidate_selected_signal(event.destination)
end

--- @param event EventData.on_blueprint_settings_pasted
local function on_blueprint_settings_pasted(event)
    invalidate_selected_signal(event.entity)
end

--- Undo and redo can revert circuit conditions without raising further events, so invalidate all cached signals
local function on_undo_redo_applied()
    for _, controller in pairs(storage.controllers) do
        controller.selected_signal = nil
        controller.previous_value = nil
    end
end

--- Cache the runtime settings in storage
local function read_settings()
    storage.controller_updates_per_tick = settings.global["nixie-tube-group-updates-per-tick"].value --[[@as number]]
    storage.use_overflow_notation = settings.global["nixie-tube-enable-overflow-notation"].value --[[@as boolean]]
end

--- @param event EventData.on_runtime_mod_setting_changed
local function on_runtime_mod_setting_changed(event)
    read_settings()

    if event.setting == "nixie-tube-enable-overflow-notation" then
        helpers.invalidate_all_controller_caches()
    end
end

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
    controller.selected_signal = signal or false
    controller.previous_value = nil

    update_controller(controller)
end

local nixie_tube = {
    on_init = function ()
        --- @type table<uint, NixieTubeController> The rightmost Nixie Tubes of each series, responsible for updating it
        storage.controllers = {}

        --- @type table<uint, table<uint, NixieTubeController>> Controllers indexed per surface, so surfaces nobody
        ---     is looking at can be skipped entirely
        storage.controllers_by_surface = {}

        --- @type table<uint, uint> Per surface, the unit number of the last updated controller, so the sweep can
        ---     continue where it left off when there are more controllers than the update budget
        storage.next_controller_by_surface = {}

        --- @type table<uint, NixieTubeDisplay> The individual Nixie Tubes. A Nixie Tube can be both a display and
        ---     a controller
        storage.displays = {}

        --- @type table<uint, NixieTubeGui>
        storage.gui = {}

        --- @type table<uint, boolean> Displays already invalidated this tick, to avoid redundant recursion
        storage.invalidated_this_tick = {}

        read_settings()
    end,

    on_configuration_changed = function ()
        read_settings()
        reconfigure_nixie_tubes()
    end,

    events = {
        [defines.events.on_tick] = on_tick,
        [defines.events.on_script_trigger_effect] = on_script_trigger_effect,
        [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
        [defines.events.on_gui_opened] = nixie_tube_gui.on_gui_opened,

        [defines.events.on_entity_settings_pasted] = on_entity_settings_pasted,
        [defines.events.on_blueprint_settings_pasted] = on_blueprint_settings_pasted,
        [defines.events.on_undo_applied] = on_undo_redo_applied,
        [defines.events.on_redo_applied] = on_undo_redo_applied,

        [defines.events.on_object_destroyed] = on_object_destroyed,
        [defines.events.on_entity_cloned] = on_entity_cloned,
    }
}

return nixie_tube
