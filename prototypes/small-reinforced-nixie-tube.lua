require("util")
local common = require("common")

circuit_connector_definitions["small-reinforced-nixie-tube"] = circuit_connector_definitions.create_single(
    belt_connector_template,
    {
        variation = 1,
        main_offset = util.by_pixel(1, -29),
        shadow_offset = util.by_pixel(19, -8),
        show_shadow = true,
    }
)

local function build_sprite(character)
    local orientation = {
        filename = "__UPSFriendlyNixieTubeDisplay__/graphics/reinforced-nixie-tube-numbers.png",
        width = 20,
        height = 44,
        scale = 0.5,
        shift = util.by_pixel(-6, -4),
        x = 20 * common.sprite_positions[character],
        y = 0,
    }

    return util.table.deepcopy({
        north = orientation,
        east  = orientation,
        south = orientation,
        west  = orientation,
    })
end

data:extend {
    {
        type = "recipe",
        name = "small-reinforced-nixie-tube",
        enabled = false,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "reinforced-nixie-tube", amount = 2 },
            { type = "item", name = "steel-plate",           amount = 3 },
            { type = "item", name = "iron-stick",            amount = 10 },
        },
        results = {
            { type = "item", name = "small-reinforced-nixie-tube", amount = 1 }
        }
    },
    {
        type = "item",
        name = "small-reinforced-nixie-tube",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/small-reinforced-nixie-tube-icon.png",
        icon_size = 32,
        subgroup = "circuit-network",
        order = "a[lamp]-b[nixie-tube]-c[small]",
        place_result = "small-reinforced-nixie-tube",
        stack_size = 50
    },
    {
        type = "lamp",
        name = "small-reinforced-nixie-tube",
        order = "z[zebra]",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/small-reinforced-nixie-tube-icon.png",
        icon_size = 32,
        collision_box = {
            { x = -0.35, y = -0.35 },
            { x = 0.35,  y = 0.35 }
        },
        selection_box = {
            { x = -0.5, y = -0.5 },
            { x = 0.5,  y = 0.5 }
        },
        flags = { "placeable-neutral", "player-creation", "not-on-map" },
        minable = {
            hardness = 0.2,
            mining_time = 0.5,
            result = "small-reinforced-nixie-tube"
        },
        max_health = 200,
        resistances = {
            {
                type = "fire",
                percent = 100
            },
            {
                type = "physical",
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
            filename = "__UPSFriendlyNixieTubeDisplay__/graphics/small-reinforced-nixie-tube-base.png",
            priority = "high",
            width = 48,
            height = 42,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(8, -6),
        },
        energy_usage_per_tick = "4kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
        },
        light = common.empty_light,
        circuit_connector = {
            sprites = circuit_connector_definitions["small-reinforced-nixie-tube"].sprites,
            points = {
                wire = {
                    green = util.by_pixel(13.5, -19),
                    red = util.by_pixel(13, -25),
                },
                shadow = {
                    green = util.by_pixel(27, -8),
                    red = util.by_pixel(31, -8),
                },
            },
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
        name                           = "small-reinforced-nixie-tube-sprite",
        icon                           = "__UPSFriendlyNixieTubeDisplay__/graphics/small-reinforced-nixie-tube-icon.png",
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
        minable                        = { hardness = 0.0, mining_time = 0.0, result = "small-reinforced-nixie-tube" },
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
}
