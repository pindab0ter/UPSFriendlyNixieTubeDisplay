local helpers = {}

--- Digit capacity per Nixie Tube entity name. The single source of truth for which entities are Nixie Tubes
--- @type table<string, integer>
helpers.digit_counts = {
    ['classic-nixie-tube'] = 1,
    ['reinforced-nixie-tube'] = 1,
    ['small-reinforced-nixie-tube'] = 2,
}

--- @type string[] The names of all Nixie Tube entities
helpers.entity_names = {}

--- @type string[] The names of the hidden digit sprite entities
helpers.sprite_names = {}

local sprite_names_set = {}

for name in pairs(helpers.digit_counts) do
    helpers.entity_names[#helpers.entity_names + 1] = name

    local sprite_name = name .. "-sprite"
    helpers.sprite_names[#helpers.sprite_names + 1] = sprite_name
    sprite_names_set[sprite_name] = true
end

--- @param entity LuaEntity
--- @return boolean
function helpers.is_nixie_tube(entity)
    return helpers.digit_counts[entity.name] ~= nil
end

--- @param entity LuaEntity
--- @return boolean
function helpers.is_nixie_tube_sprite(entity)
    return sprite_names_set[entity.name] == true
end

--- @param nixie_tube LuaEntity
--- @param data table?
--- @return NixieTubeDisplay
function helpers.storage_set_display(nixie_tube, data)
    local display = storage.displays[nixie_tube.unit_number]

    if not display then
        display = {
            entity = nixie_tube,
            arithmetic_combinators = {},
            control_behaviors = {},
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
--- @return NixieTubeController
function helpers.storage_set_controller(nixie_tube, data)
    local controller = storage.controllers[nixie_tube.unit_number]
    if not controller then
        controller = {
            entity = nixie_tube,
            surface_index = nixie_tube.surface_index,
            selected_signal = nil,
            previous_value = nil
        }
        storage.controllers[nixie_tube.unit_number] = controller

        -- Index it per surface, so unwatched surfaces can be skipped. Absent on saves from
        -- older versions until the on_tick migration has rebuilt the indexes
        local by_surface = storage.controllers_by_surface
        if by_surface then
            local surface_controllers = by_surface[controller.surface_index]
            if not surface_controllers then
                surface_controllers = {}
                by_surface[controller.surface_index] = surface_controllers
            end
            surface_controllers[nixie_tube.unit_number] = controller
        end
    end

    for k, v in pairs(data or {}) do
        controller[k] = v
    end

    return controller
end

--- Remove a controller record along with its per-surface index entry
--- @param unit_number uint
function helpers.remove_controller(unit_number)
    local controller = storage.controllers[unit_number]
    if not controller then
        return
    end

    storage.controllers[unit_number] = nil

    local by_surface = storage.controllers_by_surface
    local surface_controllers = by_surface and controller.surface_index and by_surface[controller.surface_index]
    if surface_controllers then
        surface_controllers[unit_number] = nil
        if next(surface_controllers) == nil then
            by_surface[controller.surface_index] = nil
        end
    end

    -- The sweep may not continue iterating from a removed key
    local pointers = storage.next_controller_by_surface
    if pointers and controller.surface_index and pointers[controller.surface_index] == unit_number then
        pointers[controller.surface_index] = nil
    end
end

--- Find the controller of the chain that contains this Nixie Tube by walking east.
--- @param unit_number uint?
--- @return NixieTubeController?
function helpers.find_chain_controller(unit_number)
    while unit_number do
        local controller = storage.controllers[unit_number]
        if controller then
            return controller
        end

        -- Find the display to the east, i.e. the one that feeds this one
        --- @type uint?
        local eastern_unit_number
        for other_unit_number, other_display in pairs(storage.displays) do
            if other_display.next_display == unit_number then
                eastern_unit_number = other_unit_number
                break
            end
        end

        unit_number = eastern_unit_number
    end
end

--- Invalidate all controller caches (total digits and last drawn value), so that every display
--- recalculates on its next update even when the signal value is unchanged
function helpers.invalidate_all_controller_caches()
    for _, controller in pairs(storage.controllers) do
        controller.total_digits = nil
        controller.previous_value = nil
    end
end

return helpers
