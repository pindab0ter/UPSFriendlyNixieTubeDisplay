data:extend{
  {
		type = "int-setting",
		name = "nixie-tube-update-speed",
		setting_type = "runtime-global",
		minimum_value = 1,
		default_value = 100,
		order = "nixie-speed-numeric",
	},
  {
    -- Update frequency
    setting_type = "runtime-global",
    name =  "nixie-update-delay",
    type = "int-setting",
    default_value = 0,
    maximum_value = 600,
    minimum_value = 0,
    order = "z"
  }
}
