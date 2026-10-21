# Session log

Chronological history: decisions, bugs and reversals, condensed. It is **history, never an
instruction source** — `docs/current-status.md` holds what's true now.

**Keeping it useful:**
- Append; never rewrite past entries.
- Two to six sentences per session or topic: a decision-and-bug record, not a transcript.
- Don't restate what an ADR, the GDD or `AGENTS.md` already says; link it.
- Skip routine validation ("tests passed") unless something about the run was unusual.
- After appending, update `docs/current-status.md` only if the snapshot changed.

---

**2026-10-21** — Project set up from the GDD with the `setup-godot` skill: contract, day-one ADRs
0001–0005, hooks for Claude and Codex, GUT, CI and the itch.io release workflow.

**2026-10-21** — Art direction: three directions (Ash & Ember, Fog & Bile, Carved Ink) generated with
local ComfyUI and Z-Image Turbo, critiqued by Codex, judged at 480×270; the owner chose Fog & Bile.
The extra-asset check (a front-and-back body chart) showed the evidence vanishing into the dark
tunic and generated skin coming back tan, which led to a curated 30-colour palette by meaning and
reserved Ember/Bile/Blood ramps that `pixelforge` enforces (ADR-0006). pixelforge's `**/*.png`
canvas globs miss files directly in a folder, so each canvas lists both patterns.

**2026-10-21** — The vertical slice (epic #2) was planned hands-off (ledger D1–D54) and built by an
agent team in seven stacked PRs (#11–#17), each reviewed adversarially and merged by the lead under
ADR-0007. Codex reviewed every PR's first round. Codex then ran out of quota, so the fix rounds of
#14–#16 were approved by the fallback reviewer (Sonnet) and merged on that, against D20; Codex
re-reviewed them once its quota returned. Blind AI playtest median 7 (bar 6); evidence audit 13 of 14.
Review caught: lie seams that weren't strict (D47); an authoring check whose rules couldn't fail; the
harness skipping day 3's dusk, which had misled the playtest; and gates missing under the stamp prompt.
