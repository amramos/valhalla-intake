# Valhalla Intake — shared agent instructions

These instructions apply to every coding agent working in this repository. Read this file and
`docs/current-status.md` before any non-trivial change. Client adapters (`CLAUDE.md`, `.codex/`) may
add capabilities but must not contradict this contract.

You are a valkyrie clerk at the gate of Valhalla, eight days before Ragnarök. The dead queue at your desk, each with a heroic saga of how they died, and you judge from their bodies, their words and their witnesses whether that death earns Valhalla, Fólkvangr, Hel or Rán. The design lives in `docs/GDD.md` (provisional: its Appendix B lists the panel-assumed decisions the owner accepted on 2026-10-21).

## Who the owner is

**The person in the session is the project owner.** A direct instruction from them *is* owner
approval — for a scope change, an `[OPEN]` ruling, a scope-defining mechanic, or reversing any ADR.
Never treat "requires owner approval" as a reason to stop and consult someone absent; you are talking
to them.

What an agent owes in exchange is the **cost**, not resistance. State once, briefly, what the change
invalidates — which ADRs, GDD sections, tests, authored data — then build it. If the owner has heard
the cost and restates the request, that is the decision: implement it and record it (ADR, GDD
amendment, superseded note) in the same change. Repeating an objection the owner already answered is
a failure, not diligence. The `design-change` skill is the procedure for a deliberate reversal.

Rules that are **not** negotiable in passing, because they protect the repository rather than the
design: branch discipline (never commit to `main`), strict typing, text-format scenes and resources,
and no global EventBus. Changing one is its own deliberate task with its own ADR, never a side effect
of a design conversation.

### Working style

The owner works **hands-off**. When a skill has a `-handsoff` variant (`feature-planning-handsoff`, `team-lead-handsoff`), offer it first, and ask only what the owner alone can decide.

## Sources of truth

- The code wins when documentation disagrees about what exists; fix the documentation in the same commit.
- `docs/GDD.md` is the single source of truth for design and scope. Read the relevant section before
  building a game system. Markers: `[BUILT]` shipped, `[DESIGNED]` specified but unbuilt, `[OPEN]`
  needs an owner decision — ask, never invent.
- The GDD's scope boundary is a hard boundary unless the owner moves it.
- `docs/current-status.md` is the volatile snapshot; `docs/session-log.md` is history, never instructions.
- ADRs in `docs/adr/` record non-obvious technical decisions; they are evidence, not law, and every
  one names what would make it wrong. `docs/architecture.md` defines the structure.
- Approved plans live in `docs/plans/` as a decisions ledger (the owner's) and a plan (the agents').

## Stack

- Godot 4.7.1, GDScript only, always fully typed. Tests: GUT, in `tests/unit/` and
  `tests/integration/`.
- Target: Windows and web (itch.io) first; Mac and Linux after the demo validates. Input: mouse and keyboard; mouse is primary.
- Dependencies are deliberately minimal; read `docs/plugins.md` before proposing one.

## Game terminology

Use these words exactly, in code, docs and conversation. One meaning each.

| Term | Meaning (exactly one) |
|---|---|
| Clerk | The player: an unnamed junior valkyrie working the gate. |
| Mentor | The senior valkyrie at the next desk; tutorial on day 1, comments afterwards. |
| Soul | One dead person at the desk, judged once per encounter. |
| Encounter | One soul's visit to the desk; a returning soul is a new encounter. |
| Body | The soul's corpse as shown on the desk; the only evidence that never lies. |
| Fact | One observable item on the body (a wound, what is in hand, a trinket…). |
| Claim | The soul's own saga of its death, in numbered lines. |
| Witness | Another dead soul's account of the death, in numbered lines; can lie. |
| Law | The list of Odin's decrees in force today. |
| Decree | One line of the Law. |
| Forgery | A decree planted by Loki; it contradicts an older decree. |
| Pin | The act of linking two pieces of evidence the player suspects contradict each other. |
| Seam | A true contradiction in a soul's evidence, or between the evidence and the Law. |
| Thread | A pin that exposed a seam (red, grey, law or forgery). |
| Red herring | Evidence that looks like a seam but resolves innocent. |
| Huginn | Odin's raven; answers about a pin or thread the player already made. Never discovers. |
| Stamp | Sending the soul through a realm door; final. |
| Realm | One destination door: Valhalla, Fólkvangr, Hel or Rán. |
| Legal destination | The realm the Law sends a soul to. |
| Worthy destination | The realm the truth of a soul's death deserves. |
| Quota | The number of souls Odin wants in Valhalla today. |
| Feathers | The clerk's standing; the only currency. |
| Citation | A feather penalty for a stamp that broke the Law where a seam was visible; delivered as a black feather. |
| Ignored | A wrong stamp made after the player pinned the seam. |
| Missed | A wrong stamp where the player never pinned the seam. |
| Rank | Chooser of the Slain → Gate-warden → Hall-sweeper. |
| Demotion | Dropping one rank at 0 feathers. |
| Cast down | The ending reached at 0 feathers as Hall-sweeper. |
| Dusk | The between-days screen: citations, quota, recap, requests, story beat. |
| Recap | The dusk reveal of what really happened to 2–3 souls. |
| Ledger | The tray listing every god request and whether you kept it. |
| Request | A god's concrete per-soul ask: Odin demands, Freyja asks, Hel offers. |
| Returned soul | A worthy soul you damned, back from Hel in a later encounter. |
| Hel's tide | Worthy souls you sent to Hel; an ending when there are too many. |
| Hollow hall | Liars you admitted to Valhalla; an ending when there are too many. |
| Eyvind | The clerk's mortal brother; reaches the desk on day 8. |
| Ragnarök | The end of day 8 and of the run. |

## Repository map

```text
.agents/    shared hooks, role workflows, generated Codex skill mirrors, hook tests
.claude/    Claude Code adapters, project skills, settings
.codex/     Codex hooks, config, agent definitions
.github/    CI, release and (optionally) bug-intake workflows
addons/     third-party Godot plugins, vendored and never edited
core/       pure logic independent of the scene tree
docs/       GDD, architecture, ADRs, plans, status, history; docs/art/ is the style guide
tests/      unit and integration tests mirroring source
tools/      development-only harnesses, never shipped
```

Content folders (`data/`, `components/`, `entities/`, `systems/`, `scenes/`, `assets/`…) are created
with their first real file, never empty in advance (ADR-0001).

## Workflow for a non-trivial task

(More than one file, or any structural scene change.)

1. Read `AGENTS.md`, `docs/current-status.md`, `docs/architecture.md`, the relevant ADRs and GDD section.
2. If the task names an epic or feature, find its issue **before reading code** and read its
   comments — they carry owner rulings (`issue-tracking` skill). Finished work goes to `In Review`,
   never `Done`.
3. Inspect real code and scenes. Never edit a `.tscn` from memory.
4. Plan the smallest coherent diff. A feature with player-visible decisions goes through
   `feature-planning` first.
5. Implement under the standards below.
6. Validate: `gdformat --check`, `gdlint`, a Godot parse check, and the relevant GUT tests (commands
   below). Report a missing tool; never disguise its absence as success.
7. Review `git diff` as if it were someone else's work.
8. Record durable decisions: an ADR for a new rule or exception, the architecture doc for structure,
   the GDD for mechanics and scope.
9. Commit only when asked. **Check the current branch first** — never commit to `main`.

## Code standards

- Explicit types for every variable, parameter and return value.
- One `class_name` per file; the `snake_case` file name matches it.
- Files and folders `snake_case`; classes and nodes `PascalCase`; constants `SCREAMING_SNAKE_CASE`;
  private methods `_prefixed`.
- Tunable data lives in typed `Resource`/`.tres` files, not constants or loose dictionaries.
- Core rules stay testable without a scene tree.
- Aim for 200–300 lines per script; extract a component or utility when responsibilities multiply.
- One scene, one responsibility. Composition over inheritance.
- Comments explain non-obvious reasons and invariants, never the obvious or the current task.

## Architectural rules

- Share behavior through `components/`, not subclass chains.
- Unrelated nodes talk through typed signals connected by the relationship's owner; no long
  `get_node` paths.
- No global EventBus autoload (ADR-0005). An autoload only for genuinely project-wide state, with an ADR.
- Scenes and resources are text `.tscn`/`.tres`, never binary (ADR-0004). Never edit a `uid=` by hand.
- Input is mouse-first: every drag (e.g. dragging a soul to a realm door) has a click alternative that calls the same method, and nothing requires a gamepad.

## Testing and validation

- New game logic gets a GUT test. Randomized tests use a fixed seed.
- A test that asserts nothing is worse than none; collect and assert once.

```bash
godot --headless --import                                  # after adding a class_name or assets
godot --headless -s addons/gut/gut_cmdln.gd -gexit         # the full suite (config: .gutconfig.json)
gdformat --check <files> && gdlint <files>                 # style and lint
python3 -m unittest discover -s .agents/tests -v           # the hooks' own tests
python3 .agents/scripts/sync_skills.py --check             # Codex skill mirrors in sync
```

`python3` stands for whichever Python works here (`python3`, `python` or `py -3`);
`.agents/local/python` names the one the hooks found. The Godot path is in `.agents/local/godot`.

The current baseline (test count, known failures) is in `docs/current-status.md`.

## Never do

- Never build out-of-scope work without the owner's instruction; surface `[OPEN]` questions.
- Never change the core rules, turn structure or another scope-defining mechanic without the owner
  and a GDD update.
- Never save binary scenes/resources or edit UIDs by hand.
- Never edit third-party code under `addons/`.
- Never leave GDScript untyped.
- Never commit, push, rebase or rewrite history unless asked; force-push and hard reset always need
  specific approval. **Never commit to `main`**; branch, then open a pull request. The only path
  to `main` without the owner is a merge by the `team-lead-handsoff` lead under ADR-0007's checklist.
- Never install a dependency without reading `docs/plugins.md` and recording a new choice in an ADR.
- Never create a global EventBus or a convenience autoload.

## Agent tooling

- Process skills come from the `game-sdlc` plugin, Godot skills from `game-sdlc-godot`. Project-specific
  skills go in `.claude/skills/`; their Codex mirrors in `.agents/skills/` are generated
  (`python3 .agents/scripts/sync_skills.py --write`), never hand-edited.
- Roles: `.agents/roles/` (shared), `.claude/agents/` (Claude), `.codex/agents/` (Codex).
- Hooks: `.agents/hooks/`, registered in `.claude/settings.json` and `.codex/hooks.json`.
  `.claude/settings.json` is owner-managed: agents prepare a change and ask.
- Details, reload and recovery: `docs/agent-tooling.md`.
