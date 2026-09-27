---
paths:
  - "src/features/**/*"
---

# Features (pawn / combat / input)

## Feature folders

| Folder | Role |
|--------|------|
| `pawn/` | Core `RigidBody3D` piece: HP, slingshot, flight, stun, owns shield+attack |
| `shield/` | Charges (spent on activation), recharge, front-hemisphere block, optional stun on contact |
| `attack/` | Timed forward collider (sword); reports hits to `Pawn.resolve_interaction` |
| `combat/` | `InteractionKind` + `CombatResolver` (interaction table) |
| `player_controller/` | Input → pawn (gated by `set_input_enabled`); lives; respawn facing center; lose at 0 lives |
| `ai/` | `AiBrain` — drives P2 controller (sling / attack / shield) |
| `joystick/` | `SlingshotJoystick` — pull back, release → opposite impulse |
| `arena/` | Square pad + rectangular barrier perimeter (`barrier_segment_count` / 4 per side) + abyss |
| `barrier/` | Segment HP, elasticity bounce, enemy-knock damage only |
| `abyss/` | Below-arena catch volume → `Pawn.die()` |

## Must

- Keep feature deps inside the feature folder when possible
- Public API: `setup`/`initialize`, signals `ev_*`, PackedScene spawn
- Read tuning from `GameConfig` passed into `setup`/`initialize`
- Physics layers: pawn=1, attack=2, shield=3, barrier=4, abyss=5, world=6

## Joystick / movement

- Stick value ∈ [-1, 1] per axis; length clamped to ≤ 1
- Release returns stick to center and emits `ev_released(value)`
- Launch direction = **opposite** of pull (`MaxImpulse * stick_length`)
- Player may slingshot only when stopped (speed ≤ `pawn_min_flight_speed`) and not stunned/in-flight

## Avoid

- Feature A importing Feature B private nodes/scripts (except `combat/` helpers)
- Hardcoding impulse/damage/charge numbers — use `GameConfig`
- Renaming `SlingshotJoystick` back to `VirtualJoystick` (native class clash in Godot 4.7+)
