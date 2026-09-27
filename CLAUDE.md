# Checkers for Dummies — Claude Code guide

Top-down 3D arena duel (Godot **4.7**, Mobile renderer): slingshot pawns, shield/attack, destructible barriers, fall into abyss = death. Architecture ported from `quizmatik` (HFSM app flow, battle FSM, Resource signal buses, feature folders, no autoloads).

Prefer the smallest change that fits existing patterns. Do not invent parallel systems.

Godot 4.x only: `@export`/`@onready`, `signal.connect(cb)`, `instantiate()`, typed GDScript, `Input` actions.

Path-scoped details live in `.claude/rules/` (loaded automatically when touching matching files).

## Run

Open in Godot 4.7+, F5 (`main.tscn`). Any scene must also run alone via F6. No test suite / CLI build.

## Source of truth

- **Game design:** `doc/TZ_CORE.md` (Russian) is canonical — on conflict with code, the TZ wins; section → code map at its end.
- **Look & interaction table:** `concepts/ART_DIRECTION.md` + frames (AI reference only, see below).

## Stable references (critical)

Avoid hardcoded `res://` strings that break when files move.

- Prefer `class_name` + typed use over `preload("res://path/script.gd")`
- Prefer `@export` / `@export_file` / PackedScene assigned in the editor
- Do not add new path constants for scripts/resources unless no other option (document why)

## Target platforms (critical)

**Mobile** first (touch joystick + buttons), then **desktop**, later **HTML5**.

- Design every control/UI for touch first, then mouse/keyboard; large hit targets, readable in phone landscape, clean on 16:9
- InputMap actions (`attack`, `shield`, `move_*` debug keyboard, `ui_*`) over hard-coded keys; on-screen joystick is the primary move input
- Mobile renderer — keep physics/FX light
- Platform-specific code behind `OS.has_feature(...)` — do not fork gameplay

## #1 Scene isolation (critical)

**Every scene must open and run alone in the editor (F6) without crashes**, with no parent context.

- Bake safe defaults into `.tres` and `@export` them on the scene
- Parents **override** at runtime via events / `initialize(data)`
- No required autoloads, parent, or sibling scenes
- New dependency? Ask: *can this scene still F6 isolated?*

## Folders

| Path | Role |
|------|------|
| `main.tscn` → `src/game/main.gd` | HFSM bootstrap host |
| `src/game/scenes/` | Screens: `app_root`, `menu`, `game`, `post_battle` |
| `src/features/` | Isolated gameplay features (pawn, shield, attack, arena, barrier, abyss, joystick, player_controller, ai, combat) |
| `src/common/` | Project-shared Resources (`GameConfig`, `NeonPalette`) |
| `src/ui/` | Shared UI widgets (empty for now) |
| `core/` | Project-agnostic code only (FSM, HFSM, EventListener, shackers, window stack, ResourceUtils) |
| `assets/` | Runtime shared art/audio (not created yet) |
| `concepts/` | AI style/design reference only — never used by the game |
| `doc/` | Project docs (full TZ); Godot-blind via `doc/.gdignore` |

Ignore for gameplay work: `addons/`, `.godot/`, `.cursor/`, `.claude/`, `doc/`, `concepts/`.
Export never packs: `concepts/`, `doc/`, `.cursor/`, `.claude/`, `.godot/`, `.git/` — keep `concepts/.gdignore`, `doc/.gdignore`.

## Layer contracts

- **`src/features/`** — one folder = one feature; deps stay inside; public surface = signals `ev_*`, `setup`/`initialize`, exported PackedScenes. No importing another feature's internals (compose in the game scene). Exception: `src/features/combat/` (`InteractionKind`, `CombatResolver`) may be used by pawn/shield/attack.
- **`core/`** — must not depend on `src/` (no `GameConfig`, `Pawn`, project scenes). Needs this-game types → belongs in `src/`.
- **`src/game/scenes/`** — orchestration only: wire features + config, own screen flow/FSM/UI. Reusable feature guts → `src/features/`.

## UI — editor-first (critical)

- Build UI in the editor (nodes in `.tscn`); scripts bind `@export` refs, update state, connect signals
- Dynamic lists: template `.tscn` + `instantiate()`; avoid `*.new()` UI trees except rare runtime overlays (aim arrow, debug)
- OK programmatic: 3D arena/barrier generation, pawn mesh bootstrap, tiny runtime HUD bits

## Flow

```
Menu --ev.start_game--> Battle --ev.exit_game--> PostBattle
PostBattle --ev.return_to_menu--> Menu
PostBattle --ev.start_game--> Battle (retry)
```

- App phases: HFSM (`src/game/hfsm/app_hfsm.json`) via `main.gd` (only creates HFSM + scene host); `app_root` bridges `RootEvents` → `hfsm.add_event`; phase scenes via `HfsmScenePaths`
- In battle: `GameEvents` + `GameManager` FSM (`countdown` → `game` → `end_game`), not HFSM
- Combat table: `CombatResolver` + `InteractionKind` (pawn / sword / shield)
- Death = fall into `Abyss` (not HP=0). Lives in `PlayerController`; match ends when a player hits 0 lives. No ad-hoc win/lose flags outside the FSM.

## Placement

- Gameplay unit → `src/features/{name}/`
- Screen / flow → `src/game/scenes/{name}/`
- Project-shared Resource → `src/common/`
- Shared UI widget → `src/ui/`
- Generic utility → `core/lib/`
- Tuning knobs → `GameConfig` (`.gd` + `.tres`), never magic numbers in features

## Cheap-change heuristics

1. Match the nearest existing file; copy its wiring (`@export`, signals `ev_*`).
2. Prefer editing one layer: data (`.tres`) → feature → scene orchestration.
3. Before adding to `core/`: confirm zero `src/` imports.
4. New scene dependency → default `.tres` on the scene + optional runtime override.
5. Do not edit `addons/` or binary assets casually.
6. Interaction-table changes → `CombatResolver` + update `concepts/ART_DIRECTION.md` / interaction mockup if design changes.
7. No drive-by renames without explicit request.

## `concepts/` — AI design reference only

- Before changing arena/HUD/combat look or interaction rules, **read** `concepts/ART_DIRECTION.md` and relevant frames
- **Never** reference `res://concepts/...` (`.tscn`, `.tres`, `.gd`, preload, `@export`, `ResourceLoader`, inspector)
- Never copy/generate from `concepts/` into the running game, never put game files there
- Needed in play → recreate a separate file under `assets/` or the feature/scene folder

## Not implemented yet (don't assume they exist)

- **Localization:** none. UI strings are hardcoded in `.tscn` and mixed RU/EN (HUD `Щит`/`Атака`, menu `PLAY`, post-battle `AGAIN`/`MENU`). No `tr()`, no translation CSV. Don't add a localization system unless asked; if asked, use Godot's built-in `TranslationServer` + CSV (`*.translation` is already gitignored) and keep strings in `.tscn` auto-translated.
- **Tutorial / onboarding:** none, not in the TZ either.
- `assets/`, `addons/`, `WindowStackManager` usage in menu, export presets.

## Keep rules accurate (always)

When a change alters structure, contracts, or placement conventions, update the rules **in the same task**:
this file, `.claude/rules/`, and the mirrored `.cursor/rules/` (both tools are used — keep them in sync).

Update when: new/renamed folder under `src/`/`core/`/`tools/`; new feature, event bus, or FSM state; isolation / `core/` boundary / Resource-default contract changes; editor-first UI policy; target platforms; export ignores; HFSM semantics or JSON conventions; combat table / pawn lifecycle; entry point wiring; visual conventions; a convention deliberately replaced; localization or tutorial added.

How: patch the smallest relevant file; one concern per file; paths + must/never over prose; fix or delete wrong rules — no contradictions, no duplicated maps, no one-off hacks as architecture.
