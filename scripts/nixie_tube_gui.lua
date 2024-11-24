local gui = require("__flib__.gui")
local helpers = require("scripts.helpers")
local nixie_tube_gui = {}

nixie_tube_gui.callbacks = {
    --- @type fun(self: NixieTubeGui, event: EventData.on_gui_selection_state_changed)?
    on_nt_gui_elem_changed = nil,
}

--- @param player_index uint
function nixie_tube_gui.destroy_gui(player_index)
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

function nixie_tube_gui.destroy_all_guis()
    for player_index, _ in pairs(storage.gui) do
        nixie_tube_gui.destroy_gui(player_index)
    end
end

--- @param self NixieTubeGui
--- @param new_entity LuaEntity?
function nixie_tube_gui.update_gui(self, new_entity)
    if not new_entity and not self.entity.valid then
        nixie_tube_gui.destroy_gui(self.player.index)
        return
    end

    if new_entity then
        self.entity = new_entity
    end
end

--- @param entity LuaEntity
function nixie_tube_gui.update_all_guis(entity)
    for _, gui in pairs(storage.gui) do
        if not gui.entity.valid or gui.entity == entity then
            nixie_tube_gui.update_gui(gui, entity)
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

    local is_controller = storage.controllers[entity.unit_number] ~= nil
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
                {
                    type = "camera",
                    position = entity.name == "classic-nixie-tube" and {
                        x = entity.position.x,
                        y = entity.position.y - 0.35,
                    } or entity.position,
                    surface_index = entity.surface.index,
                    zoom = 2,
                    style_mods = { width = 125, height = 150 },
                }
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
                    enabled = is_controller,
                    handler = {
                        [defines.events.on_gui_elem_changed] = nixie_tube_gui.on_nt_gui_elem_changed,
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

    nixie_tube_gui.update_gui(self)
end

--- @param event EventData.on_gui_opened
function nixie_tube_gui.on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid or not helpers.is_nixie_tube(entity) then
        return
    end

    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    nixie_tube_gui.create_nixie_tube_gui(player, entity)
end

--- @param self NixieTubeGui
--- @param event EventData.on_gui_closed|EventData.on_gui_click
function nixie_tube_gui.on_nt_gui_closed(self, event)
    nixie_tube_gui.destroy_gui(event.player_index)
end

--- @param self NixieTubeGui
--- @param event EventData.on_gui_selection_state_changed
function nixie_tube_gui.on_nt_gui_elem_changed(self, event)
    nixie_tube_gui.callbacks.on_nt_gui_elem_changed(self, event)
    nixie_tube_gui.update_all_guis(self.entity)
end

gui.add_handlers(nixie_tube_gui, function (event, handler)
    local self = storage.gui[event.player_index]
    if not self then return end
    if not self.entity.valid then return end

    handler(self, event)
end)

gui.handle_events()

return nixie_tube_gui
