## Must

- [ ] Use new GUI on ghosts

## Should

- [ ] New art

## Could

- [ ] Add sound on open/close GUI
  - [ ] Find out how to trigger close_sound
  - [ ] Add open sound only when opening GUI
- [ ] Prevent opening the GUI again if it is already open

## Won't

- Improve performance of configure_nixie_tube: it only runs on placement/removal, and the bookkeeping for
  targeted invalidation (a previous_display backpointer) costs more in code than the scan costs in runtime
