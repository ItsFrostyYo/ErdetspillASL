# Erdetspill Autosplitter

This repo contains the Uhara-based LiveSplit autosplitter for the `erdetspill` process.

- Release script: `asl/Erdetspill.asl`
- Script version: `1.0.0 (Uhara10)`

## What It Does

- **Start**: starts when the game's own speedrun timer starts at the beginning of a run
- **Reset**: fully resets LiveSplit when the in-game timer resets, then starts the fresh run
- **In-game time**: matches the game's authoritative speedrun timer to the displayed centisecond
- **Timer pauses**: pauses whenever the game's timer pauses, including death and alternate-world puzzle/minigame sections
- **Quest splits**: optionally splits when supported quests are unlocked
- **End split**: splits only when the real ending sequence starts after returning to Grandpa

## Supported Split Types

### Quest unlocks

These split when the corresponding quest is unlocked, and only if their setting is enabled:

- `Redeem the Inheritance Document - ARVEDOKUMENTET`
- `Buy Ice Cream - KJØP IS`
- `Return to Grandpa - TILBAKE TIL BESTEFAR`
- `Apply for a Scholarship - STIPEND`
- `Return to the Bank - TILBAKE TIL BANKEN`
- `Buy the Last Ice Cream - EN IS TIL`
- `Slaughter in the Name of Gravel - SLAKT I GRUSENS NAVN`
- `Return Kristoffer's Cap - CAPSEN TIL KRISTOFFER`
- `Restore the Power - INGEN STRØM`
- `Deliver the Ice Cream - LEVER ISEN`

### End split

- `Finish the Game - LEVER ISEN (END)`

The end split uses the game's ending-sequence state. A normal timer pause, such as dying and entering the alternate-world puzzle/minigame area, does **not** trigger it.

## Timer Behavior

The autosplitter follows the game's own `SpeedrunTimer`:

- LiveSplit starts when the timer begins from the first second of a fresh run
- LiveSplit pauses when the timer is not advancing
- LiveSplit resumes when the timer continues
- an in-game restart performs a full LiveSplit reset and begins a new attempt
- the displayed Game Time is truncated to centiseconds in the same way as the in-game timer

This keeps the LiveSplit timer synchronized with the game's timer instead of estimating load times separately.

## Settings

The LiveSplit settings are grouped like this:

### Quest Unlocks

- `Redeem the Inheritance Document - ARVEDOKUMENTET`
- `Buy Ice Cream - KJØP IS`
- `Return to Grandpa - TILBAKE TIL BESTEFAR`
- `Apply for a Scholarship - STIPEND`
- `Return to the Bank - TILBAKE TIL BANKEN`
- `Buy the Last Ice Cream - EN IS TIL`
- `Slaughter in the Name of Gravel - SLAKT I GRUSENS NAVN`
- `Return Kristoffer's Cap - CAPSEN TIL KRISTOFFER`
- `Restore the Power - INGEN STRØM`
- `Deliver the Ice Cream - LEVER ISEN`

Each setting enables or disables its corresponding quest-unlock split.

### End

- `Finish the Game - LEVER ISEN (END)`

This setting enables or disables the final ending split independently of the quest splits.

Only enabled settings are active.

## In-Game Time

This autosplitter uses LiveSplit `Game Time` and supplies it directly from Erdetspill's in-game speedrun timer.

Compare against **Game Time** in LiveSplit to display the same time as the game.

## Uhara

This autosplitter depends on the unmodified `uhara10` component.

The required component is included in this repo:

- `Components/uhara10`

If LiveSplit does not already place or load it correctly, put `uhara10` in your LiveSplit `Components` folder.

The Erdetspill-specific Godot memory reader is contained inside the ASL and compiled in memory by LiveSplit. It does not modify Uhara10.

If the autosplitter stops working, the usual causes are:

- `uhara10` is missing
- the game updated and the Godot memory layout changed
- the Scriptable Auto Splitter component is not pointing to `asl/Erdetspill.asl`

## Compatibility

- Game version: `1.1.2`
- Godot version: `4.6.2`
- Process: `erdetspill`
- Platform: Windows

## License

MIT License. See [LICENSE](./LICENSE).

## Disclaimer

This is a fan-made speedrunning tool and is not affiliated with the developers of Erdetspill.
