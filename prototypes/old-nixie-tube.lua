require "util"
require "lib.prototyping.circuit-network"

local function build_sprite(value)
    local orientation = {
        filename = "__UPSFriendlyNixieTubeDisplay__/graphics/old-nixie-tube/" .. value .. ".png",
        width = 27,
        height = 45,
        scale = 1,
        shift = { x = 0, y = -0.5 },
    }

    return util.table.deepcopy({
        north = orientation,
        east  = orientation,
        south = orientation,
        west  = orientation,
    })
end

local empty_sprite = {
    filename = "__UPSFriendlyNixieTubeDisplay__/graphics/empty.png",
    width = 1,
    height = 1,
    frame_count = 1,
    shift = { 0, 0 }
}

local empty_light = {
    intensity = 0,
    size = 0,
}

data:extend {
    {
        type = "recipe",
        name = "SNTD-old-nixie-tube",
        enabled = false,
        energy_required = 3,
        ingredients = {
            { type = "item", name = "electronic-circuit", amount = 1 },
            { type = "item", name = "iron-plate",         amount = 2 },
            { type = "item", name = "copper-cable",       amount = 10 },
        },
        results = {
            { type = "item", name = "SNTD-old-nixie-tube", amount = 1 }
        },
    },
    {
        type = "item",
        name = "SNTD-old-nixie-tube",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/old-nixie-tube-icon.png",
        icon_size = 32,
        subgroup = "circuit-network",
        order = "c-a-a",
        place_result = "SNTD-old-nixie-tube",
        stack_size = 50
    },
    {
        type = "lamp",
        name = "SNTD-old-nixie-tube",
        order = "z[zebra]",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/old-nixie-tube/icon.png",
        icon_size = 32,
        selection_box = {
            { x = -0.5, y = -1.3 },
            { x = 0.5,  y = 0.5 }
        },
        flags = { "placeable-neutral", "player-creation", "not-on-map" },
        minable = {
            hardness = 0.1,
            mining_time = 0.5,
            result = "SNTD-old-nixie-tube"
        },
        max_health = 35,
        resistances = {
            {
                type = "fire",
                percent = 50
            },
        },
        corpse = "small-remnants",
        picture_on = {
            filename = "__UPSFriendlyNixieTubeDisplay__/graphics/empty.png",
            priority = "low",
            width = 1,
            height = 1,
        },
        picture_off = {
            filename = "__UPSFriendlyNixieTubeDisplay__/graphics/old-nixie-tube-base.png",
            priority = "high",
            width = 64,
            height = 55,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(16, -13),
        },
        energy_usage_per_tick = "4kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
        },
        light = empty_light,
        circuit_connector = {
            sprites = {
                led_red = empty_sprite,
                led_green = empty_sprite,
                led_blue = empty_sprite,
                led_light = empty_light,
            },
            points = {
                wire = {
                    green = util.by_pixel_hr(17, 13),
                    red = util.by_pixel_hr(17, 13),
                },
                shadow = {
                    green = util.by_pixel_hr(17, 25),
                    red = util.by_pixel_hr(17, 25),
                }
            }
        },
        circuit_wire_max_distance = 8,
        created_effect = {
            type = "direct",
            action_delivery = {
                type = "instant",
                source_effects = {
                    {
                        type = "script",
                        effect_id = "nixie-tube-created",
                    },
                }
            }
        },
        open_sound = { filename = "__base__/sound/open-close/electric-small-open.ogg" },
        close_sound = { filename = "__base__/sound/open-close/electric-small-close.ogg" },
    },
    {
        type                           = "arithmetic-combinator",
        name                           = "SNTD-old-nixie-tube-sprite",
        icon                           = "__UPSFriendlyNixieTubeDisplay__/graphics/old-nixie-tube-icon.png",
        icon_size                      = 32,
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
        minable                        = { hardness = 0.0, mining_time = 0.0, result = "SNTD-old-nixie-tube" },
        max_health                     = 1,
        order                          = "z[zebra]",

        energy_source                  = {
            type = "void",
            usage_priority = "secondary-input",
            render_no_network_icon = false,
            render_no_power_icon = false
        },
        active_energy_usage            = "1W",

        sprites                        = {
            north = empty_sprite,
            east  = empty_sprite,
            south = empty_sprite,
            west  = empty_sprite,
        },

        activity_led_sprites           = {
            north = empty_sprite,
            east  = empty_sprite,
            south = empty_sprite,
            west  = empty_sprite,
        },

        activity_led_light             = empty_light,
        activity_led_light_offsets     = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } },

        screen_light                   = empty_light,
        screen_light_offsets           = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } },

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

        input_connection_bounding_box  = { { 0, 0 }, { 0, 0 } },
        input_connection_points        = {
            { shadow = { red = { 0, 0 }, green = { 0, 0 }, }, wire = { red = { 0, 0 }, green = { 0, 0 }, } },
            { shadow = { red = { 0, 0 }, green = { 0, 0 }, }, wire = { red = { 0, 0 }, green = { 0, 0 }, } },
            { shadow = { red = { 0, 0 }, green = { 0, 0 }, }, wire = { red = { 0, 0 }, green = { 0, 0 }, } },
            { shadow = { red = { 0, 0 }, green = { 0, 0 }, }, wire = { red = { 0, 0 }, green = { 0, 0 }, } }
        },

        output_connection_bounding_box = { { 0, 0 }, { 0, 0 } },
        output_connection_points       = {
            { shadow = { red = { 0, 0 }, green = { 0, 0 }, }, wire = { red = { 0, 0 }, green = { 0, 0 }, } },
            { shadow = { red = { 0, 0 }, green = { 0, 0 }, }, wire = { red = { 0, 0 }, green = { 0, 0 }, } },
            { shadow = { red = { 0, 0 }, green = { 0, 0 }, }, wire = { red = { 0, 0 }, green = { 0, 0 }, } },
            { shadow = { red = { 0, 0 }, green = { 0, 0 }, }, wire = { red = { 0, 0 }, green = { 0, 0 }, } }
        },

        circuit_wire_max_distance      = 0,
    }
}
