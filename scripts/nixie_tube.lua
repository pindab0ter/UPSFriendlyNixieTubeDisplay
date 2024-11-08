local stateDisplay = {
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

local validNixieNumber = {
    ['SNTD-old-nixie-tube'] = 1,
    ['SNTD-nixie-tube'] = 1,
    ['SNTD-nixie-tube-small'] = 2
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
                parameters.operation = stateDisplay[new_state]
            else
                if parameters.operation ~= stateDisplay["off"] then
                    parameters.operation = stateDisplay["off"]
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
    local num = validNixieNumber[entity.name]

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

local function on_remove_entity(entity) --or event
    entity = entity.entity

    if entity.valid then
        if validNixieNumber[entity.name] then
            remove_nixie_sprites(entity)

            -- If it was a controller, deregister
            if storage.nextNixieController == entity.unit_number then
                -- If it was the *next* controller, pass it forward...
                if not storage.SNTD_nixieControllers[storage.nextNixieController] then
                    error("Invalid next_controller removal")
                end

                storage.nextNixieController = next(storge.SNTD_nixieControllers, storage.nextNixieController)
            end
            storage.SNTD_nixieControllers[entity.unit_number] = nil

            -- If it had a next-digit, register it as a controller
            local nextDigit = storage.SNTD_nextNixieDigit[entity.unit_number]
            if nextDigit and nextDigit.valid then
                storage.SNTD_nixieControllers[nextDigit.unit_number] = nextDigit
                displayValueString(nextDigit)
            end

            -- Clean up
            storage.SNTD_nixieSprites[entity.unit_number] = nil
            storage.SNTD_nextNixieDigit[entity.unit_number] = nil
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

        for nixie_name, _ in pairs(validNixieNumber) do
            local entities = surface.find_entities_filtered { name = nixie_name }
            for _, entity in pairs(entities) do
                gizmatize_nixie(entity);
            end
        end
    end
end

local nixie_tube = {}

nixie_tube.on_init = function()
    storage.SNTD_nixieControllers = {}
    storage.SNTD_nixieSprites = {}
    storage.SNTD_nextNixieDigit = {}
    regizmatize_nixies()
end

nixie_tube.on_configuration_changed = function()
    regizmatize_nixies()
end

nixie_tube.events = {
    [defines.events.on_built_entity] = on_place_entity,
    [defines.events.on_robot_built_entity] = on_place_entity,
    [defines.events.script_raised_revive] = on_place_entity,
    [defines.events.script_raised_built] = on_place_entity,

    [defines.events.on_pre_player_mined_item] = on_remove_entity,
    [defines.events.on_robot_pre_mined] = on_remove_entity,
    [defines.events.on_entity_died] = on_remove_entity,
    [defines.events.script_raised_destroy] = on_remove_entity,

    [defines.events.on_tick] = on_tick
}

return nixie_tube
