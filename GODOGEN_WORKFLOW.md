# Godogen integration contract for Game 9

Upstream: https://github.com/htdt/godogen (MIT).

Choose `godot-gdscript` and `codex`. Godogen is a GENERATOR RUNTIME + ASSET WORKFLOW, not a ready-made game engine. Use Godot 4 native 2D for this title. Obtain the complete upstream setup and skills by actually running:

```sh
git clone https://github.com/htdt/godogen.git
cd godogen
./publish.sh --engine godot-gdscript --agent codex --out /path/to/game9-repository
```

Do NOT use `--force`; it removes existing files. Then review `AGENTS.md`, `godot-gdscript.md`, `.agents/skills/asset-gen/SKILL.md`. Optional local asset generation from `htdt/godogen_assets` requires GPU and setup. Paid generation needs explicit user approval.

**Current truth:** Upstream README, publish.sh, engine guide, runtime and asset skill were actually inspected via GitHub connector. The publish.sh process has NOT run in the current environment. This document integrates the rules while distinguishing their adoption from tool execution.

Development loop:
1. Edit gameplay and update README with inventory of what actually works.
2. Build real importable Godot scenes and interactive scripts with original assets.
3. Run Godot import and GDScript parser checks; grep logs for SCRIPT ERROR.
4. Watch an actual input-driven 10-minute quest-to-boss playthrough.
5. Record real gameplay footage after successful run.
6. For mobile, export web or iOS build, host HTTPS, test real Safari touch interaction.
7. Only mark features complete after observed proof.

Sprite references: https://github.com/0x0funky/agent-sprite-forge .
All art currently in `assets/` is project-authored vector placeholder art, NOT alleged AI-generated sprite sheets.

Never claim: a build succeeded without Godot, an iOS Safari test succeeded in desktop Chromium, or Godogen has executed without logs.
