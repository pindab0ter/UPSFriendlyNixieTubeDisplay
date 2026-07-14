require("util")
local common = require("common")

local connector_definition = circuit_connector_definitions.create_single(
    belt_connector_template,
    {
        variation = 1,
        main_offset = util.by_pixel(0, 0),
        shadow_offset = util.by_pixel(0, 0),
        show_shadow = true,
    }
) --[[@as { sprites: table, points: table }]]

local function build_sprite(character)
    local orientation = {
        filename = "__UPSFriendlyNixieTubeDisplay__/graphics/classic-nixie-tube-numbers.png",
        width = 27,
        height = 45,
        scale = 1,
        shift = { x = 0, y = -0.5 },
        x = 0,
        y = 45 * common.sprite_positions[character],
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
        name = "classic-nixie-tube",
        enabled = false,
        energy_required = 3,
        ingredients = {
            { type = "item", name = "electronic-circuit", amount = 1 },
            { type = "item", name = "iron-plate",         amount = 2 },
            { type = "item", name = "copper-cable",       amount = 10 },
        },
        results = {
            { type = "item", name = "classic-nixie-tube", amount = 1 }
        },
    },
    {
        type = "item",
        name = "classic-nixie-tube",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/classic-nixie-tube-icon.png",
        icon_size = 32,
        subgroup = "circuit-network",
        order = "a[lamp]-b[nixie-tube]-a[classic]",
        place_result = "classic-nixie-tube",
        stack_size = 50
    },
    {
        type = "lamp",
        name = "classic-nixie-tube",
        order = "z[zebra]",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/classic-nixie-tube-icon.png",
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
            hardness = 0.1,
            mining_time = 0.5,
            result = "classic-nixie-tube"
        },
        max_health = 35,
        resistances = {
            {
                type = "fire",
                decrease = 0,
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
            filename = "__UPSFriendlyNixieTubeDisplay__/graphics/classic-nixie-tube-base.png",
            priority = "high",
            width = 64,
            height = 55,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(16, -13),
        },
        always_on = true,
        energy_usage_per_tick = "4kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
        },
        light = common.empty_light,
        circuit_connector = {
            sprites = connector_definition.sprites,
            points = {
                wire = {
                    green = util.by_pixel_hr(17, 13),
                    red = util.by_pixel_hr(17, 13),
                },
                shadow = {
                    green = util.by_pixel_hr(22, 20),
                    red = util.by_pixel_hr(22, 20),
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
    common.digit_sprite_entity("classic-nixie-tube", "__UPSFriendlyNixieTubeDisplay__/graphics/classic-nixie-tube-icon.png", build_sprite)
}
