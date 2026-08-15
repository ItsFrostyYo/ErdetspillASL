# Erdetspill Autosplitter

A LiveSplit autosplitter for `erdetspill` using the game's own speedrun timer.

## Activate It in LiveSplit

1. Open LiveSplit and right-click the timer.
2. Select **Edit Splits**.
3. Set the game name to **erdetspill**.
4. Click **Activate** beside the autosplitter.
5. Click **Settings** to open settings.

## Features

- Starts with the game's speedrun timer.
- Resets LiveSplit when the game resets.
- Uses the game's exact in-game time.
- Pauses whenever the in-game timer pauses.
- Supports optional quest-unlock splits.
- Supports optional quest-completion splits.
- Splits at the game's dedicated ending signal.

Use **Game Time** in LiveSplit to display the same time as the game.

## Settings

### Quest Unlocks

These split when the quest is unlocked:

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

### Quest Completions

These split when the game marks the quest as completed:

- `Redeem the Inheritance Document - ARVEDOKUMENTET`
- `Buy Ice Cream - KJØP IS`
- `Return to Grandpa - TILBAKE TIL BESTEFAR`
- `Apply for a Scholarship - STIPEND`
- `Return to the Bank - TILBAKE TIL BANKEN`
- `Buy the Last Ice Cream - EN IS TIL`
- `Slaughter in the Name of Gravel - SLAKT I GRUSENS NAVN`
- `Return Kristoffer's Cap - CAPSEN TIL KRISTOFFER`
- `Restore the Power - INGEN STRØM`

### End

The End setting uses the game's actual ending signal.

- `Finish the Game - LEVER ISEN (END)`

### Additional Splits

Additional Splits for Things Specifically Added

- `Pick Up the Peak Performance Cap - PLUKK OPP CAPS`

Quest unlock and completion settings are disabled by default. The End setting
is enabled by default.

## Supported Game
Game version: `1.1.2`
Godot version: `4.6.2`
Platform: `Windows`

## How It Works

The ASL reads the game's timer and quest state. Unlock settings split when a
quest becomes active, completion settings split when the game records it as
completed, and End splits only when the real ending begins.

The autosplitter reads memory only. It does not modify the game or Uhara10.

## Files

- `asl/Erdetspill.asl`
- `Components/uhara10`

## License

MIT License. See [LICENSE](./LICENSE).
