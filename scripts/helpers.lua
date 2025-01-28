local helpers = {}

local entity_names = {
    'classic-nixie-tube',
    'reinforced-nixie-tube',
    'small-reinforced-nixie-tube',
    'million-reinforced-nixie-tube'
}

---Determine if a table with contiguous keys has the given value.
---@param table table
---@return boolean
function helpers.table_contains(table, value)
    for i = 1, #table do
        if table[i] == value then
            return true
        end
    end
    return false
end

--- @param entity LuaEntity
--- @return boolean
function helpers.is_nixie_tube(entity)
    return helpers.table_contains(entity_names, entity.name)
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
            signal = nil,
            last_value = nil
        }
        storage.controllers[nixie_tube.unit_number] = controller
    end

    for k, v in pairs(data or {}) do
        controller[k] = v
    end

    return controller
end

return helpers
