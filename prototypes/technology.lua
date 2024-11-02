require 'util'

data:extend({
  {
    type = "technology",
    name = "SNTD-nixie-tubes-1",
    icon = "__UPSFriendlyNixieTubeDisplay__/graphics/old-nixie-technology-icon.png",
    icon_size = 32,
    unit = {
      count = 2 * util.table.deepcopy(data.raw["technology"]["circuit-network"].unit.count),
      time = util.table.deepcopy(data.raw["technology"]["circuit-network"].unit.time),
      ingredients = util.table.deepcopy(data.raw["technology"]["circuit-network"].unit.ingredients),
    },
    prerequisites = {
      "circuit-network"
    },
    effects = {
      {
        type = "unlock-recipe",
        recipe = "SNTD-old-nixie-tube"
      },
    },
    -- TODO: Figure out why `.order` is not working
    order = (data.raw["technology"]["circuit-network"].order or "") .. "[SNTD]-a[regular]"
  },
  {
    type = "technology",
    name = "SNTD-nixie-tubes-2",
    icon = "__UPSFriendlyNixieTubeDisplay__/graphics/nixie-technology-icon.png",
    icon_size = 32,
    unit = {
      count = 3 * util.table.deepcopy(data.raw["technology"]["circuit-network"].unit.count),
      time = util.table.deepcopy(data.raw["technology"]["circuit-network"].unit.time),
      ingredients = util.table.deepcopy(data.raw["technology"]["circuit-network"].unit.ingredients),
    },
    prerequisites = {
      "SNTD-nixie-tubes-1"
    },
    effects = {
      {
        type = "unlock-recipe",
        recipe = "SNTD-nixie-tube"
      },
      {
        type = "unlock-recipe",
        recipe = "SNTD-nixie-tube-small"
      }
    },
    order = (data.raw["technology"]["circuit-network"].order or "") .. "[SNTD]-b[reinforced]"
  }
})
