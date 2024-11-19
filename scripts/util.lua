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

return util
