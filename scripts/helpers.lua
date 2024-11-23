local helpers = {}

local entity_names = {
    'SNTD-old-nixie-tube',
    'SNTD-nixie-tube',
    'SNTD-nixie-tube-small'
}

---@param table table
---@return boolean
function helpers.table_contains(table, value)
    for _, v in pairs(table) do
        if v == value then
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
--- @return SignalID?
function helpers.get_selected_signal(nixie_tube)
    local control_behavior = nixie_tube.get_control_behavior() --[[@as LuaLampControlBehavior?]]

    if not control_behavior then
        return nil
    end

    return control_behavior
        .circuit_condition --[[@as CircuitCondition]]
        .first_signal
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
