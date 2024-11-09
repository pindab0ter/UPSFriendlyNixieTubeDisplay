local gui = require("__flib__.gui")

local state_display = {
    ["off"] = "*", -- default

    ["0"] = "+",
    ["1"] = "-",
    ["2"] = "/",
    ["3"] = "%",
    ["4"] = "^",
    ["5"] = "<<",
    ["6"] = ">>",
    ["7"] = "AND",
    ["8"] = "OR",
    ["9"] = "XOR"
}

local valid_nixie_number = {
    ['SNTD-old-nixie-tube'] = 1,
    ['SNTD-nixie-tube'] = 1,
    ['SNTD-nixie-tube-small'] = 2
}

local entity_names = {
    ['SNTD-old-nixie-tube'] = true,
    ['SNTD-nixie-tube'] = true,
    ['SNTD-nixie-tube-small'] = true
}

local sprite_names = {
    'SNTD-nixie-tube-sprite',
    'SNTD-old-nixie-tube-sprite',
    'SNTD-nixie-tube-small-sprite',
}

local function remove_nixie_sprites(nixie)
    if storage.SNTD_nixieSprites[nixie.unit_number] ~= nil then
        for _, sprite in pairs(storage.SNTD_nixieSprites[nixie.unit_number]) do
            if sprite.valid then
                sprite.destroy()
            end
        end
    end
end

-- Set the state(s) and update the sprite for a nixie
local function setStates(nixie, newstates)
    for key, new_state in pairs(newstates) do
        if not new_state then new_state = "off" end

        local sprite = storage.SNTD_nixieSprites[nixie.unit_number][key]
        if sprite and sprite.valid then
            local behavior = sprite.get_or_create_control_behavior()
            local parameters = behavior.parameters
            if nixie.energy >= 50 then
                -- new_state is a string of the new state (see stateDisplay)
                parameters.operation = state_display[new_state]
            else
                if parameters.operation ~= state_display["off"] then
                    parameters.operation = state_display["off"]
                end
            end
            behavior.parameters = parameters
        else
            log("Invalid nixie: " .. nixie.unit_number)
        end
    end
end

local function get_signal_value(entity)
    local behavior = entity.get_control_behavior()
    if behavior == nil then return nil end

    if behavior.disabled then return nil end

    local condition = behavior.circuit_condition
    if condition == nil then return nil end

    -- shortcut, return stored value if unchanged
    -- TODO: Use storage instead of this entity's signal constant
    -- if not sig and condition.fulfilled and condition.comparator == "=" then
    --   return condition.constant, false
    -- end
    -- Get the variable to display; return if none selected
    local signal
    signal = condition.first_signal

    if signal == nil or signal.name == nil then return (nil) end

    -- check both wires of the variable
    local redCircuitValue = 0
    local redCircuitNetwork = entity.get_circuit_network(defines.wire_type.red)
    if redCircuitNetwork then
        redCircuitValue = redCircuitNetwork.get_signal(signal)
    end

    local greenCircuitvalue = 0
    local greenCircuitNetwork = entity.get_circuit_network(defines.wire_type.green)
    if greenCircuitNetwork then
        greenCircuitvalue = greenCircuitNetwork.get_signal(signal)
    end

    local circuitTotal = redCircuitValue + greenCircuitvalue

    return circuitTotal, true
end


--- Display the value on the nixie tube
local function displayValueString(entity, valueString, enabled)
    if not (entity and entity.valid) then return end

    -- Check if the nixie is enabled and pass it on to the next digit
    if (enabled == nil) then
        enabled = false
        local behavior = entity.get_control_behavior()
        if behavior and behavior.circuit_condition and behavior.circuit_condition.fulfilled then
            enabled = true
        end
    end

    local nextDigit = storage.SNTD_nextNixieDigit[entity.unit_number]
    local spriteCount = #storage.SNTD_nixieSprites[entity.unit_number]

    if (not valueString) or (not enabled) then
        -- Set both this digit and the next digit to 'off'
        setStates(entity, (spriteCount == 1) and { "off" } or { "off", "off" })
    elseif #valueString < spriteCount then
        -- Set this digit to the value, and the next digit to 'off'
        setStates(entity, { "off", valueString })
    elseif #valueString >= spriteCount then
        -- Set this digit and pass the rest to the next digit
        setStates(entity,
            (spriteCount == 1) and { valueString:sub(-1) } or { valueString:sub(-2, -2), valueString:sub(-1) })
    end

    if nextDigit then
        if valueString and (#valueString > spriteCount) and enabled then
            displayValueString(nextDigit, valueString:sub(1, -(spriteCount + 1)), enabled)
        else
            -- Set next digit to 'off'
            displayValueString(nextDigit, nil, enabled)
        end
    end
end

local function on_place_entity(event)
    local entity = event.created_entity or event.entity

    if not entity.valid then
        return
    end

    gizmatize_nixie(entity)
end

function gizmatize_nixie(entity)
    local num = valid_nixie_number[entity.name]

    if num then
        local pos = entity.position
        local surf = entity.surface

        local sprites = {}
        -- placing the base of the nixie
        for n = 1, num do
            -- place nixie at same spot
            local name, position
            if num == 1 then -- large nixie, one sprites
                if entity.name == "SNTD-nixie-tube" then
                    name = "SNTD-nixie-tube-sprite"
                    position = { x = pos.x + 1 / 32, y = pos.y + 1 / 32 }
                else -- old nixie tube
                    name = "SNTD-old-nixie-tube-sprite"
                    position = { x = pos.x + 1 / 32, y = pos.y + 3.5 / 32 }
                end
            else -- small nixie, two sprites
                name = "SNTD-nixie-tube-small-sprite"
                position = { x = pos.x - 4 / 32 + ((n - 1) * 10 / 32), y = pos.y + 3 / 32 }
            end

            local sprite = surf.create_entity(
                {
                    name = name,
                    position = position,
                    force = entity.force
                })
            sprites[n] = sprite
        end

        storage.SNTD_nixieSprites[entity.unit_number] = sprites

        -- properly reset nixies when (re)added
        local behavior = entity.get_or_create_control_behavior()
        local condition = behavior.circuit_condition
        condition.comparator = "="
        condition.constant = 0
        condition.second_signal = nil
        behavior.circuit_condition = condition

        --enslave guy to left, if there is one
        local neighbors = surf.find_entities_filtered {
            position = { x = entity.position.x - 1, y = entity.position.y },
            name = entity.name }
        for _, n in pairs(neighbors) do
            if n.valid then
                if storage.nextNixieController == n.unit_number then
                    -- if it's currently the *next* controller, claim that too...
                    storage.nextNixieController = entity.unit_number
                end

                storage.SNTD_nixieControllers[n.unit_number] = nil
                storage.SNTD_nextNixieDigit[entity.unit_number] = n
            end
        end

        --slave self to right, if any, otherwise this will be the controller
        neighbors = surf.find_entities_filtered {
            position = { x = entity.position.x + 1, y = entity.position.y },
            name = entity.name }
        local foundright = false
        for _, n in pairs(neighbors) do
            if n.valid then
                foundright = true
                storage.SNTD_nextNixieDigit[n.unit_number] = entity
            end
        end
        if not foundright then
            storage.SNTD_nixieControllers[entity.unit_number] = entity
        end
    end
end

local function on_tick_controller(entity)
    if not entity.valid then
        log("Removed invalid nixie: " .. entity.unit_number)
        return
    end

    local value, value_changed = get_signal_value(entity)

    if value then
        if value_changed then
            local format = "%i"
            local valueString = format:format(value)
            displayValueString(entity, valueString)
        end
    else
        displayValueString(entity)
    end
end

--- @param event EventData.on_tick
local function on_tick(event)
    if (settings.global["nixie-update-delay"].value == 0 or event.tick % settings.global["nixie-update-delay"].value == 0) then
        for _ = 1, settings.global["nixie-tube-update-speed"].value do
            local nixie

            if storage.nextNixieController and not storage.SNTD_nixieControllers[storage.nextNixieController] then
                error("Invalid next_controller")
            end

            storage.nextNixieController, nixie = next(storage.SNTD_nixieControllers, storage.nextNixieController)

            if nixie then
                if nixie.valid then
                    on_tick_controller(nixie)
                else
                    log("Removing invalid nixie: " .. nixie.unit_number)
                    nixie = nil
                end
            else
                return
            end
        end
    end
end

local function regizmatize_nixies()
    storage.SNTD_nixieControllers = {}
    storage.SNTD_nixieSprites = {}
    storage.SNTD_nextNixieDigit = {}

    for _, surface in pairs(game.surfaces) do
        for _, sprite_name in pairs(sprite_names) do
            local entities = surface.find_entities_filtered { name = sprite_name }
            for _, entity in pairs(entities) do
                entity.destroy();
            end
        end

        for nixie_name, _ in pairs(valid_nixie_number) do
            local entities = surface.find_entities_filtered { name = nixie_name }
            for _, entity in pairs(entities) do
                gizmatize_nixie(entity);
            end
        end
    end
end

--- @param player_index uint
local function destroy_gui(player_index)
    local self = storage.nixie_tube_gui[player_index]
    if not self then
        return
    end

    storage.nixie_tube_gui[player_index] = nil

    local window = self.elems.nt_nixie_tube_window
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
        self.elems.entity_preview.entity = new_entity
        self.entity = new_entity
    end

    -- local entity = self.entity
    -- local priority = "primary"
    -- local mode = "output"
    --
    -- local mode_dropdown = self.elems.mode_dropdown
    -- mode_dropdown.selected_index = table.find(modes, mode) --[[@as uint]]

    -- local priority_dropdown = self.elems.priority_dropdown
    -- priority_dropdown.selected_index = table.find(priorities, priority) -]
    -- priority_dropdown.enabled = mode ~= "buffer"

    -- local slider_value, dropdown_index = get_slider_values(entity.electric_buffer_size, mode)

    -- local power_slider = self.elems.power_slider
    -- power_slider.slider_value = slider_value
    -- local textfield = self.elems.power_textfield
    -- textfield.text = tostring(slider_value)
    -- local dropdown = self.elems.power_dropdown
    -- if mode == "buffer" then
    --     dropdown.items = si_suffixes_joule
    -- else
    --     dropdown.items = si_suffixes_watt
    -- end
    -- dropdown.selected_index = dropdown_index
end

--- @param entity LuaEntity
local function update_all_guis(entity)
    for _, gui in pairs(storage.nixie_tube_gui) do
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
        -- player.play_sound({ path = "entity-close/ee-infinity-accumulator-tertiary-buffer" })
    end,

    --- @param e EventData.on_gui_selection_state_changed
    on_nt_gui_choose_elem_changed = function(self, e)
        log("Changing signal with event " .. (serpent.block(e.name)))

        local entity = self.entity

        local signal = e.element.elem_value
        if not signal then
            return
        end

        log("Signal: " .. signal.name)

        -- local behavior = entity.get_or_create_control_behavior()
        -- local conditin = behavior.circuit_condition
        -- condition.first_signal = signal
        -- behavior.circuit_condition = condition

        -- displayValueString(entity)
        update_all_guis(entity)
    end,
}

gui.add_handlers(handlers, function(e, handler)
    local self = storage.nixie_tube_gui[e.player_index]
    if not self then return end
    if not self.entity.valid then return end

    handler(self, e)
end)


--- @param player LuaPlayer
--- @param entity LuaEntity
local function create_gui(player, entity)
    destroy_gui(player.index)

    local elems = gui.add(player.gui.screen, {
        type = "frame",
        name = "nt_nixie_tube_window",
        direction = "vertical",
        elem_mods = { auto_center = true },
        handler = { [defines.events.on_gui_closed] = handlers.on_nt_gui_closed },
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
                style_mods = { top_margin = 4, vertical_align = "center" },
                {
                    type = "label",
                    caption = "Signal"
                },
                {
                    type = "choose-elem-button",
                    elem_type = "signal",
                    handler = {
                        [defines.events.on_gui_elem_changed] = handlers.on_nt_gui_choose_elem_changed,
                    },
                },
            },
            --  {
            --    { type = "empty-widget", style = "flib_horizontal_pusher", ignored_by_interaction = true },
            --     {
            --         type = "drop-down",
            --         name = "mode_dropdown",
            --         items = { { "gui.ee-output" }, { "gui.ee-input" }, { "gui.ee-buffer" } },
            --         selected_index = 0,
            --         handler = {
            --             [defines.events.on_gui_selection_state_changed] = handlers.on_nt_gui_mode_dropdown_changed,
            --         },
            --     },
            -- },
            -- { type = "line", direction = "horizontal" },
            -- {
            --     type = "flow",
            --     style_mods = { vertical_align = "center" },
            --     {
            --         type = "label",
            --         caption = { "", { "gui.ee-priority" }, " [img=info]" },
            --         tooltip = { "gui.ee-ia-priority-description" },
            --     },
            --     { type = "empty-widget", style = "flib_horizontal_pusher", ignored_by_interaction = true },
            --     {
            --         type = "drop-down",
            --         name = "priority_dropdown",
            --         items = { { "gui.ee-primary" }, { "gui.ee-secondary" }, { "gui.ee-tertiary" } },
            --         selected_index = 0,
            --         handler = {
            --             [defines.events.on_gui_selection_state_changed] = handlers.on_nt_gui_priority_dropdown_changed,
            --         },
            --     },
            -- },
            -- { type = "line", direction = "horizontal" },
            -- {
            --     type = "flow",
            --     style_mods = { vertical_align = "center" },
            --     {
            --         type = "label",
            --         style_mods = { right_margin = 6 },
            --         caption = { "gui.ee-power" },
            --     },
            --     {
            --         type = "slider",
            --         name = "power_slider",
            --         style_mods = { horizontally_stretchable = true },
            --         minimum_value = 0,
            --         maximum_value = 999,
            --         value = 0,
            --         handler = { [defines.events.on_gui_value_changed] = handlers.on_nt_gui_power_slider_changed },
            --     },
            --     {
            --         type = "textfield",
            --         name = "power_textfield",
            --         style = "nt_slider_textfield",
            --         text = "",
            --         numeric = true,
            --         allow_decimal = true,
            --         clear_and_focus_on_right_click = true,
            --         handler = { [defines.events.on_gui_text_changed] = handlers.on_nt_gui_power_textfield_changed },
            --     },
            --     {
            --         type = "drop-down",
            --         name = "power_dropdown",
            --         style_mods = { width = 69 },
            --         selected_index = 0,
            --         handler = {
            --             [defines.events.on_gui_selection_state_changed] = handlers.on_nt_gui_power_dropdown_changed,
            --         },
            --     },
            -- },
        },
    })

    player.opened = elems.nt_nixie_tube_window

    --- @class NixieTubeGui
    local self = {
        elems = elems,
        entity = entity,
        player = player,
    }

    storage.nixie_tube_gui[player.index] = self

    update_gui(self)
end

--- @param e EventData.on_gui_opened
local function on_gui_opened(e)
    if e.gui_type ~= defines.gui_type.entity then
        return
    end

    local entity = e.entity
    if not entity or not entity.valid or not entity_names[entity.name] then return end

    local player = game.get_player(e.player_index)
    if not player then return end

    create_gui(player, entity)
end

--- @param e DestroyedEvent
local function on_entity_destroyed(e)
    local entity = e.entity
    if not entity.valid or not entity_names[entity.name] then
        return
    end

    for player_index, gui in pairs(storage.nixie_tube_gui) do
        if gui.entity == entity then
            destroy_gui(player_index)
        end
    end
end

--- @param e EventData.on_entity_settings_pasted
local function on_entity_settings_pasted(e)
    local source = e.source
    if not source.valid or not entity_names[source.name] then
        return
    end

    local destination = e.destination
    if not destination.valid or not entity_names[destination.name] then
        return
    end

    --   local source_priority, source_mode = get_settings_from_name(source.name)
    --   local destination_priority, destination_mode = get_settings_from_name(destination.name)
    --   if source_priority == destination_priority and source_mode == destination_mode then
    --     return
    --   end
    --   local new_entity = change_entity(destination, source_priority, source_mode)
    --   if not new_entity then
    --     return
    --   end

    -- update_all_guis(new_entity)
end

script.on_configuration_changed(function()
    regizmatize_nixies()
end)

script.on_init(function()
    storage.SNTD_nixieControllers = {}
    storage.SNTD_nixieSprites = {}
    storage.SNTD_nextNixieDigit = {}

    --- @type table<uint, NixieTubeGui>
    storage.nixie_tube_gui = {}
    regizmatize_nixies()
end)

script.on_event(defines.events.on_tick, on_tick)

local nixie_tube = {}

nixie_tube.events = {
    [defines.events.on_gui_opened] = on_gui_opened,
    [defines.events.on_entity_settings_pasted] = on_entity_settings_pasted,

    [defines.events.on_entity_died] = on_entity_destroyed,
    [defines.events.on_player_mined_entity] = on_entity_destroyed,
    [defines.events.on_pre_player_mined_item] = on_entity_destroyed,
    [defines.events.script_raised_destroy] = on_entity_destroyed,

    [defines.events.on_built_entity] = on_place_entity,
    [defines.events.on_robot_built_entity] = on_place_entity,
    [defines.events.script_raised_built] = on_place_entity,
    [defines.events.script_raised_revive] = on_place_entity,
}

return nixie_tube
