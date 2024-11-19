require "util"
require "lib.prototyping.circuit-network"

local shift_digit = { x = -1 / 32, y = -20 / 32 }
local arrow_box = { { -.5, 1 }, { 0.5, 1 } }

circuit_connector_definitions["SNTD-old-nixie-tube"] = circuit_connector_definitions.create_scaled(
  universal_connector_template,
  { variation = 27, main_offset = util.by_pixel(5, 24), shadow_offset = util.by_pixel(4, 24), show_shadow = true }
)

local function SNTD_old_nixie_tube_sprite_getNumber(number)
  local function getNumberOrientation(number)
    local orientation = {}
    orientation.filename = "__UPSFriendlyNixieTubeDisplay__/graphics/old-nixie-tube-numbers.png"
    orientation.width = 27
    orientation.height = 45
    orientation.scale = 1
    orientation.shift = shift_digit
    orientation.x = 0
    orientation.y = orientation.height * (number + 1)

    return util.table.deepcopy(orientation)
  end

  return util.table.deepcopy({
    north = getNumberOrientation(number),
    east  = getNumberOrientation(number),
    south = getNumberOrientation(number),
    west  = getNumberOrientation(number),
  })
end

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
  }
}

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
  ["off"] = "off.png"
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
