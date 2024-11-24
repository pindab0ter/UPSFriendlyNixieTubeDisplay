## Must

- [x] Create custom GUI
  - [x] Get proof of concept working
  - [x] Create front end
  - [x] Handle GUI interactions
  - [x] Prevent changing settings for non-rightmost signals to prevent confusion
    - [x] Clear settings for Nixie Tube whenever they have a western neighbor
    - [x] Redraw Nixie Tube when adding a western neighbor
    - [x] Fix UI not responding on fresh save
- [x] Rewrite rendering code
  - [x] Add sprite caching back in
  - [x] Further improve performance if possible
  - [x] Fix z-fighting
- [x] Fix circuit connection visuals
- [x] Fix "Turned off during daytime" in popup on hover
- [x] Fix memory leak when removing Nixie Tubes
- [x] Implement small and big reinforced Nixie Tubes
- [x] Test upgrade to 2.0 path
- [x] Fix upgrade to 2.0 path

## Should

- [ ] Improve performance of configure_nixie_tube
- [ ] New art
- [x] Rename entities both in code and localisation
  - [x] 'Old Nixie Tube' to either 'Classic Nixie Tube'
  - [x] 'Nixie Tube' to 'Reinforced Nixie Tube'
  - [x] Write migrations
- [x] Improve phrasing and naming for settings
  - [x] Remove update_delay setting?
- [x] Figure out why activity light works for Classix Nixie Tube, but not the other ones
- [x] Split up GUI and controller code

## Could

- [ ] Add sound on open/close GUI
  - [ ] Find out how to trigger close_sound
  - [ ] Add open sound only when opening GUI
- [ ] Prevent opening the GUI again if it is already open
- [x] Show the Nixie Tube preview in the GUI with rendered digits

## Won't
