---
paths:
  - "src/game/scenes/game/**/*"
---

# Game scene / battle

## Ownership

- Orchestration: `game.gd` builds arena, spawns `PlayerController`s, wires HUD
- Live `game_config_default.tres` on the scene = **standalone defaults** (must F6 alone)
- States: `GameManager` FSM only (`countdown` / `game` / `end_game`)
  - `countdown` → `on_countdown_tick(n)` on the scene; player input stays off until `on_match_start`
  - `end_game` → `on_match_result(data)` (input off, banner), holds `end_game_delay`, then `on_match_end`
- Combat table: `src/features/combat/combat_resolver.gd` + `interaction_kind.gd`
- Features: compose from `src/features/` — scene wires and reacts to `ev_*`

## Change guide

| Goal | Touch |
|------|--------|
| Win/lose / transitions | FSM states + `FSMGameEvents` + `GameManager.request_end` |
| Lives / respawn | `PlayerController` |
| Pawn HP / knockback / flight / stun | `Pawn` |
| Interaction table (pawn/sword/shield) | `CombatResolver` (+ update concepts) |
| Slingshot move | `Pawn.apply_slingshot` + `SlingshotJoystick` |
| AI opponent | `AiBrain` (`src/features/ai/`) + `GameConfig` AI group |
| Attack / shield | `AttackEntity` / `ShieldEntity` |
| Arena size / barrier perimeter | `Arena` + `GameConfig` arena/barrier fields |
| Barrier damage / bounce | `BarrierSegment` |
| Fall death | `Abyss` |
| HUD only | `game.tscn` HUD nodes — listen to controller/`GameEvents`, don't own combat |

## Combat contracts (critical)

- Final knockback: `base_impulse * (1 + HP/100) * impulse_mod`
- Impulse vector: from attacker center → defender center
- HP **accumulates** damage (higher HP → harder knockback); death = abyss, not HP=0
- Flight: enemy knockback raised speed above `pawn_min_flight_speed` → blocks input until slow
- `was_knocked_by_enemy`: set by knockback; cleared on leaving flight, on own slingshot, or after `knock_flight_grace` if no flight started
- Stun: queued if in flight **or freshly knocked**; applied after leaving flight; timer does not reset on new flight. Table stuns apply after both sides' knockbacks
- Shield: **activation spends 1 charge** (TZ); block / table interaction just ends the active shield (`consume()`), no second charge
- Shield block: active + `attack_dir · forward <= 0` → no damage
- Barrier damage only if `pawn.was_knocked_by_enemy`; amount = pre-contact speed (`Pawn._prev_planar_velocity` — contact signals fire after the solver)
- After barrier bounce: velocity reflected about segment normal, `*= barrier_elasticity`

## Constraints

- Exit battle via `root_events.ev_exit_game` with `{ "winner_id": int, "vs_ai": bool }`
- Speeds / charges / damage / arena size come from `GameConfig`, not hardcode
- Prefer small `RefCounted` helpers over growing `game.gd`
- Touch joystick + attack/shield buttons required; keyboard fallback OK for P2/dev
