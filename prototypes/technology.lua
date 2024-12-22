require 'util'

data:extend({
    {
        type = "technology",
        name = "classic-nixie-tubes",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/classic-nixie-tube-technology-icon.png",
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
                recipe = "classic-nixie-tube"
            },
        },
        order = (data.raw["technology"]["circuit-network"].order or "") .. "[nt]-a[classic]"
    },
    {
        type = "technology",
        name = "reinforced-nixie-tubes",
        icon = "__UPSFriendlyNixieTubeDisplay__/graphics/reinforced-nixie-tube-technology-icon.png",
        icon_size = 32,
        unit = {
            count = 3 * util.table.deepcopy(data.raw["technology"]["circuit-network"].unit.count),
            time = util.table.deepcopy(data.raw["technology"]["circuit-network"].unit.time),
            ingredients = util.table.deepcopy(data.raw["technology"]["circuit-network"].unit.ingredients),
        },
        prerequisites = {
            "classic-nixie-tubes"
        },
        effects = {
            {
                type = "unlock-recipe",
                recipe = "reinforced-nixie-tube"
            },
            {
                type = "unlock-recipe",
                recipe = "small-reinforced-nixie-tube"
            },
            {
                type = "unlock-recipe",
                recipe = "million-reinforced-nixie-tube"
            }
        },
        order = (data.raw["technology"]["circuit-network"].order or "") .. "[nt]-b[reinforced]"
    }
})
