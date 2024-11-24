require("util")
local common = require("common")

circuit_connector_definitions["nixie-tube"] = circuit_connector_definitions.create_single(
    universal_connector_template,
    {
        variation = 26,
        main_offset = util.by_pixel(5.5, 24.0),
        shadow_offset = util.by_pixel(5.0, 24.0),
        show_shadow = true
    }
)

local function build_sprite(character)
    local orientation = {
        filename = "__UPSFriendlyNixieTubeDisplay__/graphics/nixie-tube-numbers.png",
        width = 20,
        height = 44,
        scale = 1,
        shift = util.by_pixel(0, -6),
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
        name = "SNTD-nixie-tube",
        enabled = false,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "SNTD-old-nixie-tube", amount = 1 },
            { type = "item", name = "steel-plate",         amount = 3 },
            { type = "item", name = "iron-stick",          amount = 10 },
        },
        results = {
            { type = "item", name = "SNTD-nixie-tube", amount = 1 }
        }
    },
    {
        type = "item",
        name = "SNTD-nixie-tube",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/nixie-tube-icon.png",
        icon_size = 32,
        subgroup = "circuit-network",
        order = "c-a-b",
        place_result = "SNTD-nixie-tube",
        stack_size = 50
    },
    {
        type = "lamp",
        name = "SNTD-nixie-tube",
        order = "z[zebra]",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/nixie-tube-icon.png",
        icon_size = 32,
        collision_box = {
            { x = -0.35, y = -0.85 },
            { x = 0.35,  y = 0.85 }
        },
        selection_box = {
            { -0.5, -1.0 },
            { 0.5,  1.0 }
        },
        flags = { "placeable-neutral", "player-creation", "not-on-map" },
        minable = {
            hardness = 0.2,
            mining_time = 0.5,
            result = "SNTD-nixie-tube"
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
            filename = "__UPSFriendlyNixieTubeDisplay__/graphics/nixie-tube-base.png",
            priority = "high",
            width = 40,
            height = 64,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(4, 0)
        },
        energy_usage_per_tick = "4kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
        },
        light = common.empty_light,
        circuit_connector = circuit_connector_definitions["nixie-tube"],
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
        name                           = "SNTD-nixie-tube-sprite",
        icon                           = "__UPSFriendlyNixieTubeDisplay__/graphics/nixie-tube-icon.png",
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
