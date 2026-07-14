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

---@type Vector
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

---@type Sprite
common.empty_sprite = {
    filename = "__UPSFriendlyNixieTubeDisplay__/graphics/empty.png",
    width = 1,
    height = 1,
    frame_count = 1,
    shift = common.empty_vector,
}

---@type Sprite4Way
common.empty_sprites = {
    north = common.empty_sprite,
    east = common.empty_sprite,
    south = common.empty_sprite,
    west = common.empty_sprite,
}

---@type LightDefinition
common.empty_light = {
    intensity = 0,
    size = 0,
}

---@type WirePosition
common.empty_wire_position = {
    copper = common.empty_vector,
    red = common.empty_vector,
    green = common.empty_vector,
}

---@type WireConnectionPoint
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

--- Build the hidden arithmetic combinator whose operation glyphs render a Nixie Tube's digit.
--- Setting the combinator's operation selects which digit sprite the engine draws
--- @param name string The Nixie Tube entity name
--- @param icon string
--- @param build_sprite fun(character: string): Sprite4Way
--- @return ArithmeticCombinatorPrototype
function common.digit_sprite_entity(name, icon, build_sprite)
    return {
        type                           = "arithmetic-combinator",
        name                           = name .. "-sprite",
        icon                           = icon,
        icon_size                      = 32,
        hidden                         = true,
        flags                          = {
            "placeable-off-grid",
            "not-repairable",
            "not-on-map",
            "not-deconstructable",
            "not-blueprintable",
            "hide-alt-info",
            "not-flammable",
            "not-selectable-in-game",
            "not-in-kill-statistics",
            "not-in-made-in",
        },
        max_health                     = 1,
        order                          = "z[zebra]",

        energy_source                  = {
            type = "void",
            usage_priority = "secondary-input",
            render_no_network_icon = false,
            render_no_power_icon = false
        },
        active_energy_usage            = "1W",

        sprites                        = common.empty_sprites,
        activity_led_sprites           = common.empty_sprites,
        activity_led_light             = common.empty_light,
        activity_led_light_offsets     = common.empty_offsets,
        screen_light                   = common.empty_light,
        screen_light_offsets           = common.empty_offsets,

        minus_symbol_sprites           = build_sprite("-"),
        multiply_symbol_sprites        = build_sprite("0"),
        plus_symbol_sprites            = build_sprite("1"),
        divide_symbol_sprites          = build_sprite("2"),
        modulo_symbol_sprites          = build_sprite("3"),
        power_symbol_sprites           = build_sprite("4"),
        left_shift_symbol_sprites      = build_sprite("5"),
        right_shift_symbol_sprites     = build_sprite("6"),
        and_symbol_sprites             = build_sprite("7"),
        or_symbol_sprites              = build_sprite("8"),
        xor_symbol_sprites             = build_sprite("9"),

        input_connection_bounding_box  = common.empty_bounding_box,
        input_connection_points        = common.empty_wire_connection_points,
        output_connection_bounding_box = common.empty_bounding_box,
        output_connection_points       = common.empty_wire_connection_points,

        circuit_wire_max_distance      = 0,
    }
end

return common
