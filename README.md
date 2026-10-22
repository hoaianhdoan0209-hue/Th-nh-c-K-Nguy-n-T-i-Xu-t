# GAME 9 — THÁNH ƯỚC: KỶ NGUYÊN TÁI SINH

> Original 2D action RPG inspired by knightly vows, lost divinities and restoration of a broken world. Gameplay reference: the progression and exploration feel of Ngọc Rồng Online. **All setting, characters, story, and game assets are original.**

## Project status

**Vertical slice in development, not a release.** Godot 4 / GDScript. First milestone: playable opening **Làng Tro Sáng** (Village of Embers), then Rừng Tàn Quang and Đền Phong Ấn.

This repository belongs to Game 9. The user's ratings for prior Game 8 were 8/10 graphics and 7/10 overall. Game 9's priority is deeper interconnected systems, not static art.

## Playable opening update — 2026-10-22

- Choosing a path now starts a four-line return-of-the-king opening with Aurel, an original god of vows. The existing game title is preserved.
- Aurel follows the hero in the world. **R / THẦN** opens advice for the current quest stage; companion state survives save/load, including older saves.
- Movement accelerates and brakes; jumping supports 120 ms coyote time and a 140 ms input buffer. Attack arcs, floating damage/XP and lightweight character motion provide feedback.
- Original project-authored SVG art remains placeholder art. No NRO executable code, sprites or server endpoints were imported from the supplied RAR. This remains a single-player vertical slice, not a live MMO.
- Local Godot 4.3 import, gameplay parse and the expanded **34-assertion** chapter/combat/companion/save test pass. Manual full chapter, real phone play and production balance remain unverified.

| Asset | Description | In-game size | Path | Origin |
| --- | --- | --- | --- | --- |
| Aurel | Floating divine companion | 100 × 116 px | `assets/aurel.svg` | Original project-authored SVG; no paid generation |
| Existing heroes and NPCs | Three paths and village cast | Native SVG sizes, roughly 114 × 146 px | `assets/*.svg` | Existing project-authored placeholder art |
| Existing zone backdrops | Village, forest, temple | 1400 × 720 px each | `assets/bg_*.svg` | Existing project-authored placeholder art |

## Target gameplay loop

Choose ONE of three paths and name the character → meet elder → recover three fragments → repair broken sword → repel Vực creatures → purify an altar → defeat a boss → return and receive the first Sacred Covenant. A quest changes the world; rewards modify combat and travel.

- Vệ Ước: sword + timed defense, resilient.
- Tinh Thuật Sư: ranged magical marks, fragile.
- Thánh Y: purification and restorative magic, balanced.
- Side-scrolling movement, jump, ground/platform collision, normal combos, skill with MP/cooldown, dash, enemies with telegraphed attacks.
- NPC dialogue, inventory, item pickup, quest log, shops, level/XP, save/load, on-screen mobile input.
- THREE named linked locations, four NPCs, three monster variations and one boss are the content target, not automatically claimed complete by this paragraph.

## How to run

Install **Godot 4.x** (standard/GDScript build). Import `project.godot` in the editor and press F6/F5 or run:

```sh
godot --path .
```

Validation once Godot is available:

```sh
godot --headless --path . --import
godot --headless --path . --quit-after 60 2>&1 | tee godot-log.txt
grep -E 'SCRIPT ERROR|Parse Error' godot-log.txt && exit 1 || true
```

**iPhone note:** Godot native desktop project is NOT itself an iOS/Safari URL. Web export, hosting on HTTPS and manual Safari touch tests are separate gates. Do not claim iPhone compatibility or release until completed.

## Godogen — highest-priority pipeline

Generator: https://github.com/htdt/godogen (MIT). Choice: `--engine godot-gdscript --agent codex`. The source repository produces development instructions, not a ready-made game. Its published runtime guide is kept alongside project source in `GODOGEN_WORKFLOW.md`. To truly use Godogen on a workstation, clone its upstream and run:

```sh
./publish.sh --engine godot-gdscript --agent codex --out /path/to/this/repo
```

Do not add `--force` (it would delete this project). Configure local `godogen_assets` if available. The asset-generation subsystem is NOT claimed to have run until actual generation logs/assets are present. No paid calls without approval.

Asset generation reference: https://github.com/0x0funky/agent-sprite-forge . Heretic (https://github.com/p-e-w/heretic) is an LLM-ablation tool, **not** a game-generation engine, and is deliberately not part of runtime gameplay.

## Honest validation ledger — 2026-10-19

| Gate | Status |
| --- | --- |
| GitHub source commits and original assets | **Committed** |
| Godot 4.3 import/type/parser + headless launch | **PASS** — [validation run](https://github.com/hoaianhdoan0209-hue/Th-nh-c-K-Nguy-n-T-i-Xu-t/actions/runs/39287955034) |
| Scripted chapter quest/boss/items/save/load test | **PASS** — 27 assertions including missing-sprite audit, input movement, class skills and dodge |
| Browser/Web export on GitHub Actions | **PASS** — [HTML/WASM/PCK artifact](https://github.com/hoaianhdoan0209-hue/Th-nh-c-K-Nguy-n-T-i-Xu-t/actions/runs/39288694512) |
| GitHub Pages HTTPS publication | **DEPLOYED** — [Game 9 browser URL](https://hoaianhdoan0209-hue.github.io/Th-nh-c-K-Nguy-n-T-i-Xu-t/) via [successful GitHub Actions run](https://github.com/hoaianhdoan0209-hue/Th-nh-c-K-Nguy-n-T-i-Xu-t/actions/runs/39289787384). Real Safari playtest remains pending. |
| Full 10-minute hands-on manual playtest | **NOT YET VERIFIED** |
| Real iPhone Safari end-to-end controls | **NOT YET VERIFIED** |

GitHub Actions passing shows the source imports, exports and its scripted state machine passes. It does **not** certify real mobile ergonomics, finished animations, balanced boss combat or the feel of NRO Online. Pages deployment succeeded in GitHub Actions. URL availability was confirmed by GitHub deployment logs; a separate real-browser iPhone playtest is still required.

## Source conventions

- `project.godot`: engine configuration.
- `scenes/Main.tscn`: entry scene.
- `scripts/Game.gd`: game loop, world, quests and combat.
- `assets/`: only game-loaded art, no screenshots disguised as assets.
- `docs/`: detailed design and validation.

See `docs/OPENING_AND_SYSTEMS.md` for the signed-off brief and gameplay acceptance tests.

Licensing: original code and generated project work under MIT (see `LICENSE`). Other projects are cited, not copied wholesale.
