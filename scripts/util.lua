local util = {}

local entity_names = {
    'SNTD-old-nixie-tube',
    'SNTD-nixie-tube',
    'SNTD-nixie-tube-small'
}

---@param table table
---@return boolean
function util.table_contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

--- @param entity LuaEntity
--- @return boolean
function util.is_nixie_tube(entity)
    return util.table_contains(entity_names, entity.name)
end

--- @param entity LuaEntity
--- @return SignalID?
function util.get_selected_signal(entity)
    local control_behavior = entity.get_control_behavior()

    return control_behavior
        and control_behavior.circuit_condition
        and control_behavior.circuit_condition.first_signal
        or nil
end

--- @param nixie_tube LuaEntity
--- @param data table?
--- @return NixieTubeDisplay
function util.storage_set_display(nixie_tube, data)
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
function util.storage_set_controller(nixie_tube, data)
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

return util
