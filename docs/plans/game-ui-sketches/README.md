# Game UI sketches: forks S1 and S2

Layout sketches for comparing options by eye. Each one is drawn over a real 1:1 capture of the
slice (480×270), uses only `docs/art/palette.gpl` colours, and sets its text in m5x7 at size 16 with
no anti-aliasing (ADR-0008). Every `-x3` file is the same image scaled ×3 (nearest neighbour), with
a 12 px strip underneath that names the option.

Re-run: `py -3 docs/plans/game-ui-sketches/draw_sketches.py [SHOTS_DIR]`. SHOTS_DIR is the folder of
slice captures (`05_law_thread.png`, `16_dusk1_card1.png`, `20_dawn2.png`, `30_dusk3_card5.png`,
`02_ulf.png`). It falls back to `$VI_SHOTS`, then to the session folder the captures were taken
into. The script stops if any output pixel is outside the palette.

Content notes:
- The witness sheets borrow Bersi's lines from Freydis's encounter, because Ulf has no witness on day 1.
- S2-C's citation is illustrative: day 1 has no citations. Its recap (Kolbeinn) comes from dusk 1, and Hel's letter comes from dusk 2.

| File | What it shows |
|---|---|
| `S1-A.png` / `S1-A-x3.png` | Parchment and ink: torn saga sheets headed by the speaker, hanging quotes, Odin's Law as a scroll with knotwork rods and roman numerals, an ember seal on the newest decree, a pinned 2 px thread, the caption as a ledger page edge, the HUD as candle/quill/slate/book, a writ and a stamp under the doors. |
| `S1-B.png` / `S1-B-x3.png` | Carved stone: claim and witness as dark tablets with a Fog 1 groove, the Law as a round-topped rune stone, the caption chalked on a framed slate, the HUD carved into the wall, and the same pins and thread. |
| `S1-C.png` / `S1-C-x3.png` | Papers, Please literal: stacked typed slips (claim and witness), the rulebook with its LAW tab open over them, the caption as a slip tied to the thread, and a tray of three realm stamps (spear, serpent, boar) in place of door clicks. |
| `S1-compare-x3.png` | S1-A, S1-B and S1-C stacked at ×3. |
| `S2-A-dusk.png` / `-x3` | The clerk's ledger: the desk dimmed with only the two doors lit, a candle, the dusk written on the left page, a Skip all ribbon at the top and a "turn" dog-ear in place of Next. |
| `S2-A-dawn.png` / `-x3` | The clerk's ledger at dawn, day 2: the briefing on the left page, the new decree IV with its seal on the right, and a "begin" dog-ear. |
| `S2-A-ending.png` / `-x3` | The ledger's last page: Hel's tide and its outcome, a row per soul marked tick / black feather / frost (returned), the standing as an ember seal with "13 feathers", and a Play again ribbon. |
| `S2-B-dusk.png` / `-x3` | Title cards: everything goes to Night 0 except the two glowing doors; "Dusk, day 1" in ×2 lettering, the card's lines, and underlined Skip all and Next. |
| `S2-B-ending.png` / `-x3` | Title cards ending: "Hel's tide" in ×2 lettering and the outcome, then each soul carved into its own stone block. The stone sits below the doors, because the strip above them is only 9 px. Play again is underlined. |
| `S2-C-dusk.png` / `-x3` | On the desk, as objects. The desk stays lit with no soul at it. A black feather lies on the ledger line with its citation, and a slate holds tallies with "+2". The mentor pushes a torn recap sheet over the body chart, and Hel's letter carries a bile seal (whether bile is allowed there is an open question). |
| `S2-C-ending.png` / `-x3` | On the desk ending: the whole ledger (440×150) slid across the lit desk, listing every soul with marks, the standing seal, and a Play again ribbon. |
| `S2-compare-x3.png` | The six S2 dusk and ending images at ×2, dusk on the left and ending on the right, rows A, B and C. |
| `draw_sketches.py` | The script that draws all of the above. |
