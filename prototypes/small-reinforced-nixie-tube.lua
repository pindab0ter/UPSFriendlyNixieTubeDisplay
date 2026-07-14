require("util")
local common = require("common")

local connector_definition = circuit_connector_definitions.create_single(
    belt_connector_template,
    {
        variation = 1,
        main_offset = util.by_pixel(1, -29),
        shadow_offset = util.by_pixel(19, -8),
        show_shadow = true,
    }
) --[[@as { sprites: table, points: table }]]

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
                decrease = 0,
                percent = 100
            },
            {
                type = "physical",
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
            filename = "__UPSFriendlyNixieTubeDisplay__/graphics/small-reinforced-nixie-tube-base.png",
            priority = "high",
            width = 48,
            height = 42,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(8, -6),
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
    common.digit_sprite_entity("small-reinforced-nixie-tube", "__UPSFriendlyNixieTubeDisplay__/graphics/small-reinforced-nixie-tube-icon.png", build_sprite)
}
