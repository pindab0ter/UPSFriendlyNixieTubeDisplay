local gui = require("__flib__.gui")
local util = require("scripts.util")

--- @class NixieTubeController
--- @field entity LuaEntity
--- @field signal SignalID?
--- @field last_value int?

--- @class NixieTubeDisplay
--- @field entity LuaEntity
--- @field sprites table<uint, LuaRenderObject>
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

--- @param nixie_tube LuaEntity
--- @param data table?
--- @return NixieTubeDisplay
local function storage_set_display(nixie_tube, data)
    local display = storage.displays[nixie_tube.unit_number]
    if not display then
        display = {
            entity = nixie_tube,
            sprites = {},
            next_display = nil,
            remaining_value = nil,
        }
        storage.displays[nixie_tube.unit_number] = display
    end

    for k, v in pairs(data or {}) do
        display[k] = v
    end

    return display
end

--- @param nixie_tube LuaEntity
--- @param data table?
local function storage_set_controller(nixie_tube, data)
    local controller = storage.controllers[nixie_tube.unit_number]
    if not controller then
        controller = {
            entity = nixie_tube,
            signal = nil,
            last_value = nil
        }
        storage.controllers[nixie_tube.unit_number] = controller
    end

    if not data then
        return
    end

    for k, v in pairs(data) do
        controller[k] = v
    end
end

local digit_counts = {
    ['SNTD-old-nixie-tube'] = 1,
    ['SNTD-nixie-tube'] = 1,
    ['SNTD-nixie-tube-small'] = 2
}

local entity_names = {
    'SNTD-old-nixie-tube',
    'SNTD-nixie-tube',
    'SNTD-nixie-tube-small'
}

--- Set the digit(s) and update the sprite for a nixie tube
--- @param display NixieTubeDisplay
--- @param values table<string, string>
local function draw_sprites(display, values)
    for key, value in pairs(values) do
        local has_enough_energy = display.entity.energy >= 50 or script.level.is_simulation
        if not value or not has_enough_energy then
            value = "off"
        end

        local render_object = display.sprites[key]

        if not (render_object and render_object.valid) then
            render_object = rendering.draw_sprite {
                sprite = "SNTD-old-nixie-tube-" .. value,
                target = {
                    entity = display.entity,
                    offset = { 0, -0.5 }
                },
                surface = display.entity.surface,
                render_layer = "object",
            }

            display.sprites[key] = render_object
            return
        end

        render_object.sprite = "SNTD-old-nixie-tube-" .. value
    end
end

--- Display the value on this and adjacent Nixie tubes
--- @param display NixieTubeDisplay
--- @param value? string
local function draw_value(display, value)
    if not (display and display.entity and display.entity.valid) then
        return
    end

    local sprite_count = digit_counts[display.entity.name]

    if (not value) then
        -- Set this display to 'off'
        draw_sprites(display, (sprite_count == 1) and { "off" } or { "off", "off" })
    elseif #value < sprite_count then
        -- Display the last digit
        draw_sprites(display, { "off", value })
    elseif #value >= sprite_count then
        -- Display the rightmost `sprite_count` digits
        draw_sprites(
            display,
            (sprite_count == 1) and { value:sub(-1) } or { value:sub(-2, -2), value:sub(-1) }
        )
    end

    if display.next_display then
        local next_display = storage.displays[display.next_display]

        if not (next_display and next_display.entity and next_display.entity.valid) then
            return
        end

        -- Cache the remaining value
        local remaining_value = value and value:sub(1, -(sprite_count + 1)) or nil
        if next_display.remaining_value == remaining_value then
            return
        end
        next_display.remaining_value = remaining_value

        if value and (#value > sprite_count) then
            draw_value(next_display, remaining_value)
        else
            -- Set display to 'off'
            draw_value(next_display, nil)
        end
    end
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
function configure_nixie_tube(nixie_tube)
    nixie_tube.always_on = true

    local digit_count = digit_counts[nixie_tube.name]

    if not digit_count then
        return
    end

    storage_set_display(nixie_tube)

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

            storage.controllers[neighbor.unit_number] = nil
            storage_set_display(nixie_tube, {
                next_display = neighbor.unit_number
            })
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
            local display = storage_set_display(neighbor, {
                next_display = nixie_tube.unit_number,
            })

            -- Otherwise the display will not render until the value of the display to the east changes
            invalidate_remaining_value_cache(display)
        end
    end

    -- If there is no eastern neighbor, set this as a controller
    if not has_eastern_neighbor then
        local control_behavior = nixie_tube.get_or_create_control_behavior()
        local signal = control_behavior
            and control_behavior.circuit_condition
            and control_behavior.circuit_condition.first_signal
            or nil

        storage_set_controller(nixie_tube, {
            signal = signal,
        })
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

    local signal = controller.signal

    -- Set the displays to 'off' if there is no signal
    if not signal then
        if controller.last_value == nil then
            return
        end
        draw_value(display, nil)
        return
    end

    -- Get the signal value
    local value = controller.entity.get_signal(
        signal,
        defines.wire_connector_id.circuit_red,
        defines.wire_connector_id.circuit_green
    )

    -- Do not update the displays if the value hasn't changed
    if value == controller.last_value then
        return
    end
    controller.last_value = value

    draw_value(display, ("%i"):format(value))
end

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

local function reconfigure_nixie_tubes()
    storage.controllers = {}
    storage.next_controller = nil
    storage.displays = {}
    storage.gui = {}

    rendering.clear("UPSFriendlyNixieTubeDisplay")

    for _, surface in pairs(game.surfaces) do
        local entities = surface.find_entities_filtered { name = entity_names }
        for _, entity in pairs(entities) do
            configure_nixie_tube(entity);
        end
    end
end

--- @param player_index uint
local function destroy_gui(player_index)
    local player = game.get_player(player_index)
    player.opened = nil

    local self = storage.gui[player_index]
    if not self then
        return
    end

    storage.gui[player_index] = nil

    local window = self.elements.nt_nixie_tube_window
    if not window.valid then
        return
    end

    window.destroy()
end

--- @param self NixieTubeGui
--- @param new_entity LuaEntity?
local function update_gui(self, new_entity)
    if not new_entity and not self.entity.valid then
        destroy_gui(self.player.index)
        return
    end

    if new_entity then
        self.elements.entity_preview.entity = new_entity
        self.entity = new_entity
    end
end

--- @param entity LuaEntity
local function update_all_guis(entity)
    for _, gui in pairs(storage.gui) do
        if not gui.entity.valid or gui.entity == entity then
            update_gui(gui, entity)
        end
    end
end

local handlers = {
    --- @param self NixieTubeGui
    --- @param e EventData.on_gui_closed|EventData.on_gui_click
    on_nt_gui_closed = function(self, e)
        destroy_gui(e.player_index)

        local player = self.player
        if not player.valid then
            return
        end
    end,

    --- @param event EventData.on_gui_selection_state_changed
    on_nt_gui_elem_changed = function(self, event)
        local nixie_tube = self.entity
        local signal = event.element.elem_value
        local behavior = nixie_tube.get_or_create_control_behavior()

        behavior.circuit_condition = {
            comparator = "=",
            first_signal = signal,
            second_signal = signal,
        }

        storage_set_controller(nixie_tube, { signal = signal })
        draw_value(storage.displays[nixie_tube.unit_number])
        update_all_guis(nixie_tube)
    end,
}

gui.add_handlers(handlers, function(e, handler)
    local self = storage.gui[e.player_index]
    if not self then return end
    if not self.entity.valid then return end

    handler(self, e)
end)


--- @param player LuaPlayer
--- @param entity LuaEntity
local function create_nixie_tube_gui(player, entity)
    destroy_gui(player.index)

    local behavior = entity.get_or_create_control_behavior()
    if (not behavior or not behavior) then return end
    local condition = behavior.circuit_condition
    local signal = condition and condition.first_signal

    local elements = gui.add(player.gui.screen, {
        type = "frame",
        name = "nt_nixie_tube_window",
        direction = "vertical",
        elem_mods = { auto_center = true },
        handler = { [defines.events.on_gui_closed] = handlers.on_nt_gui_closed },
        tags = { nixie_tube_unit_number = entity.unit_number },
        {
            type = "flow",
            style = "flib_titlebar_flow",
            drag_target = "nt_nixie_tube_window",
            {
                type = "label",
                style = "flib_frame_title",
                caption = "Nixie Tube",
                ignored_by_interaction = true,
            },
            { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
            {
                type = "sprite-button",
                style = "frame_action_button",
                sprite = "utility/close",
                tooltip = { "gui.close-instruction" },
                mouse_button_filter = { "left" },
                handler = { [defines.events.on_gui_click] = handlers.on_nt_gui_closed },
            }
        },
        {
            type = "frame",
            style = "entity_frame",
            style_mods = { padding = 12 },
            direction = "vertical",
            {
                type = "frame",
                style = "deep_frame_in_shallow_frame",
                {
                    type = "entity-preview",
                    name = "entity_preview",
                    style = "wide_entity_button",
                    elem_mods = { entity = entity },
                },
            },
            {
                type = "flow",
                style = "player_input_horizontal_flow",
                style_mods = { top_margin = 4, vertical_align = "center" },
                {
                    type = "label",
                    caption = "Signal",
                    style_mods = { width = 77 }
                },
                {
                    type = "choose-elem-button",
                    elem_type = "signal",
                    signal = signal,
                    -- locked = true, -- TODO: Figure out why this isn't respected
                    handler = {
                        [defines.events.on_gui_elem_changed] = handlers.on_nt_gui_elem_changed,
                    },
                },
            },
        },
    })

    player.opened = elements.nt_nixie_tube_window

    --- @class NixieTubeGui
    local self = {
        elements = elements,
        entity = entity,
        player = player,
    }

    storage.gui[player.index] = self

    update_gui(self)
end

--- @param event EventData.on_gui_opened
local function on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid or not util.table_contains(entity_names, entity.name) then
        return
    end

    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    create_nixie_tube_gui(player, entity)
end

--- @param event EventData.on_object_destroyed
local function on_object_destroyed(event)
    local entity = event.entity
    if not entity or not entity.valid or not util.table_contains(entity_names, entity.name) then
        return
    end

    for player_index, gui in pairs(storage.gui) do
        if gui.entity == entity then
            destroy_gui(player_index)
        end
    end

    storage.displays[entity.unit_number] = nil
    storage.controllers[entity.unit_number] = nil
    storage.next_controller = nil
end

script.on_configuration_changed(function()
    reconfigure_nixie_tubes()
end)

script.on_init(function()
    storage.controllers = {}
    storage.next_controller = nil
    storage.displays = {}

    --- @type table<uint, NixieTubeGui>
    storage.gui = {}
end)

commands.add_command(
    "reconfigure-nixie-tubes",
    "Reconfigure all Nixie Tubes",
    function()
        game.player.opened = nil
        reconfigure_nixie_tubes()
    end
)

local filters = {}
filters[#filters + 1] = { filter = "name", name = "nixie_tube" }
filters[#filters + 1] = { filter = "ghost_name", name = "nixie_tube" }

local nixie_tube = {
    events = {
        [defines.events.on_tick] = on_tick,
        [defines.events.on_gui_opened] = on_gui_opened,

        [defines.events.on_entity_died] = on_object_destroyed,
        [defines.events.on_player_mined_entity] = on_object_destroyed,
        [defines.events.on_pre_player_mined_item] = on_object_destroyed,
        [defines.events.on_robot_mined_entity] = on_object_destroyed,
        [defines.events.script_raised_destroy] = on_object_destroyed,
    }
}

script.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id == "nixie-tube-created" then
        local entity = event.cause_entity
        if entity then
            configure_nixie_tube(entity)
        end
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting == "nixie-update-delay" then
        storage.update_delay = tonumber(settings.global["nixie-update-delay"].value)
    elseif event.setting == "nixie-tube-update-speed" then
        storage.update_speed = tonumber(settings.global["nixie-tube-update-speed"].value)
    end
end)

return nixie_tube
