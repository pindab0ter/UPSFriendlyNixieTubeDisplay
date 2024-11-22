require "util"
require "lib.prototyping.circuit-network"

local shift_digit = { x = -1 / 32, y = -20 / 32 }
local arrow_box = { { -.5, 1 }, { 0.5, 1 } }

circuit_connector_definitions["SNTD-old-nixie-tube"] = circuit_connector_definitions.create_scaled(
    universal_connector_template,
    { variation = 27, main_offset = util.by_pixel(5, 24), shadow_offset = util.by_pixel(4, 24), show_shadow = true }
)

local function SNTD_old_nixie_tube_sprite_getNumber(value)
    local function getNumberOrientation(value)
        local orientation = {
            filename = "__UPSFriendlyNixieTubeDisplay__/graphics/old-nixie-tube/" .. value .. ".png",
            width = 27,
            height = 45,
            scale = 1,
            shift = { x = 0, y = -0.5 },
        }

        return util.table.deepcopy(orientation)
    end

    return util.table.deepcopy({
        north = getNumberOrientation(value),
        east  = getNumberOrientation(value),
        south = getNumberOrientation(value),
        west  = getNumberOrientation(value),
    })
end

local spriteList = {
    ["0"] = "0.png",
    ["1"] = "1.png",
    ["2"] = "2.png",
    ["3"] = "3.png",
    ["4"] = "4.png",
    ["5"] = "5.png",
    ["6"] = "6.png",
    ["7"] = "7.png",
    ["8"] = "8.png",
    ["9"] = "9.png",
    ["-"] = "-.png",
    ["off"] = "off.png", -- unused
}

for key, value in pairs(spriteList) do
    data:extend {
        {
            type = "sprite",
            name = "SNTD-old-nixie-tube-" .. key,
            filename = "__UPSFriendlyNixieTubeDisplay__/graphics/old-nixie-tube/" .. value,
            width = 27,
            height = 45,
        } --- @as data.Sprite
    }
end

local emptySprite = {
    filename = "__UPSFriendlyNixieTubeDisplay__/graphics/empty.png",
    width = 1,
    height = 1,
    frame_count = 1,
    shift = { 0, 0 }
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
        collision_box = { { -.49, -.45 }, { .49, .45 } },
        selection_box = { { -.5, -.5 }, { .5, .5 } },
        flags = { "placeable-neutral", "player-creation", "not-on-map" },
        minable = { hardness = 0.2, mining_time = 0.5, result = "SNTD-old-nixie-tube" },
        max_health = 55,
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
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = { 0, 0 }
        },
        picture_off = {
            filename = "__UPSFriendlyNixieTubeDisplay__/graphics/old-nixie-tube-base.png",
            priority = "high",
            width = 64,
            height = 55,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = { 16 / 32, -13 / 32 }
        },
        energy_usage_per_tick = "4kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
        },
        light = { intensity = 0.0, size = 0, color = { r = 1, g = .6, b = .3, a = 0 } },
        -- circuit_connector = circuit_connector_definitions["SNTD-old-nixie-tube"],
        circuit_wire_max_distance = 7.5,
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
        flags                          = { "placeable-neutral", "placeable-off-grid", "hide-alt-info", "not-blueprintable", "not-deconstructable" },
        minable                        = { hardness = 0.2, mining_time = 0.5, result = "SNTD-old-nixie-tube" },
        max_health                     = 100,
        order                          = "z[zebra]",
        corpse                         = "small-remnants",
        collision_box                  = { { -.49, -.45 }, { .49, .45 } },
        selection_box                  = { { 0, -.5 }, { 0, -.5 } },

        energy_source                  = {
            type = "void",
            usage_priority = "secondary-input",
            render_no_network_icon = false,
            render_no_power_icon = false
        },
        active_energy_usage            = "1W",

        working_sound                  = {
            sound = {
                filename = "__base__/sound/combinator.ogg",
                volume = 0,
            },
            max_sounds_per_type = 1,
            match_speed_to_activity = true,
        },

        vehicle_impact_sound           = {
            filename = "__base__/sound/car-metal-impact.ogg",
            volume = 0.65
        },

        -- base of the nixie tube
        sprites                        = {
            north = emptySprite,
            east  = emptySprite,
            south = emptySprite,
            west  = emptySprite,
        },

        activity_led_sprites           = {
            north = emptySprite,
            east  = emptySprite,
            south = emptySprite,
            west  = emptySprite,
        },

        activity_led_light             = {
            intensity = 0,
            size = 1,
            color = { r = 1.0, g = 1.0, b = 1.0 }
        },

        activity_led_light_offsets     = {
            { 0, 0 },
            { 0, 0 },
            { 0, 0 },
            { 0, 0 }
        },

        screen_light                   = {
            intensity = 0.3,
            size = 0.6,
            color = { r = 1.0, g = 1.0, b = 1.0 }
        },

        screen_light_offsets           = {
            { 0.015625, -0.234375 },
            { 0.015625, -0.296875 },
            { 0.015625, -0.234375 },
            { 0.015625, -0.296875 }
        },

        minus_symbol_sprites           = SNTD_old_nixie_tube_sprite_getNumber("-"),
        multiply_symbol_sprites        = SNTD_old_nixie_tube_sprite_getNumber("0"),
        plus_symbol_sprites            = SNTD_old_nixie_tube_sprite_getNumber("1"),
        divide_symbol_sprites          = SNTD_old_nixie_tube_sprite_getNumber("2"),
        modulo_symbol_sprites          = SNTD_old_nixie_tube_sprite_getNumber("3"),
        power_symbol_sprites           = SNTD_old_nixie_tube_sprite_getNumber("4"),
        left_shift_symbol_sprites      = SNTD_old_nixie_tube_sprite_getNumber("5"),
        right_shift_symbol_sprites     = SNTD_old_nixie_tube_sprite_getNumber("6"),
        and_symbol_sprites             = SNTD_old_nixie_tube_sprite_getNumber("7"),
        or_symbol_sprites              = SNTD_old_nixie_tube_sprite_getNumber("8"),
        xor_symbol_sprites             = SNTD_old_nixie_tube_sprite_getNumber("9"),

        input_connection_bounding_box  = arrow_box,
        input_connection_points        = {
            {
                shadow = {
                    red = { 22.5 / 32, 23.5 / 32 },
                    green = { 18.5 / 32, 28.5 / 32 },
                },
                wire = {
                    red = { 12 / 32, 23 / 32 },
                    green = { 12 / 32, 28 / 32 },
                }
            },
            {
                shadow = {
                    red = { 22.5 / 32, 23.5 / 32 },
                    green = { 18.5 / 32, 28.5 / 32 },
                },
                wire = {
                    red = { 12 / 32, 23 / 32 },
                    green = { 12 / 32, 28 / 32 },
                }
            },
            {
                shadow = {
                    red = { 22.5 / 32, 23.5 / 32 },
                    green = { 18.5 / 32, 28.5 / 32 },
                },
                wire = {
                    red = { 12 / 32, 23 / 32 },
                    green = { 12 / 32, 28 / 32 },
                }
            },
            {
                shadow = {
                    red = { 22.5 / 32, 23.5 / 32 },
                    green = { 18.5 / 32, 28.5 / 32 },
                },
                wire = {
                    red = { 12 / 32, 23 / 32 },
                    green = { 12 / 32, 28 / 32 },
                }
            }
        },

        output_connection_bounding_box = arrow_box,
        output_connection_points       = {
            {
                shadow = {
                    red = { 22.5 / 32, 23.5 / 32 },
                    green = { 18.5 / 32, 28.5 / 32 },
                },
                wire = {
                    red = { 12 / 32, 23 / 32 },
                    green = { 12 / 32, 28 / 32 },
                }
            },
            {
                shadow = {
                    red = { 22.5 / 32, 23.5 / 32 },
                    green = { 18.5 / 32, 28.5 / 32 },
                },
                wire = {
                    red = { 12 / 32, 23 / 32 },
                    green = { 12 / 32, 28 / 32 },
                }
            },
            {
                shadow = {
                    red = { 22.5 / 32, 23.5 / 32 },
                    green = { 18.5 / 32, 28.5 / 32 },
                },
                wire = {
                    red = { 12 / 32, 23 / 32 },
                    green = { 12 / 32, 28 / 32 },
                }
            },
            {
                shadow = {
                    red = { 22.5 / 32, 23.5 / 32 },
                    green = { 18.5 / 32, 28.5 / 32 },
                },
                wire = {
                    red = { 12 / 32, 23 / 32 },
                    green = { 12 / 32, 28 / 32 },
                }
            }
        },

        circuit_wire_max_distance      = 9
    }
}
