require("util")
local common = require("common")

circuit_connector_definitions["reinforced-nixie-tube"] = circuit_connector_definitions.create_single(
    universal_connector_template,
    {
        variation = 26,
        main_offset = util.by_pixel(2, 22.0),
        shadow_offset = util.by_pixel(2, 22.0),
        show_shadow = true
    }
)

local function build_sprite(character)
    local orientation = {
        filename = "__UPSFriendlyNixieTubeDisplay__/graphics/reinforced-nixie-tube-numbers.png",
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
        name = "reinforced-nixie-tube",
        enabled = false,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "classic-nixie-tube", amount = 1 },
            { type = "item", name = "steel-plate",        amount = 3 },
            { type = "item", name = "iron-stick",         amount = 10 },
        },
        results = {
            { type = "item", name = "reinforced-nixie-tube", amount = 1 }
        }
    },
    {
        type = "item",
        name = "reinforced-nixie-tube",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/reinforced-nixie-tube-icon.png",
        icon_size = 32,
        subgroup = "circuit-network",
        order = "a[lamp]-b[nixie-tube]-b[reinforced]",
        place_result = "reinforced-nixie-tube",
        stack_size = 50
    },
    {
        type = "lamp",
        name = "reinforced-nixie-tube",
        order = "z[zebra]",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/reinforced-nixie-tube-icon.png",
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
            result = "reinforced-nixie-tube"
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
            filename = "__UPSFriendlyNixieTubeDisplay__/graphics/reinforced-nixie-tube-base.png",
            priority = "high",
            width = 40,
            height = 64,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(4, 0)
        },
        always_on = true,
        energy_usage_per_tick = "4kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
        },
        light = common.empty_light,
        circuit_connector = circuit_connector_definitions["reinforced-nixie-tube"],
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
    common.digit_sprite_entity("reinforced-nixie-tube", "__UPSFriendlyNixieTubeDisplay__/graphics/reinforced-nixie-tube-icon.png", build_sprite)
}
