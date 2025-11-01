data:extend {
    {
        type = "int-setting",
        name = "nixie-tube-group-updates-per-tick",
        setting_type = "runtime-global",
        minimum_value = 1,
        default_value = 100,
        order = "nixie-tube-group-updates-per-tick",
    },
    {
        type = "bool-setting",
        name = "nixie-tube-enable-overflow-notation",
        setting_type = "runtime-global",
        default_value = true,
        order = "nixie-tube-enable-overflow-notation",
    },
}
