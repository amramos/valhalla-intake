# Vertical slice — evidence matrix

**State:** DRAFT for the designer's check (D39) · **Ledger:** `vertical-slice-ledger.md` ·
**Plan:** `vertical-slice-plan.md` · **Issue:** #3 (WP0)

The authoring brief for WP2 (art) and WP4 (content data): the 15 encounters D39 names (the 12
roster slots, Egil, and returned Hakon in two variants; 14 authored, see Resolved 5), every body fact, every line, every valid pin pair, every red
herring, both destinations and the coverage that D6 demands. Names and wording may change; a slot's
purpose and acceptance seam may not (D25). Problems the matrix could not solve without a new
decision, and the lead's rulings on them, are in **Resolved** at the end.

## 0. Rules the matrix applies

### Desk per day

| Day | Doors open | Decrees in force | Witnesses | Quota | Clock | Citations | Huginn |
|---|---|---|---|---|---|---|---|
| 1 | Valhalla, Hel (Fólkvangr barred) | L1, L2, L3 | none | 1 | untimed | warnings only | — |
| 2 | Valhalla, Hel (Fólkvangr barred) | + L4 | yes | 1 | real time | yes | — |
| 3 | Valhalla, Hel, Fólkvangr | + L5 | yes (none for returned Hakon) | 2 | real time | yes | 2 answers |

### Decrees (D32, verbatim)

| Id | Text | From day | Names |
|---|---|---|---|
| L1 | "Valhalla takes only those slain by a weapon in battle. Death by sickness, age or accident goes to Hel." | 1 | Valhalla (weapon, in battle); Hel (sickness, age, accident) |
| L2 | "Whoever lies to the Gate goes to Hel, whatever else the Law says." | 1 | Hel — above every other decree |
| L3 | "Even so, a warrior without a weapon in hand goes to Hel." | 1 | Hel — narrows L1 |
| L4 | "Even so, those who fled the battle go to Hel." | 2 | Hel — narrows L1 |
| L5 | "Those who fell defending hearth and kin go to Fólkvangr, whatever L1, L3 and L4 say." | 3 | Fólkvangr — above L1, L3, L4; below L2 |

**Precedence, as the decrees word it:** L2 > L5 > L3 = L4 > L1. No two decrees contradict (no
forgery in the slice).

### Seam rules

Every pair not listed as a seam in an encounter resolves "no seam" (−10 s from day 2, D10, D24).

| Kind | Pair | Caption | Notes |
|---|---|---|---|
| Lie seam, red | body fact × claim or witness line the fact shows false | "the body gives the lie." | Liar side is the line. Decides by L2; the citation names L2 |
| Lie seam, grey | claim line × witness line that cannot both be true | "one of them lies." | 8 px knot; Huginn names the liar side (day 3) |
| Law thread | evidence that shows a decree's condition × that decree | "the saga is true. Lx sends her to <realm>." on an honest soul; "Lx sends him to <realm>." on a liar | The caption names where **that decree** sends the soul; the decree texts settle precedence (rules R2, R3) |

What makes a law thread (applied the same way on every soul):
- **L1** (Valhalla clause): a claim line that states a death in battle. No body fact shows "in
  battle", so a wound or "no wound" against L1 is no seam.
- **L3:** the body fact "nothing in hand". "drawn sword in hand" against L3 is no seam (its
  condition is absent).
- **L4:** a testimony line that states the soul left the battle. No body fact proves flight, so any
  wound against L4 is no seam (D6: a back wound never proves flight).
- **L5:** a testimony line that states the soul fell holding its home or shielding its kin.
- **L2:** never pinned directly; a lie seam reaches it. Anything against L2 is no seam.

### Authoring rules (asserted by the WP4 authoring check)

| Rule | Statement |
|---|---|
| R1 | A law thread links evidence to a decree whose condition that evidence shows (per decree, as above) |
| R2 | Its caption names that decree's destination: "the saga is true. Lx sends her to <realm>." on an honest soul, "Lx sends him to <realm>." on a liar |
| R3 | Precedence is read from the decree text ("Even so", "whatever else the Law says", "whatever L1, L3 and L4 say"), never stated in a caption |
| R4 | A line that a body fact shows false (one side of a red seam) makes no law thread |
| R5 | A line on either side of a grey seam makes no law thread; pinned to a decree, it is no seam |
| R6 | A soul whose verdict rests on a grey seam alone (Ketil) has no law threads at all |
| R7 | A law thread without "the saga is true." appears only on a soul with at least one red seam, so a missing prefix never decides a verdict alone |

R4–R7 exist because the "the saga is true" prefix, or its absence, would otherwise tell the clerk
whether a soul lies, and answer for Huginn.

### Body chart conventions (D5)

- **One build** for every soul (D40): the same body base, front and back, in tunic, belt, trousers
  and boots, blocky hands, right hand empty by default. The head and hair are the identity layer
  (not clickable, not evidence).
- **Standard hit areas** on every soul, so absences are always pinnable: **B1** front torso,
  **B2** back torso, **B3** right hand. Extra facts are **B4**, **B5**.
- **Extra hit areas** and where they sit: left hand (soft hands), neck (broken neck), lower legs
  (wet to the knee), shirt hem down to the feet (night-shirt). No soul carries two facts in one
  area. Every hit area is at least 8×8 px, padded beyond the drawn pixels where needed.
- **Labels** are plain and identical everywhere a state repeats: "spear wound, chest", "spear wound, back",
  "no wound, chest", "no wound, back", "drawn sword in hand", "nothing in hand", "broken neck",
  "wet to the knee", "soft hands, no calluses", "night-shirt only, bare feet".
- No bile on any body. A returned soul's change is frost in the identity layer and a frost-burned
  name plate, never a fact.

### Line conventions

Claims run 3–4 lines, witnesses up to 3. Each line, its "C1 " prefix included, is at most 132 px
in m5x7 at 16 px (D50); `tools/content/measure_lines.gd` measures every line here (widest: 132 px). Every soul's human detail sits in a
pinnable line, named in each encounter's "Human detail" row (D27). Lines use straight quotes and
ASCII punctuation only: m5x7 has no curly quotes, dashes or ellipsis. Tone: deadpan over dread (GDD §6).

---

## Day 1 — Valhalla and Hel; L1–L3; no witnesses; quota 1; untimed

### 1 · Ulf (slot 1, guided 1/3)

| | |
|---|---|
| Build · identity | Base · old, bald crown, grey beard |
| Legal | **Valhalla** — L1 |
| Worthy | **Valhalla** (open) |
| Human detail (D27) | C4 |
| Liar · permitted uncertainty | no · none |
| Purpose | The verb, step by step: read, pin a confirming law thread, stamp (D16, D25) |
| Truth (recap) | Speared in the shield-wall at Ness, sword up to the end |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | spear wound, chest | front · chest | wound front overlay |
| B2 | no wound, back | back · upper back | none (hit area) |
| B3 | drawn sword in hand | front · right hand (sword also drawn on the back view) | sword overlay |

| Line | Text |
|---|---|
| C1 | "Speared, in battle." |
| C2 | "Took it in the chest." |
| C3 | "Sword up to the end." |
| C4 | "Sif gets the goat." |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| C1 × L1 | law | L1 → Valhalla | "the saga is true. L1 sends him to Valhalla." |

**Red herrings:** none (tutorial).
**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

### 2 · Kolbeinn (slot 2, guided 2/3)

| | |
|---|---|
| Build · identity | Base + night-shirt · red beard, round face |
| Legal | **Hel** — L2 (also L3) |
| Worthy | **Hel** (open) |
| Human detail (D27) | C4 |
| Liar · permitted uncertainty | yes · none |
| Purpose | The first lie: a red thread, the mentor highlights the pair (D25) |
| Truth (recap) | Died in his bed after the feast, full of mead. His wife did see |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | no wound, chest | front · chest | none (hit area) |
| B2 | no wound, back | back · upper back | none (hit area) |
| B3 | nothing in hand | front · right hand | none (hit area) |
| B4 | night-shirt only, bare feet | front · shirt hem to feet | night-shirt overlay |

| Line | Text |
|---|---|
| C1 | "Danes axed my chest." |
| C2 | "Mail on. Shield up." |
| C3 | "Died sword in hand." |
| C4 | "My wife will tell you." |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| B1 × C1 | red | liar C1 | "the body gives the lie." |
| B4 × C2 | red | liar C2 | "the body gives the lie." |
| B3 × C3 | red | liar C3 | "the body gives the lie." |
| B3 × L3 | law | L3 → Hel | "L3 sends him to Hel." |

**Red herrings:** none.
**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

### 3 · Hallr (slot 3, guided 3/3)

| | |
|---|---|
| Build · identity | Base + broken neck · long moustache, shaved sides (tilted head pose) |
| Legal | **Hel** — L2 |
| Worthy | **Hel** (open) |
| Human detail (D27) | C1 |
| Liar · permitted uncertainty | yes · none |
| Purpose | The second obvious liar; the body shows the real death (D25: a broken neck and no cut against a blade death) |
| Truth (recap) | Drunk on the hall roof the night before the duel, sword out, boasting. He slipped. Gorm never came |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | no wound, chest | front · chest (below the neck area) | none (hit area) |
| B2 | no wound, back | back · upper back | none (hit area) |
| B3 | drawn sword in hand | front · right hand | sword overlay |
| B4 | broken neck | front · neck | neck kink + tilted head pose |

| Line | Text |
|---|---|
| C1 | "Gorm called me out." |
| C2 | "Sword still sheathed." |
| C3 | "Blade in my chest." |
| C4 | "Not a bone broken." |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| B1 × C3 | red | liar C3 | "the body gives the lie." |
| B4 × C4 | red | liar C4 | "the body gives the lie." |
| B3 × C2 | red | liar C2 | "the body gives the lie." |

**Red herrings:** none. (B4 × C3 is no seam: a broken neck and a chest wound could both be true; B2 × C3 is no seam: a blade in the chest needn't come out the back; C4
is the line the neck breaks. B3 × C2 is strict because the label names a drawn blade: a sheathed sword could still be in his hand.)
**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

### 4 · Asa (slot 4, unguided)

| | |
|---|---|
| Build · identity | Base · fair hair in one braid |
| Legal | **Hel** — L3 ("Even so" narrows L1) |
| Worthy | **Valhalla** (open) |
| Human detail (D27) | C4 |
| Liar · permitted uncertainty | no · none |
| Purpose | The first Law against truth; the first figure at Hel's door; mercy is a warning only and a surplus on the quota (D25, D28, D35) |
| Truth (recap) | Fell in battle on the beach. Her spear snapped in a Dane and she fought on bare-handed |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | spear wound, chest | front · chest | wound front overlay |
| B2 | no wound, back | back · upper back | none (hit area) |
| B3 | nothing in hand | front · right hand | none (hit area) |

| Line | Text |
|---|---|
| C1 | "Danes on the beach." |
| C2 | "Spear in both hands." |
| C3 | "It broke. I kept on." |
| C4 | "My girl has the farm." |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| B3 × L3 | law | L3 → Hel | "the saga is true. L3 sends her to Hel." |

| Red herring | Why it looks like a seam | Innocent explanation |
|---|---|---|
| B3 × C2 | An empty hand against "spear in both hands", the shape of Kolbeinn's lie | Her own C3: "It broke. I kept on." |

**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

---

## Day 2 — witnesses arrive; + L4; quota 1; citations begin

Slots 5–7 all carry the **same back wound** (B2, one overlay) and each a clearly different second
fact (D25): Sigvaldi a second wound in front, Hakon a clean front and a gripped sword with an
admission in his claim, Grim wet legs and an empty hand. The back wound gives two verdicts
(Sigvaldi Valhalla, Grim Hel) and never proves flight (D6).

### 5 · Sigvaldi (slot 5)

| | |
|---|---|
| Build · identity | Base · beardless youth, short hair |
| Legal | **Valhalla** — L1 |
| Worthy | **Valhalla** (open) |
| Human detail (D27) | C4 |
| Liar · permitted uncertainty | no · none |
| Purpose | Back-wound red herring explained by his witness; the day's one lawful Valhalla soul, so the quota is met before Hakon (D25, D28) |
| Truth (recap) | The wall broke behind him; a Dane got in behind and speared his back. He turned and killed him with a Dane's sword |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | spear wound, chest | front · chest | wound front overlay (second fact) |
| B2 | spear wound, back | back · upper back | wound back overlay |
| B3 | drawn sword in hand | front · right hand | sword overlay |

| Line | Text |
|---|---|
| C1 | "Fell in battle. Ness." |
| C2 | "My sword broke early." |
| C3 | "Took a Dane's instead." |
| C4 | "Mother kept my bed." |
| **Witness** | **Bjorn, his shield-brother** |
| W1 | "Our wall broke." |
| W2 | "A Dane got in behind." |
| W3 | "Speared his back." |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| C1 × L1 | law | L1 → Valhalla | "the saga is true. L1 sends him to Valhalla." |

| Red herring | Why it looks like a seam | Innocent explanation |
|---|---|---|
| B2 × L4 | A back wound reads as flight | W1–W3: the wall broke and a Dane got in behind and speared his back |
| B2 × C1 | A back wound against a battle death | W1–W3, as above |
| B3 × C2 | A gripped sword against "my sword broke" | His own C3: "Took a Dane's instead." |

**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

### 6 · Hakon (slot 6, return-eligible)

| | |
|---|---|
| Build · identity | Base · dark braided beard |
| Legal | **Hel** — L4 |
| Worthy | **Valhalla** (open) |
| Human detail (D27) | C1 |
| Liar · permitted uncertainty | no · none |
| Purpose | The return arc: a true saga L4 damns. He admits leaving the fight carrying Ivar; Ivar is not his kin and nothing reads as defending (D2, D25, D32). The quota is already met by Sigvaldi, so mercy is a pure −2 (D28) |
| Truth (recap) | Left the fight carrying Ivar, a Jute he barely liked. Speared in the back walking away. Ivar died anyway |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | no wound, chest | front · chest | none (hit area; second fact: clean front) |
| B2 | spear wound, back | back · upper back | wound back overlay |
| B3 | drawn sword in hand | front · right hand | sword overlay |

| Line | Text |
|---|---|
| C1 | "Ivar owed me a knife." |
| C2 | "He fell. I lifted him." |
| C3 | "Left the fight." |
| C4 | "A spear, in my back." |
| **Witness** | **Ivar** |
| W1 | "No kin of his. A Jute." |
| W2 | "Carried me out of it." |
| W3 | "I died anyway. Sorry." |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| C3 × L4 | law | L4 → Hel | "the saga is true. L4 sends him to Hel." |
| W2 × L4 | law | L4 → Hel | "the saga is true. L4 sends him to Hel." |

**Red herrings:** none. B2 × L4 is no seam by rule (a wound never proves flight); his own C3 is what
L4 reads. He grips a sword on purpose, so L3 never touches him and returned Hakon's only seam stays
Hel's lie (Resolved 3).
**Ignored / missed record (D2):** *ignored* if C3 × L4 or W2 × L4 was pinned before he was stamped
to Hel; *missed* otherwise. Stamped to Hel → slot 10 is returned Hakon; dusk line "Hakon is back".
**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

### 7 · Grim (slot 7)

| | |
|---|---|
| Build · identity | Base + wet to the knee · black hair, scarred cheek |
| Legal | **Hel** — L2 (also L3) |
| Worthy | **Hel** (open) |
| Human detail (D27) | W3 |
| Liar · permitted uncertainty | yes · none (his grey seam is settled by the body, D30) |
| Purpose | Wet to the knee against an explicit dryness claim, "Dry when I fell" (D25's hill line stays as context); the same back wound as Sigvaldi with the opposite verdict; the first grey thread (D25) |
| Truth (recap) | Ran for the ford when the Danes came. Cut down from behind, halfway across. His dog stayed on the hill |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | no wound, chest | front · chest | none (hit area) |
| B2 | spear wound, back | back · upper back | wound back overlay |
| B3 | nothing in hand | front · right hand | none (hit area) |
| B4 | wet to the knee | front · lower legs (drawn on both views) | wet overlay (second fact) |

| Line | Text |
|---|---|
| C1 | "Never left the hill." |
| C2 | "Dry when I fell." |
| C3 | "No wound on my back." |
| C4 | "Never in the water." |
| **Witness** | **Orm, who stayed** |
| W1 | "He ran off the hill." |
| W2 | "Waded into the ford." |
| W3 | "The dog stayed." |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| B4 × C2 | red | liar C2 | "the body gives the lie." |
| B2 × C3 | red | liar C3 | "the body gives the lie." |
| C1 × W1 | grey | liar C1 | "one of them lies." |
| C4 × W2 | grey | liar C4 | "one of them lies." |
| B3 × L3 | law | L3 → Hel | "L3 sends him to Hel." |

**Red herrings:** none. No seam by rule: B2 × L4 and B4 × L4 (the body shows no motive); W1 × L4
and W2 × L4 (disputed lines make no law thread).
**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

### 8 · Brand (slot 8)

| | |
|---|---|
| Build · identity | Base + soft hands · oiled hair, trimmed beard |
| Legal | **Hel** — L2 (also L3) |
| Worthy | **Hel** (open) |
| Human detail (D27) | C4 |
| Liar · permitted uncertainty | yes · none |
| Purpose | Soft hands against "thirty winters at the oar" (D25), made strict by his own explicit hands claim, "Hands hard as oak."; the rowing boast stays as context. The day's last soul, a quota temptation if Sigvaldi was refused; then dusk: Eyvind's prayer and Hel's offer naming Ragna |
| Truth (recap) | A rich man's son with a bought seat on the ship. Hid under a bench at the boarding and was speared there |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | spear wound, chest | front · chest | wound front overlay |
| B2 | no wound, back | back · upper back | none (hit area) |
| B3 | nothing in hand | front · right hand | none (hit area) |
| B4 | soft hands, no calluses | front · left hand | soft-hand overlay (shape) |

| Line | Text |
|---|---|
| C1 | "Thirty winters rowing." |
| C2 | "Hands hard as oak." |
| C3 | "One wound: my back." |
| C4 | "Mother sent cheese." |
| **Witness** | **Toki, a rower** |
| W1 | "He never rowed. Ever." |
| W2 | "Hid under a bench." |
| W3 | "Smelled of cheese." |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| B4 × C2 | red | liar C2 | "the body gives the lie." |
| B1 × C3 | red | liar C3 | "the body gives the lie." |
| B2 × C3 | red | liar C3 | "the body gives the lie." |
| C1 × W1 | grey | liar C1 | "one of them lies." |
| B3 × L3 | law | L3 → Hel | "L3 sends him to Hel." |

**Red herrings:** none. W2 × L4 is no seam: hiding under a bench doesn't say he left the battle.
**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

---

## Day 3 — Fólkvangr opens; + L5; Huginn; quota 2

Queue (D22): Freydis, then returned Hakon **or** Egil, then Ragna, then Ketil.

### 9 · Freydis (slot 9)

| | |
|---|---|
| Build · identity | Base + soft hands · dark hair in a braided crown |
| Legal | **Valhalla** — L1 |
| Worthy | **Valhalla** (open) |
| Human detail (D27) | C4 |
| Liar · permitted uncertainty | no · none |
| Purpose | Back-wound red herring (D25), plus soft hands that look like Brand's lie; the day's only lawful Valhalla soul (D35) |
| Truth (recap) | The jarl's skald. First over the Danes' rail; a Dane hiding by the mast speared her from behind |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | no wound, chest | front · chest | none (hit area) |
| B2 | spear wound, back | back · upper back | wound back overlay |
| B3 | drawn sword in hand | front · right hand | sword overlay |
| B4 | soft hands, no calluses | front · left hand | soft-hand overlay |

| Line | Text |
|---|---|
| C1 | "Slain in a sea-battle." |
| C2 | "Skald, not a rower." |
| C3 | "First over their rail." |
| C4 | "Verse half done. Pity." |
| **Witness** | **Bersi, a crewman** |
| W1 | "She went over first." |
| W2 | "One hid by the mast." |
| W3 | "Got her from behind." |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| C1 × L1 | law | L1 → Valhalla | "the saga is true. L1 sends her to Valhalla." |

| Red herring | Why it looks like a seam | Innocent explanation |
|---|---|---|
| B2 × L4 | A back wound reads as flight | W2–W3: a Dane hid by the mast and got her from behind |
| B2 × C3 | "First over" with a wound behind | W2–W3, as above |
| B4 × C3 | Soft hands on a fighter, after Brand's soft hands gave the lie | Her own C2: "Skald, not a rower." |

**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

### 10a · Hakon, returned — variant IGNORED (slot 10, if Hakon went to Hel after a pinned L4 thread)

| | |
|---|---|
| Build · identity | Base (same body as slot 6) · dark braided beard with frost rime; frost-burned name plate, hover label "Back from Hel. His saga was true." (a label, not a fact or seam; GDD §3.6: worthiness visible when you choose) |
| Legal | **Hel** — L2 |
| Worthy | **Valhalla** (open) |
| Human detail (D27) | C4 |
| Liar · permitted uncertainty | yes · none |
| Purpose | The arc: a contradiction still decides him. His one seam is a lie Hel taught him, in a claim line; L2 sends him back, or the clerk chooses mercy. No Fólkvangr route (D2, D25, D32). Mercy fills the day's quota |
| Truth (recap) | As on day 2. Hel taught him to hide the back wound, as if that had damned him; the lie is what damns him now |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | no wound, chest | front · chest | none (hit area) |
| B2 | spear wound, back | back · upper back | wound back overlay |
| B3 | drawn sword in hand | front · right hand | sword overlay |

| Line | Text |
|---|---|
| C1 | "You read it. Then Hel." |
| C2 | "Hel taught me better." |
| C3 | "One wound: the chest." |
| C4 | "Ivar owed me a knife." |
| **Witness** | none: the panel reads "No witness came back." (Resolved 4) |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| B1 × C3 | red | liar C3 | "the body gives the lie." |
| B2 × C3 | red | liar C3 | "the body gives the lie." |

**Red herrings:** none. Nothing admits leaving the wall, so L4 has nothing to read; he grips a sword,
so L3 has nothing to read; no line claims kin, so L5 has nothing to read.
**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

### 10b · Hakon, returned — variant MISSED (slot 10, if Hakon went to Hel with no L4 thread pinned)

Identical to 10a (body, name plate and its label, destinations, seams, mentor) except C1–C2:

| Line | Text |
|---|---|
| C1 | "You didn't even look." |
| C2 | "Hel had time to talk." |
| C3 | "One wound: the chest." |
| C4 | "Ivar owed me a knife." |

### 10c · Egil (slot 10 fallback, if Hakon was not stamped to Hel)

| | |
|---|---|
| Build · identity | Base + night-shirt · brown beard, hair loose from sleep |
| Legal | **Hel** — L2 (L5 would send him to Fólkvangr; L2 says "whatever else the Law says") |
| Worthy | **Fólkvangr** (open) |
| Human detail (D27) | C2 |
| Liar · permitted uncertainty | yes · none (his grey seam is settled by the body) |
| Purpose | Keeps day 3's Law-against-truth beat: a liar who died defending kin (D39). He lied out of pride, about mail he wasn't wearing |
| Truth (recap) | Held his door against raiders at night, in his night-shirt, while Hild gave birth behind him |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | spear wound, chest | front · chest (over the night-shirt) | wound front overlay |
| B2 | no wound, back | back · upper back | none (hit area) |
| B3 | drawn sword in hand | front · right hand | sword overlay |
| B4 | night-shirt only, bare feet | front · shirt hem to feet | night-shirt overlay |

| Line | Text |
|---|---|
| C1 | "Raiders, in the night." |
| C2 | "Hild was in childbed." |
| C3 | "I held our door." |
| C4 | "In my mail, of course." |
| **Witness** | **Kalf, one of the raiders** |
| W1 | "Held his door. Long." |
| W2 | "Swore all the while." |
| W3 | "No mail. Just a shirt." |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| B4 × C4 | red | liar C4 | "the body gives the lie." |
| C4 × W3 | grey | liar C4 | "one of them lies." |
| C3 × L5 | law | L5 → Fólkvangr (overruled by L2) | "L5 sends him to Fólkvangr." |
| W1 × L5 | law | L5 → Fólkvangr (overruled by L2) | "L5 sends him to Fólkvangr." |

**Red herrings:** none.
**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

### 11 · Ragna (slot 11, Hel's named soul)

| | |
|---|---|
| Build · identity | Base + night-shirt + broken neck · grey-streaked hair, loose (tilted head pose); serpent mark on the name plate, hover "Hel asked for her" |
| Legal | **Fólkvangr** — L5 ("whatever L1, L3 and L4 say") |
| Worthy | **Fólkvangr** (open) |
| Human detail (D27) | W3 |
| Liar · permitted uncertainty | no · none |
| Purpose | Hel's promise: find a seam where there is none. **No lie seam**; a law thread to L5; five look-alike seams, each explained in her own lines or her witness's (D3, D25, D38). Keeping the promise is a citation (−2) for +4, and +1 to the tide (D29) |
| Truth (recap) | Raiders came at night. She held the door with her husband's sword while her boys got out the back; the raiders fired the roof and it fell on her |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | no wound, chest | front · chest | none (hit area) |
| B2 | no wound, back | back · upper back | none (hit area) |
| B3 | drawn sword in hand | front · right hand | sword overlay |
| B4 | broken neck | front · neck | neck kink + tilted head pose |
| B5 | night-shirt only, bare feet | front · shirt hem to feet | night-shirt overlay |

| Line | Text |
|---|---|
| C1 | "They came at night." |
| C2 | "I held the door." |
| C3 | "My boys behind me." |
| C4 | "Then the roof fell." |
| **Witness** | **Skeggi, one of the raiders** |
| W1 | "She held that door." |
| W2 | "So we fired the roof." |
| W3 | "Her boys got out." |

| Seam | Type | Decree · liar side | Caption |
|---|---|---|---|
| C2 × L5 | law | L5 → Fólkvangr | "the saga is true. L5 sends her to Fólkvangr." |
| C3 × L5 | law | L5 → Fólkvangr | "the saga is true. L5 sends her to Fólkvangr." |
| W1 × L5 | law | L5 → Fólkvangr | "the saga is true. L5 sends her to Fólkvangr." |

| Red herring | Why it looks like a seam | Innocent explanation |
|---|---|---|
| B5 × C2 | A night-shirt on a defender, like Kolbeinn's and Egil's lies | Her own C1: "They came at night." |
| B1 × C2 | No wound on a fighter, like Kolbeinn's lie | Her own C4: "Then the roof fell." (and W2) |
| B2 × C2 | As above, the back | C4 and W2 |
| B4 × C2 | A broken neck on a fighter, like Hallr's lie | Her own C4: "Then the roof fell." (and W2) |
| C4 × L1 | A falling roof reads as an accident, which L1 sends to Hel | W2: "So we fired the roof." It was the raid, not an accident |

**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

### 12 · Ketil (slot 12)

| | |
|---|---|
| Build · identity | Base + wet to the knee · fair beard, one plait |
| Legal | **Hel** — L2 (by the truth; L4 if the witness is believed) |
| Worthy | **Hel** (open) |
| Human detail (D27) | C4 |
| Liar · permitted uncertainty | yes · **yes**: C2 × W1 unresolved means no citation either way (D37) |
| Purpose | A body that fits Valhalla; only the grey thread decides him; the only day-3 soul that needs Huginn; the quota temptation (admitting him fills quota 2) (D25, D30, D35) |
| Truth (recap) | Ran at the first spear. They caught him midstream in the ford; he turned too late |

| Fact | Label | View · place | Visual state |
|---|---|---|---|
| B1 | spear wound, chest | front · chest | wound front overlay |
| B2 | no wound, back | back · upper back | none (hit area) |
| B3 | drawn sword in hand | front · right hand | sword overlay |
| B4 | wet to the knee | front · lower legs (drawn on both views) | wet overlay |

| Line | Text |
|---|---|
| C1 | "Raiders at the ford." |
| C2 | "Held it. Never ran." |
| C3 | "Speared in the chest." |
| C4 | "Sigrid will sing it." |
| **Witness** | **Hauk, his neighbour** |
| W1 | "Ketil ran first." |
| W2 | "Caught in the ford." |
| W3 | "He turned. Too late." |

| Seam | Type | Decree · liar side | Caption · Huginn |
|---|---|---|---|
| C2 × W1 | grey | liar C2 | "one of them lies." · Huginn: "The claim lies." |

No law threads (rule R6): no line states a death in battle; W1, the only line that shows
flight, is disputed.

| Red herring | Why it looks like a seam | Innocent explanation |
|---|---|---|
| B1 × W1 | A front wound on a man who "ran" | W3: "He turned. Too late." |
| B4 × C2 | Wet to the knee on a man who "held it", like Grim's lie | C1 and W2: both accounts put him in the ford |
| B4 × W1 | As above | C1 and W2 |

Neither red herring settles the grey seam: the body fits both accounts.
**Mentor:** her steps and comments for this soul are in the mentor script (§ A2).

---

## A. Authored text (WP4)

Every string the slice shows outside the testimony and the decrees. Quoted text is final; it uses
straight quotes and ASCII punctuation only (m5x7 carries á, ó, ö and þ, but no curly quotes,
dashes or ellipsis). `{braces}` are filled from data at run time. Text on the caption strip should
stay within two strip lines (D33); WP4's authoring check measures it.

### A1. Pin results

| Result | Caption strip text |
|---|---|
| Red thread | "{a} against {b}: the body gives the lie." |
| Grey thread | "{a} against {b}: one of them lies." |
| Law thread, honest soul | "{a} against {b}: the saga is true. {Lx} sends {him/her} to {realm}." |
| Law thread, liar | "{a} against {b}: {Lx} sends {him/her} to {realm}." |
| No seam (red herrings included) | "No seam: those two agree. -10 s" (day 1, untimed: "No seam: those two agree.") |
| Re-pin of an existing thread | the thread's own caption again (free, D8) |

### A2. The mentor's script

**Guided souls (D16).** Prompts appear in her bubble, one step at a time; each step waits for the
player. She lights a pair or a whole panel, never a single fact on its own.

| Soul | Step | Lit | Bubble |
|---|---|---|---|
| 1 Ulf | read | the body chart | "Hover each mark." |
| | pair | C1 and L1 | "Line one, decree one." |
| | pin | C1 and L1 | "Click one, then the other." |
| | stamp | the doors | "The Law agrees. Stamp him." |
| 2 Kolbeinn | read | the body chart and the claim | "Read him. All of him." |
| | pair | B1 and C1 | "His chest. His C1." |
| | pin | B1 and C1 | "Pin them." |
| | stamp | the doors | "Bodies don't lie. L2 takes liars." |
| 3 Hallr | read | the body chart and the claim | "Your turn to read." |
| | pair | B1 and C3 | "His chest. His C3." |
| | pin | B1 and C3 | "Pin them." |
| | stamp | nothing | "Where does a liar go?" |

**Comments (caption strip, from soul 4 on, and after a wrong stamp on souls 1-3).** She tells a
deliberate mercy from an illegal stamp. *Mercy* is a stamp to the soul's worthy door against the
Law; *illegal* is a stamp against both. Each warning names the visible pair (the soul's cited pair,
table A3).

| When | Comment |
|---|---|
| Mercy, day 1 | "Kind. {pair}. From tomorrow, that costs feathers." |
| Illegal, day 1 | "{pair}. Wrong door. From tomorrow, that costs feathers." |
| Mercy, days 2-3 | "Kind. {pair}. That cost you two." |
| Illegal on a liar, days 2-3 | "{pair}. You let a liar through." |
| Illegal on an honest soul, days 2-3 | "{pair}. Nothing in that saga was a lie." |
| Stamp on an unresolved grey thread | none (permitted uncertainty, D37) |
| First grey thread, day 2 | "One of them lies. The body may say which." |
| First grey thread, day 3 | "Huginn answers that. Click the raven to ask him." (game UI D40) |
| Keeping Hel's promise (Ragna to Hel) | "{pair}. Hel pays well." |
| The first figure joins Hel's tide, on a lawful stamp | "The Law is kept. Hel's tide grows by one. At 3, they march." (D53) |
| The first figure, after one of her comments | the comment, then " Hel's tide grows. At 3, they march." (two note lines at most) |
| The first figure, on a wrong stamp no visible seam showed | "Hel's tide grows. At 3, they march." |

### A3. Citations

Template: "Citation: {decree}. {pair}." plus " You threaded it yourself." when the stamp was ignored
(GDD §3.7). On day 1 the same line arrives as the mentor's warning, with no feather. The black
feather replays it when clicked, and lights the pair.

| Soul | Decree | Cited pair (lit) | {pair} text |
|---|---|---|---|
| Ulf | L1 | C1 × L1 | "'Speared, in battle' and L1" |
| Kolbeinn | L2 | B1 × C1 | "No wound on his chest, and 'Danes axed my chest'" |
| Hallr | L2 | B1 × C3 | "No wound on his chest, and 'Blade in my chest'" |
| Asa | L3 | B3 × L3 | "Her empty hand, and L3" |
| Sigvaldi | L1 | C1 × L1 | "'Fell in battle. Ness' and L1" |
| Hakon | L4 | C3 × L4 | "'Left the fight' and L4" |
| Grim | L2 | B2 × C3 | "His back wound, and 'No wound on my back'" |
| Brand | L2 | B4 × C2 | "Soft hands, and 'Hands hard as oak'" |
| Freydis | L1 | C1 × L1 | "'Slain in a sea-battle' and L1" |
| Hakon, returned | L2 | B1 × C3 | "No wound on his chest, and 'One wound: the chest'" |
| Egil | L2 | B4 × C4 | "A night-shirt, and 'In my mail, of course'" |
| Ragna | L5 | C2 × L5 | "'I held the door' and L5" |
| Ketil | L2 | C2 × W1, after Huginn's answer | "Huginn's answer, and 'Held it. Never ran'" |

Ketil draws a citation only once Huginn has answered on C2 × W1; before that the stamp is
permitted uncertainty (D37).

### A4. Huginn

| Moment | Text |
|---|---|
| Answer, claim side lies | "Huginn: the claim lies." |
| Answer, witness side lies | "Huginn: the witness lies." (unused by the slice's souls; kept for the rule) |
| Control, no grey thread selected | "Ask Huginn" greyed; hover "Select a grey thread first." |
| Control, no free answer left | hover "Extra answer: 2 feathers." (D29) |
| Answer bought | "Huginn takes 2 feathers. {answer}" |

### A5. Dawn cards (D34)

Each card lists its lines in this order; "NEW" marks stay until the day's first stamp. Odin's writ
names the decrees by their numerals (L1 is "I"), as the desk shows them.

**Day 1**
- "Day 1."
- "Odin wants 1 soul for Valhalla."
- "Untimed today."
- "The Law: I, II, III."
- "Doors: Valhalla and Hel. Fólkvangr is barred."
- "The senior valkyrie will show you the first three."

**Day 2**
- "Day 2."
- "Odin wants 1 soul for Valhalla."
- "The clock: {clock}. It runs while a soul is at the desk."
- "NEW IV: Even so, those who fled the battle go to Hel."
- "Witnesses arrive. Claim against witness makes a grey thread."
- "Citations begin today: 2 feathers for any stamp against what the desk can show you."

**Day 3**
- "Day 3."
- "Odin wants 2 souls for Valhalla."
- "The clock: {clock}."
- "NEW V: Those who fell defending hearth and kin go to Fólkvangr, whatever I, III and IV say."
- "NEW door: Fólkvangr opens."
- "Huginn perches here: 2 answers a day."

### A6. Dusk cards (D15)

Order: citations, quota, recap, requests, story beat; "Next" and "Skip all". Skipping hides
nothing that has consequences: requests land in the ledger either way.

| Card | Text |
|---|---|
| Citations | "Citations today: {n}." followed by each citation line, or "No citations today." |
| Quota met | "Odin wanted {quota}. Valhalla took {count}. +2 feathers." |
| Quota short | "Odin wanted {quota}. Valhalla took {count}. -{short} feathers." |
| Recap | up to 3 souls (A7) |
| Day 2 request: Hel's offer | "Hel, at the serpent door: 'Tomorrow Ragna comes to your desk. Send her to me, and I pay four feathers at the stamp.'" |
| Ledger entry (open) | "Hel: send Ragna to Hel. 4 feathers." |
| Ledger entry (kept) | "Kept. Ragna went to Hel. Hel paid 4 feathers." |
| Ledger entry (broken) | "Broken. Ragna went to {realm}." |
| Ledger entry (lapsed) | "Lapsed. Ragna was never judged." |
| Day 2 story beat: Eyvind's prayer | "A prayer at your shrine, from Eyvind, your brother: 'Sister. Father's ring is mine now. I wear it on my oar hand. If I fall, know me by it.'" |
| Day 2, if Hakon went to Hel | "Hakon is back. Hel sent him up the road. He will be at your desk tomorrow." |
| Day 3 | the slice ending (A8) |

### A7. Recap lines

**Selection, up to 3 souls a day:** first any soul stamped against its worthy door, then any mercy,
then any permitted uncertainty, then the day's Law-against-truth soul (Asa, Hakon, Ragna), in queue
order. Each recap is the soul's truth line, then one outcome line.

| Soul | Truth line |
|---|---|
| Ulf | "Ulf was speared in the shield-wall at Ness, sword up to the end." |
| Kolbeinn | "Kolbeinn died in his bed after the feast, full of mead. His wife did see." |
| Hallr | "Hallr fell off the hall roof the night before his duel, drunk, sword out. Gorm never came." |
| Asa | "Asa fell in battle on the beach. Her spear broke in a Dane and she fought on bare-handed." |
| Sigvaldi | "Sigvaldi held the wall at Ness until it broke. A Dane got in behind him." |
| Hakon | "Hakon carried Ivar out of the fight and took a spear in the back for it. Ivar died anyway." |
| Grim | "Grim ran off the hill for the ford. They speared him from behind in the water. His dog stayed." |
| Brand | "Brand bought his seat on the ship. He hid under a bench at the boarding and was speared there." |
| Freydis | "Freydis, the jarl's skald, went over the rail first. A Dane behind the mast speared her." |
| Hakon, returned | "Hakon's saga was true. Hel taught him to hide the wound in his back." |
| Egil | "Egil held his door against raiders in his night-shirt while Hild gave birth. He lied about the mail." |
| Ragna | "Ragna held her door while her boys got out. The raiders fired the roof." |
| Ketil | "Ketil ran at the first spear. They caught him in the ford; he turned too late." |

| Outcome | Outcome line |
|---|---|
| Law and truth agree, stamped there | "{Realm}, as the Law and the truth agree." |
| Stamped legal, not worthy | "The Law sent {him/her} to {legal}. The truth was {worthy}." |
| Mercy (worthy, against the Law) | "You sent {him/her} to {worthy} against {decree}. The truth agrees." |
| Neither | "You sent {him/her} to {realm}. The Law said {legal}. The truth was {worthy}." |
| Permitted uncertainty | "{Realm}. Which side lied couldn't be proven at the desk." |
| Never judged | "Never judged." |

### A8. The slice ending (D23)

| Ending | Title | Text |
|---|---|---|
| Hel's tide (tide at threshold) | "Hel's tide" | "The worthy you damned march with Hel. At the first horn they break the line: {names}." |
| The hollow hall (hollow at threshold) | "The hollow hall" | "The liars you let in fled at the first horn. Their benches stand empty: {names}." |
| The Hall holds | "The Hall holds" | "Odin counts his einherjar and finds them true. The gate holds, for now." |

Below the ending, one row per encounter: "{name}: {verdict}. Truth: {worthy}." plus " Ignored." or
" Missed." on a wrong stamp, or "{name}: never judged."; returned Hakon is listed as "Hakon
(returned)". Then the standing: "Feathers: {n}. Rank: {rank}." and the button "Play again".

---

## Coverage (D6)

Every fact state, where it is part of a seam and where it is a red herring. Each row holds in
**both** slot-10 branches (returned Hakon or Egil), and every red-herring use is in the 12 roster
souls.

| State (label) | Hit area | Seam uses | Red-herring uses | Also shown, consistent |
|---|---|---|---|---|
| spear wound, chest | chest | Brand B1 × C3 (red) | Ketil B1 × W1 | Ulf, Asa, Sigvaldi, Egil |
| spear wound, back | upper back | Grim B2 × C3 (red); returned Hakon B2 × C3 (red) | Sigvaldi B2 × L4, B2 × C1; Freydis B2 × L4, B2 × C3 | Hakon (day 2: Hel by L4; Sigvaldi: Valhalla — one wound, two verdicts) |
| no wound, chest | chest | Kolbeinn B1 × C1; Hallr B1 × C3; returned Hakon B1 × C3 (all red) | Ragna B1 × C2 | Grim, Hakon, Freydis |
| no wound, back | upper back | Brand B2 × C3 (red) | Ragna B2 × C2 | Ulf, Kolbeinn, Hallr, Asa, Egil, Ketil |
| drawn sword in hand | right hand | Hallr B3 × C2 (red) | Sigvaldi B3 × C2 | Ulf, Hakon, Freydis, returned Hakon, Egil, Ragna, Ketil |
| nothing in hand | right hand | Kolbeinn B3 × C3 (red); Kolbeinn, Asa, Grim, Brand B3 × L3 (law) | Asa B3 × C2 | — |
| broken neck | neck | Hallr B4 × C4 (red) | Ragna B4 × C2 | — |
| wet to the knee | lower legs | Grim B4 × C2 (red) | Ketil B4 × C2, B4 × W1 | — |
| soft hands, no calluses | left hand | Brand B4 × C2 (red) | Freydis B4 × C3 | — |
| night-shirt only, bare feet | shirt hem to feet | Kolbeinn B4 × C2 (red); Egil B4 × C4 (red) | Ragna B5 × C2 | — |

**Cut or folded in** (no seam and red-herring pair in the roster): arrow; calloused hands (the
base's blocky hand is the unlabelled norm); bare feet as its own fact (folded into the night-shirt,
one hit area); a child's toy; Asa's broken spear beside her (its explanation lives in her C3);
the clean blade (D25: it can't be seen).

## Counts

| | |
|---|---|
| Encounters | 14 authored: slots 1–9, 11, 12, plus slot 10 as returned Hakon (ignored), returned Hakon (missed) or Egil — the 15 that D39 names, with slot 10 counted once per branch (Resolved 5) |
| Fact instances | 51 |
| Fact states (labels) | 10, on 7 hit areas; 7 drawn overlays, 3 absences |
| Lie seams, red | 16 pairs |
| Lie seams, grey | 5 pairs |
| Law threads | 14 pairs |
| Red herrings | 15 pairs, on 5 souls (Asa, Sigvaldi, Freydis, Ragna, Ketil) |
| Permitted uncertainty | 1 (Ketil, C2 × W1) |

## Strict-obedience trace (D23, D28, D35)

The clerk stamps every soul to its legal destination and threads what the Law needs. Counting is per
encounter, by worthy destination.

| Day | Soul | Strict stamp | Worthy | Hel's tide | Hollow hall | Quota |
|---|---|---|---|---|---|---|
| 1 | Ulf | Valhalla | Valhalla | | | 1/1 → +2 |
| 1 | Kolbeinn | Hel | Hel | | | |
| 1 | Hallr | Hel | Hel | | | |
| 1 | Asa | Hel (L3) | Valhalla | **1** Asa | | |
| 2 | Sigvaldi | Valhalla | Valhalla | | | 1/1 → +2 |
| 2 | Hakon | Hel (L4) | Valhalla | **2** Hakon | | (return arc fires) |
| 2 | Grim | Hel | Hel | | | |
| 2 | Brand | Hel | Hel | | | |
| 3 | Freydis | Valhalla | Valhalla | | | 1/2 → −1 |
| 3 | Hakon, returned | Hel (L2) | Valhalla | **3** Hakon again | | |
| 3 | Ragna | Fólkvangr (promise broken) | Fólkvangr | (kept: **4** Ragna; −2 citation, +4) | | |
| 3 | Ketil | Hel (after Huginn: "The claim lies.") | Hel | | | |

- **Strict obedience reaches Hel's tide:** 3 (Asa, Hakon, Hakon returned) against a threshold of 3;
  4 if Hel's promise is kept. The hollow hall stays at 0. Feathers: 10 → 12 → 14 → 13 (15 with the
  promise kept). Huginn: 1 of 2 answers used.
- **Mercy on Hakon is a pure −2 on day 2:** Sigvaldi (slot 5) is the day's one lawful Valhalla soul
  and comes first, so the quota of 1 is met before Hakon. Admitting Hakon gains no quota and costs
  a citation (C3 × L4 was visible). It keeps the tide at 1 and sends Egil to slot 10; obeying the Law
  on Egil (Hel, L2) adds him to the tide (2; 3 with the promise kept).
- **Mercy on day 3 pays:** with only Freydis lawful, mercy on returned Hakon (Valhalla) fills quota 2
  (citation −2, quota +2 instead of −1).
- **Leniency reaches the hollow hall:** admitting Ketil unresolved fills the day-3 quota without a
  citation (D37) and adds 1; admitting Grim or Brand on day 2 adds the second.

## Art list (WP2)

Derived from the facts above; one build (D40). Every overlay is drawn for the front and back views
of the body chart (128×100); the standing soul (48×96) is the front-view composite of the same
layers, so it can show nothing the chart doesn't (D5).

| # | Item | Views | Used by | Notes |
|---|---|---|---|---|
| 1 | **Body base** (tunic, belt, trousers, boots; blocky hands; right hand empty) | front, back | all | The only build. Ashen skin |
| 2 | spear wound, chest | front (chest) | Ulf, Asa, Sigvaldi, Brand, Egil, Ketil | Blood pixels where it enters; must read over the tunic and the night-shirt |
| 3 | spear wound, back | back (upper back) | Sigvaldi, Hakon ×3, Grim, Freydis | One overlay for every back wound (D6) |
| 4 | drawn sword in hand | front (hand and blade), back (blade at the side) | 9 encounters | Pale blade against the dark tunic |
| 5 | broken neck | front, back | Hallr, Ragna | A visible kink; needs a tilted pose of those two heads |
| 6 | wet to the knee | front, back | Grim, Ketil | Shape, not tint alone: a hard tide line at the knee and drip pixels |
| 7 | soft hands | front (left hand) | Brand, Freydis | Shape: slender, smooth fingers against the base's blocky hand |
| 8 | night-shirt only, bare feet | front, back | Kolbeinn, Egil, Ragna | Replaces tunic, belt, trousers and boots: a loose knee-length shirt, bare shins and feet |
| 9 | Identity heads (front and back) | both | 12 souls | Ulf, Kolbeinn, Hallr (tilted), Asa, Sigvaldi, Hakon, Grim, Brand, Freydis, Egil, Ragna (tilted), Ketil |
| 10 | Hakon's frost head | both | returned Hakon | Frost rime in hair and beard; cold greys, never bile (D5) |
| 11 | Name plate states | — | — | Plain; frost-burned (returned Hakon; hover "Back from Hel. His saga was true."); Hel's serpent mark (Ragna; hover "Hel asked for her") |

Absences ("no wound", "nothing in hand") need no art, only hit areas. Layer order: base → clothing
→ wet → wounds → left hand → sword → neck → head. Composites needed: 14 (one per authored
encounter; 10a and 10b share one).

## Huginn check (D30)

| Day-3 soul | Grey seams | Settled by | Needs Huginn |
|---|---|---|---|
| Freydis | none | — | no |
| Hakon, returned (both variants) | none (no witness) | — | no |
| Egil (fallback) | C4 × W3 | red B4 × C4 (night-shirt against mail) | no |
| Ragna | none | — | no |
| **Ketil** | C2 × W1 | nothing at the desk; the body fits both accounts | **yes** |

Day 2's grey seams (Grim, Brand) are settled by their red seams, so day 2 never needs him. Only
Ketil's verdict depends on a grey thread alone.

## Resolved

The lead's rulings on the issues this matrix raised (2026-10-21).

1. **Law-thread captions name the pinned decree (D38).** A law thread links evidence to a decree
   whose condition the evidence shows; its caption names that decree's destination; precedence is
   read from the decree text and never stated in a caption (rules R1–R3). Egil keeps his L5
   threads. Asa's C1 now reads "Danes on the beach." and states no death in battle, so her only
   law thread is B3 × L3 ("the saga is true. L3 sends her to Hel.").
2. **"the saga is true" must not answer for Huginn.** The three anti-leak rules are accepted:
   no law thread from a line the body shows false, from either side of a grey seam, or on a soul
   decided by a grey seam alone (rules R4–R6, asserted by the WP4 authoring check).
3. **Hakon grips a sword, so only L4 damns him on day 2.** The lead amends plan §2.26 to match;
   returned Hakon's only seam stays Hel's lie.
4. **Returned Hakon has no witness.** His witness panel reads "No witness came back."
5. **The encounter count.** D39's 15 are 14 authored encounters: slot 10 is filled by returned
   Hakon (ignored), returned Hakon (missed) or Egil; the auditor (D26) sees all three.
6. **Line cap and the line number.** Superseded by D50: a line, prefix included, is at most 132 px
   in m5x7. WP4 measured every line with the font and reworded the 14 that ran over.
7. **Front-view hit-area density.** The WP1 fit check includes Ragna's front view (neck, chest,
   right hand, hem) at 1:1.

**Judgement calls left as they are** (not blocking):
- Hakon's "clearly different second fact" is an absence, a clean front, set against Sigvaldi's
  second wound and Grim's wet legs (D25).
- L1 names no realm for a weapon death outside battle that isn't sickness, age or accident
  (Ragna's fired roof). L5 covers Ragna; future rosters should avoid the gap or close it in the Law.

## Open issues (WP4 content pass)

1. **Ledger text now out of date (owner's document).** D47 quotes Grim's back-wound line as "Not
   one wound behind."; it is now "No wound on my back." (it ran 1 px over). The ledger walkthrough
   quotes Ulf's "axe wound, front" and Grim's old citation. **Proposed fix:** a one-line ledger note
   when the lead next records decisions; the matrix is the source for the data.
2. **Every wound is now a spear wound.** Precise labels (from the WP1 playtest) name the weapon, and
   D6 needs each state in a seam and a red herring. An axe wound would be a new state with neither,
   so Ulf is now "Speared, in battle." and every front and back wound is "spear wound". **For WP2:**
   the two wound overlays must read as spear punctures, not gashes.
3. **The tool reads the font file, not the imported resource.** It measures the way the evidence
   panel does (get_string_size minus 1 at 16 px), but import options could shift a width by a
   pixel. **Proposed fix:** WP4's authoring check measures with the desk theme's font. Six distinct
   lines sit exactly at 132 px and would fail first: Sigvaldi's C2 and C3, Hakon's "Ivar owed me a
   knife." (also returned Hakon's C4), Brand's C1 and W1, and Egil's C4.
4. **Card and bubble text is not width-checked.** Dawn and dusk cards, the mentor's bubble and the
   ending have no built panels yet. The caption-strip texts fit two strip lines (the longest
   citation is 470 px of 688).
5. **Grim's human detail lives in his witness's line** (W3 "The dog stayed."), as ruled in WP0.
6. **"sword in hand" is now "drawn sword in hand" on every soul** (the PR #15 review). Hallr's
   "Sword still sheathed." could be true beside a sword held in its sheath, so B3 × C2 failed the
   strictness test. One label per state (D6) means every sword fact changes, which matches the art
   (a pale bare blade). Its hover label is 109 px (126 px with a "B3 " prefix, under D50's 132).
   The ledger walkthrough still quotes "sword in hand" (see 1).

## Measurements (D12)

This pass only: WP4 part 1, final content text, 2026-10-21, one agent. Setup is timed apart from the
encounters. Writing is new text per encounter (citation pair, recap line, mentor steps); rework is
changes to text the matrix already had (lines over 132 px, labels, markers).

| Item | Writing (min) | Rework (min) | Notes |
|---|---|---|---|
| Setup: reading the new decisions (D44–D51), the measuring tool, its first runs | — | — | 5 |
| Ulf | 0.3 | 0.4 | C1 and C4 reworded; wound now a spear |
| Kolbeinn | 0.3 | 0.1 | labels only |
| Hallr | 0.3 | 0.2 | C2 reworded |
| Asa | 0.2 | 0.4 | C2, C3, C4 reworded |
| Sigvaldi | 0.2 | 0.6 | C2, C4, W1, W2, W3 reworded; red-herring explanations rewritten |
| Hakon | 0.2 | 0.1 | labels only |
| Grim | 0.2 | 0.2 | C3 reworded |
| Brand | 0.2 | 0.3 | C3, C4, W1 reworded |
| Freydis | 0.2 | 0.1 | truth line only |
| Hakon, returned (both variants) | 0.3 | 0.1 | labels only |
| Egil | 0.2 | 0.1 | W2 reworded |
| Ragna | 0.2 | 0.1 | labels only |
| Ketil | 0.2 | 0.1 | W2 reworded |
| Shared text: pin results, mentor comments, Huginn, dawn, dusk, ending | 2.5 | — | not per encounter |
| Verification: re-measuring, the strictness re-check, caption widths | — | 1.0 | counts as verification (D12) |

Total about 14 minutes of wall-clock time. The per-encounter split is the share of that time spent
on each soul, so treat values under a minute as estimates rather than measurements.
