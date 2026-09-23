# Checkers for Dummies — Visual & Design Concept

Canonical design reference for the AI. Match this folder before restyling arena, HUD, or combat rules.

**Full game TZ (mechanics):** [`doc/TZ_CORE.md`](../doc/TZ_CORE.md)

**Not shipped.** See `.cursor/rules/concepts.mdc`. Playable art goes under `assets/` or `src/`.

## Recipe

| Piece | Source |
|-------|--------|
| **Arena layout + HUD** | `arena_layout_mockup.png` — green arena, abyss, barrier ring, joystick + Attack/Shield |
| **Combat interactions** | `interaction_table.png` — pawn / sword / shield collision outcomes |
| **Movement** | Slingshot: pull joystick opposite to desired launch direction |

## Mood

Toy arena brawler: readable top-down silhouettes, clear team colors, soft arcade — not grimdark, not neon cyberpunk.

## Palette (starting)

| Token | Approx | Use |
|-------|--------|-----|
| Arena green | `#479E52` | Playable floor |
| Abyss | `#0E1A38` | Outside / death zone |
| Barrier OK | `#40BF59` | Intact perimeter |
| Barrier hurt | `#E8C84A` → `#D94A3A` | Damaged → critical |
| P1 blue | `#3373F2` | Player 1 pawn |
| P2 red | `#E64033` | Player 2 pawn |
| Joystick ring | `#8CBFE6` | Move zone |
| Stick / attack | `#C03333` | Stick knob, attack CTA |
| Shield | `#408CE6` | Shield button / active shield mesh |

Avoid as primary look: purple-on-white AI gradients, dense dashboard HUDs, tiny finger targets.

## Layout (required)

Match `arena_layout_mockup.png`:

1. **Arena** — vertical/landscape green pad centered in view  
2. **Abyss** — surrounds arena; falling in = death  
3. **Barrier ring** — many segments on the perimeter; gaps appear when HP hits 0  
4. **HUD left** — slingshot joystick (zone + stick)  
5. **HUD bottom-center/right** — Shield, then Attack  
6. **Top** — lives / status (not cluttered with stats strips)

### Slingshot feedback

- Neutral: stick centered, no aim arrow  
- Pull: stick moves with finger; **red aim arrow** on pawn points **opposite** to pull; length ∝ charge (0…1)

## Combat table (required)

Match `interaction_table.png` / implement in `CombatResolver`:

| A \\ B | Pawn | Sword | Shield |
|--------|------|-------|--------|
| **Pawn** | Both: const damage, impulse mod 0.5 | — | — |
| **Sword** | Victim: weapon damage + std impulse; attacker: stop | Both: weapon damage + std impulse | — |
| **Shield** | Defender: 0 dmg, mod 0.5, spend charge; Attacker: const dmg, mod 2× | Defender: 0 dmg, spend, mod 0.5; Attacker: mod 2× | Both: 0 dmg, mod 2×, spend both |

Cells above the diagonal are symmetric (same pair, swapped roles).

### Damage / knockback

- On hit: `HP += damage`  
- `final_impulse = base_impulse * (1 + HP/100) * impulse_mod`  
- Direction: attacker center → defender center  
- Death: abyss (lives via `PlayerController`)

### Shield block (separate from table)

If shield active and `attack_direction · pawn_forward <= 0` → damage nullified, charge spent.

### Barrier

- Damaged only when hit by a pawn that was **enemy-knocked**  
- Damage ≈ impact speed  
- Bounce: `speed *= elasticity`  
- HP 0 → segment removed (gap to abyss)

## Archived (do not implement yet)

- Jump  
- Fall-strike / overhead colliders  
- “Push only when stopped” is **active** (already in movement rules)

## When updating this doc

If combat table, HUD layout, or palette change in design — update this file **and** the matching frame(s) in the same task. Keep `.cursor/rules/visual-concept.mdc` / `game.mdc` in sync.
