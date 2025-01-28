common = {}

---@type table<string, number>
common.sprite_positions = {
    [" "] = 0,
    ["0"] = 1,
    ["1"] = 2,
    ["2"] = 3,
    ["3"] = 4,
    ["4"] = 5,
    ["5"] = 6,
    ["6"] = 7,
    ["7"] = 8,
    ["8"] = 9,
    ["9"] = 10,
    ["-"] = 11,
}

---@type data.Vector
common.empty_vector = { x = 0, y = 0 }

common.empty_bounding_box = {
    common.empty_vector,
    common.empty_vector,
}

common.empty_offsets = {
    common.empty_vector,
    common.empty_vector,
    common.empty_vector,
    common.empty_vector,
}

---@type data.Sprite
common.empty_sprite = {
    filename = "__UPSFriendlyNixieTubeDisplay__/graphics/empty.png",
    width = 1,
    height = 1,
    frame_count = 1,
    shift = common.empty_vector,
}

---@type data.Sprite4Way
common.empty_sprites = {
    north = common.empty_sprite,
    east = common.empty_sprite,
    south = common.empty_sprite,
    west = common.empty_sprite,
}

---@type data.LightDefinition
common.empty_light = {
    intensity = 0,
    size = 0,
}

---@type data.WirePosition
common.empty_wire_position = {
    copper = common.empty_vector,
    red = common.empty_vector,
    green = common.empty_vector,
}

---@type data.WireConnectionPoint
common.empty_wire_connection_point = {
    wire = common.empty_wire_position,
    shadow = common.empty_wire_position,
}

common.empty_wire_connection_points = {
    common.empty_wire_connection_point,
    common.empty_wire_connection_point,
    common.empty_wire_connection_point,
    common.empty_wire_connection_point,
}

return common
