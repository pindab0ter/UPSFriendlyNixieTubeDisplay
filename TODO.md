## Must

- [ ] Create custom GUI
  - [x] Get proof of concept working
  - [x] Create front end
  - [x] Handle GUI interactions
  - [ ] Prevent changing settings for non-rightmost signals to prevent confusion
    - [ ] Clear settings for nixie whenever they have a right neighbour
- [x] Rewrite rendering code
  - [ ] Add sprite caching back in
- [ ] Fix circuit connection visuals
- [x] Fix "Turned off during daytime" in popup on hover

## Should

- [ ] Improve sprite resolution
- [ ] Rename entities both in code and localisation
  - [ ] 'old nixie tube' to either 'nixie tube' or 'classic nixie tube'
  - [ ] 'nixie tube' to 'reinforced nixie tube'
  - [ ] Write migrations
- [ ] Improve phrasing and naming for settings
- [ ] Split up GUI and controller code

## Could

- [ ] Add sound on open/close GUI
  - [ ] Find out how to trigger close_sound
  - [ ] Add open sound only when opening GUI
- [ ] Prevent opening the GUI again if it is already open

## Won't
