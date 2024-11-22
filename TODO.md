## Must

- [x] Create custom GUI
  - [x] Get proof of concept working
  - [x] Create front end
  - [x] Handle GUI interactions
  - [x] Prevent changing settings for non-rightmost signals to prevent confusion
    - [x] Clear settings for Nixie Tube whenever they have a western neighbor
    - [x] Redraw Nixie Tube when adding a western neighbor
- [x] Rewrite rendering code
  - [x] Add sprite caching back in
  - [ ] Further improve performance if possible
  - [x] Fix z-fighting
- [x] Fix circuit connection visuals
- [x] Fix "Turned off during daytime" in popup on hover
- [x] Fix memory leak when removing Nixie Tubes
- [ ] Implement small and big reinforced Nixie Tubes

## Should

- [ ] Improve sprite resolution
- [ ] Rename entities both in code and localisation
  - [ ] 'Old Nixie Tube' to either 'Classic Nixie Tube'
  - [ ] 'Nixie Tube' to 'Reinforced Nixie Tube'
  - [ ] Write migrations
- [ ] Improve phrasing and naming for settings
- [x] Split up GUI and controller code

## Could

- [ ] Add sound on open/close GUI
  - [ ] Find out how to trigger close_sound
  - [ ] Add open sound only when opening GUI
- [ ] Prevent opening the GUI again if it is already open

## Won't
