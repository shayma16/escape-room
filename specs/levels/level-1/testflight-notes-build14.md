# TestFlight — Within 1.0 (build 14)

## What to Test

- **Potion room — the cauldron.** The fire should sit properly in the stone hearth and lick
  the sides of the pot. Previously the flame art was drawn in the wrong place, showing as a
  bright rectangular patch on the wall to the left of the cauldron.
- **Sun/moon cabinet — after placing the ring and coin.** The gold ring and silver coin should
  seat neatly into their carved sun and moon recesses on the doors (same misplacement bug,
  not previously reported).
- **Screen edges, every scene.** The blurry/stretched smearing along the top, bottom and sides
  is gone. Edges now fade cleanly into darkness. Please check the desk, the caged-crow door,
  the potion room, the astrolabe room, the cellar, and the fireplace room.
- Everything fixed in build 13 should still work: items disappear from drawers/cabinets/barrel
  when you take them, the weight hooks onto the roped pulley hook, the rusted key can be looked
  at but not picked up, and the recipe page matches the brew.

## Known / deliberate

- Scene edges now fade to black rather than showing invented scenery. Generating real artwork
  for those edges was attempted twice and rejected both times, so the clean fade is the
  intended look.
