# tools/content/

Development-only content tools, **never shipped**.

- `build_content.gd`: rebuilds every content `.tres` under `data/` from its transcription of the
  matrix (`content_souls.gd`: the 14 encounters; `content_text.gd`: the days and the shared text
  of section A). The matrix is the source; change the transcription, then rebuild.
- `measure_lines.gd`: measures every claim and witness line of `docs/plans/vertical-slice-matrix.md`
  in m5x7 at 16 px, prefix included, against the D50 cap (132 px), the way the evidence panel
  measures it. It exits 1 when a line runs over. With a second argument it measures a file of
  candidate lines instead.

```bash
godot --headless --path . -s tools/content/measure_lines.gd
godot --headless --path . -s tools/content/measure_lines.gd -- docs/plans/vertical-slice-matrix.md candidates.txt
godot --headless --path . -s tools/content/build_content.gd
```
