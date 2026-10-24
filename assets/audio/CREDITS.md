# Audio credits

## Generated sounds

These are synthesized by `tools/audio/synth_sounds.py` (D25, D50): Python's standard library only,
with a fixed seed, so running the script again writes the same bytes. They are part of the project,
under its own licence; nothing was downloaded or recorded. Every file is 16-bit, 22050 Hz, mono.
To change one, edit the script and run it again (`py -3 tools/audio/synth_sounds.py`). The script
then reads every file back and checks its length and peak level, and that each loop joins itself
without a click. The two loops carry their loop points in the file (a `smpl` chunk), so Godot
imports them looping in any checkout.

| File | What it is | Length | Peak |
|---|---|---|---|
| `blip.wav` | the voice blip of the dead; the game pitches it per soul (D41) | 40 ms | -14 dBFS |
| `pin_tack.wav` | a pin pushed into parchment | 30 ms | -6 dBFS |
| `thread_pull.wav` | a thread drawn taut | 120 ms | -6 dBFS |
| `no_seam_tick.wav` | a pin with no seam | 60 ms | -6 dBFS |
| `horn.wav` | the horn at the end of the day | 1.2 s | -6 dBFS |
| `caw.wav` | the dry caw of the black feather on a citation (D16) | 150 ms | -6 dBFS |
| `page_turn.wav` | a page of the day-book turned (D22) | 120 ms | -12 dBFS |
| `drone.wav` | the low drone under the open day-book (D22); a loop | 4 s | -14 dBFS |
| `wind.wav` | the wind over the title (D24); a loop | 6 s | -18 dBFS |

## Kenney's sounds

Two sounds are **CC0 1.0** (public domain), by Kenney (www.kenney.nl). Credit is appreciated, not
required. Downloaded on 2026-10-21 from the official site.

| File | Source pack | Original file | Pack page |
|---|---|---|---|
| `stamp_thud.ogg` | Impact Sounds 1.0 | `Audio/impactWood_heavy_000.ogg` | https://kenney.nl/assets/impact-sounds |
| `seam_found.ogg` | Interface Sounds 1.0 | `Audio/confirmation_002.ogg` | https://kenney.nl/assets/interface-sounds |

Each pack's own `License.txt` reads: "License: (Creative Commons Zero, CC0)
http://creativecommons.org/publicdomain/zero/1.0/ — This content is free to use in personal,
educational and commercial projects." Both licence files are reproduced in `kenney-LICENSE.txt`; the CC0 legal code is in
`../fonts/m5x7-LICENSE.txt`.

No other audio ships with the game.
