local util = {}

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

--- @param nixie_tube LuaEntity
--- @param data table?
--- @return NixieTubeDisplay
function util.storage_set_display(nixie_tube, data)
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
