# Checkers for Dummies

Top-down 3D arena duel. Architecture ported from `quizmatik` (HFSM app flow, battle FSM, Resource signal buses, feature folders, no autoloads).

## Run

Open the project in Godot 4.7+ and press F5 (`main.tscn`).

## Controls

| Player | Move | Attack | Shield |
|--------|------|--------|--------|
| P1 | Virtual joystick (slingshot: pull back → release forward) | Атака / `F` | Щит / `G` |
| AI | Auto (sling / attack / shield) | — | — |

Toggle / tune AI in `GameConfig` (`ai_enabled`, aggression, aim jitter, ranges).

## Architecture

- `core/` — HFSM, FSM, EventListener, ResourceUtils, window stack (from quizmatik)
- `src/game/` — app shell (Menu → Battle → PostBattle)
- `src/features/` — Pawn, Shield, Attack, Arena, Barrier, Abyss, Joystick, PlayerController, CombatResolver
- Shared `.tres` buses: `RootEvents`, `GameEvents`, `GameConfig`
- Agent rules: `.cursor/rules/`
- Design reference (AI only): `concepts/` — see `concepts/ART_DIRECTION.md`
- Full game TZ: [`doc/TZ_CORE.md`](doc/TZ_CORE.md)
