local helpers = {}

local entity_names_set = {
    ['classic-nixie-tube'] = true,
    ['reinforced-nixie-tube'] = true,
    ['small-reinforced-nixie-tube'] = true
}

--- @param entity LuaEntity
--- @return boolean
function helpers.is_nixie_tube(entity)
    return entity_names_set[entity.name] == true
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
            control_behavior = nil,
            previous_signal = nil,
            previous_value = nil
        }
        storage.controllers[nixie_tube.unit_number] = controller
    end

    for k, v in pairs(data or {}) do
        controller[k] = v
    end

    return controller
end

--- Invalidate all controller caches (total_digits)
function helpers.invalidate_all_controller_caches()
    for _, controller in pairs(storage.controllers) do
        controller.total_digits = nil
    end
end

return helpers
