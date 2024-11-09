local handler = require("__core__.lualib.event_handler")

handler.add_libraries({
  require("__flib__.gui"),

  require("scripts.nixie_tube")
})
