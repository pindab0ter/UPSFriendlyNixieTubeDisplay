local gui = require("__flib__.gui")
local helpers = require("scripts.helpers")
local nixie_tube_gui = {}

nixie_tube_gui.callbacks = {
    --- @type fun(self: NixieTubeGui, event: EventData.on_gui_selection_state_changed)?
    on_nt_gui_elem_changed = nil,
}

--- @param player_index uint
function nixie_tube_gui.destroy_gui(player_index)
    local self = storage.gui[player_index]
    if not self then
        return
    end

    storage.gui[player_index] = nil

    -- Destroying the window also clears player.opened if it was open
    local window = self.elements.nt_nixie_tube_window
    if window and window.valid then
        window.destroy()
    end
end

--- Destroy all Nixie Tube GUIs, including windows that are no longer tracked in storage
function nixie_tube_gui.destroy_all_guis()
    for player_index, _ in pairs(storage.gui) do
        nixie_tube_gui.destroy_gui(player_index)
    end

    for _, player in pairs(game.players) do
        local window = player.gui.screen.nt_nixie_tube_window
        if window then
            window.destroy()
        end
    end
end

--- Destroy the GUIs that are showing this entity, or any GUI whose entity is gone when no entity is given
--- @param entity LuaEntity?
function nixie_tube_gui.destroy_guis_for_entity(entity)
    for player_index, player_gui in pairs(storage.gui) do
        if not player_gui.entity.valid or player_gui.entity == entity then
            nixie_tube_gui.destroy_gui(player_index)
        end
    end
end

--- Bring a GUI in line with the current state of its entity
--- @param self NixieTubeGui
function nixie_tube_gui.update_gui(self)
    if not self.entity.valid then
        nixie_tube_gui.destroy_gui(self.player.index)
        return
    end

    -- Ghosts are not tracked in storage; their chooser only changes through the GUI itself
    if self.entity.name == "entity-ghost" then
        return
    end

    local controller = storage.controllers[self.entity.unit_number]
    local signal = controller and controller.selected_signal or nil
    self.elements.nt_signal_chooser.elem_value = signal or nil
end

--- @param entity LuaEntity
function nixie_tube_gui.update_guis_for_entity(entity)
    for _, player_gui in pairs(storage.gui) do
        if not player_gui.entity.valid or player_gui.entity == entity then
            nixie_tube_gui.update_gui(player_gui)
        end
    end
end

--- Refresh the value readout and signal chooser of all open GUIs. Runs every tick while any GUI is open,
--- so only touches elements when something changed
function nixie_tube_gui.update_guis()
    for _, player_gui in pairs(storage.gui) do
        local entity = player_gui.entity
        if entity.valid and entity.name ~= "entity-ghost" then
            local controller = storage.controllers[entity.unit_number]

            local value = controller and controller.previous_value
            if player_gui.last_value ~= value then
                player_gui.last_value = value
                player_gui.elements.nt_value_label.caption = value and ("%i"):format(value) or ""
            end

            local signal = controller and controller.selected_signal or nil
            if player_gui.last_signal ~= signal then
                player_gui.last_signal = signal
                player_gui.elements.nt_signal_chooser.elem_value = signal or nil
            end
        end
    end
end

--- @param player LuaPlayer
--- @param entity LuaEntity
function nixie_tube_gui.create_nixie_tube_gui(player, entity)
    nixie_tube_gui.destroy_gui(player.index)

    local behavior = entity.get_or_create_control_behavior() --[[@as LuaLampControlBehavior?]]

    if not behavior then
        return
    end

    local is_ghost = entity.name == "entity-ghost"
    local is_controller = is_ghost or storage.controllers[entity.unit_number] ~= nil
    local circuit_condition = behavior.circuit_condition --[[@as CircuitCondition?]]
    local signal = circuit_condition and circuit_condition.first_signal

    local elements = gui.add(player.gui.screen, {
        type = "frame",
        name = "nt_nixie_tube_window",
        direction = "vertical",
        elem_mods = { auto_center = true },
        handler = { [defines.events.on_gui_closed] = nixie_tube_gui.on_nt_gui_closed },
        tags = { nixie_tube_unit_number = entity.unit_number },
        {
            type = "flow",
            style = "flib_titlebar_flow",
            drag_target = "nt_nixie_tube_window",
            {
                type = "label",
                style = "flib_frame_title",
                caption = { "entity-name." .. (is_ghost and entity.ghost_name or entity.name) },
                ignored_by_interaction = true,
            },
            { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
            {
                type = "sprite-button",
                style = "frame_action_button",
                sprite = "utility/close",
                tooltip = { "gui.close-instruction" },
                mouse_button_filter = { "left" },
                handler = { [defines.events.on_gui_click] = nixie_tube_gui.on_nt_gui_closed },
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
                style_mods = { horizontally_stretchable = true },
                {
                    type = "camera",
                    position = entity.name == "classic-nixie-tube" and {
                        x = entity.position.x,
                        y = entity.position.y - 0.35,
                    } or entity.position,
                    surface_index = entity.surface.index,
                    zoom = 2,
                    style_mods = { minimal_width = 125, height = 150, horizontally_stretchable = true },
                }
            },
            {
                type = "flow",
                style = "player_input_horizontal_flow",
                style_mods = { top_margin = 4, vertical_align = "center" },
                {
                    type = "label",
                    caption = { "gui.nixie-tube-signal" },
                },
                { type = "empty-widget", style_mods = { horizontally_stretchable = true } },
                {
                    type = "choose-elem-button",
                    name = "nt_signal_chooser",
                    elem_type = "signal",
                    signal = signal,
                    enabled = is_controller,
                    handler = {
                        [defines.events.on_gui_elem_changed] = nixie_tube_gui.on_nt_gui_elem_changed,
                    },
                },
            },
            { type = "line", visible = not is_ghost },
            {
                type = "flow",
                style = "player_input_horizontal_flow",
                style_mods = { vertical_align = "center" },
                visible = not is_ghost,
                {
                    type = "label",
                    caption = { "gui.nixie-tube-value" },
                },
                { type = "empty-widget", style_mods = { horizontally_stretchable = true } },
                {
                    type = "label",
                    name = "nt_value_label",
                    caption = "",
                },
            },
        },
    })

    player.opened = elements.nt_nixie_tube_window

    --- @class NixieTubeGui
    --- @field last_value int? The value last written to the readout
    --- @field last_signal SignalID|false|nil The signal last written to the chooser
    local self = {
        elements = elements,
        entity = entity,
        player = player,
        last_value = nil,
        last_signal = nil,
    }

    storage.gui[player.index] = self
end

--- @param event EventData.on_gui_opened
function nixie_tube_gui.on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local is_ghost = entity.name == "entity-ghost" and helpers.digit_counts[entity.ghost_name] ~= nil
    if not is_ghost and not helpers.is_nixie_tube(entity) then
        return
    end

    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    -- The signal is configured on the rightmost Nixie Tube of a row, so open that one instead
    if not is_ghost then
        local controller = helpers.find_chain_controller(entity.unit_number)
        if controller and controller.entity.valid then
            entity = controller.entity
        end
    end

    nixie_tube_gui.create_nixie_tube_gui(player, entity)
end

--- @param self NixieTubeGui
--- @param event EventData.on_gui_closed|EventData.on_gui_click
function nixie_tube_gui.on_nt_gui_closed(self, event)
    local player = game.get_player(event.player_index)
    if player and self.entity.valid and self.entity.name ~= "entity-ghost" then
        player.play_sound { path = "entity-close/" .. self.entity.name }
    end

    nixie_tube_gui.destroy_gui(event.player_index)
end

--- @param self NixieTubeGui
--- @param event EventData.on_gui_selection_state_changed
function nixie_tube_gui.on_nt_gui_elem_changed(self, event)
    if nixie_tube_gui.callbacks.on_nt_gui_elem_changed then
        nixie_tube_gui.callbacks.on_nt_gui_elem_changed(self, event)
    end
    nixie_tube_gui.update_guis_for_entity(self.entity)
end

gui.add_handlers(nixie_tube_gui, function (event, handler)
    local self = storage.gui[event.player_index]
    if not self then return end
    if not self.entity.valid then return end

    handler(self, event)
end)

gui.handle_events()

return nixie_tube_gui
