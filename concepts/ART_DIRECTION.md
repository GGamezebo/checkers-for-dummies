# Checkers for Dummies — Visual & Design Concept

Canonical design reference for the AI. Match this folder before restyling arena, HUD, or combat rules.

**Full game TZ (mechanics):** [`doc/TZ_CORE.md`](../doc/TZ_CORE.md)

**Not shipped.** See `.cursor/rules/concepts.mdc`. Playable art goes under `assets/` or `src/`. Runtime palette: `src/common/neon_palette.gd`.

## Recipe

| Piece | Source |
|-------|--------|
| **Arena layout + HUD** | `arena_layout_mockup.png` — layout only (joystick left, buttons right) |
| **Combat interactions** | `interaction_table.png` — pawn / sword / shield outcomes |
| **Look** | Dark void + cyan/magenta neon (not toy-green arena) |

## Mood

Quiet dark arena: deep void, muted teal/rose accents, soft bloom — stylish, not flashy.

## Palette

| Token | Hex | Use |
|-------|-----|-----|
| Void | `#05060F` | Sky / menu |
| Floor | `#0C1018` | Arena pad |
| Floor edge | `#2A6A78` | Thin rim (low emission) |
| Barrier OK → bad | `#2B7A88` → `#A88B3A` → `#A83A55` | Perimeter |
| P1 | `#3DB8C8` | Teal pawn |
| P2 | `#C84A6A` | Rose pawn |
| Shield / Attack | `#4A6FA8` / `#B85070` | FX + buttons |
| Aim | `#C8B45A` | Slingshot arrow |
| UI text | `#C8D4E0` | HUD |

Keep emission/bloom **low**. Prefer readable silhouettes over glow halos.

## Layout (required)

1. **Arena** — dark pad + cyan rim; camera top-down  
2. **Abyss** — void outside; fall = death  
3. **Barrier ring** — neon segments; cyan → amber → magenta as HP drops; gaps at 0  
4. **HUD left** — dark glass joystick with cyan ring  
5. **HUD right** — round neon Shield + Attack  
6. **Top** — lives in icy UI text  

### Slingshot feedback

- Pull → **yellow neon** aim arrow opposite to stick; length ∝ charge

## Combat / mechanics

Unchanged — see `doc/TZ_CORE.md` and interaction table.

## When updating this doc

Palette or mood changes → update this file + `.cursor/rules/visual-concept.mdc` + `NeonPalette` in the same task.
