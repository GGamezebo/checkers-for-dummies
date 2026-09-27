---
paths:
  - "src/game/scenes/**/*"
  - "src/ui/**/*"
  - "src/features/**/*"
  - "src/common/neon_palette.gd"
---

# Visual concept

Before changing arena/HUD look, **read** `concepts/ART_DIRECTION.md`. Never wire from `concepts/`. Use `NeonPalette` (`src/common/neon_palette.gd`) for shared colors/materials.

Must match:

- **Mood:** quiet dark void + muted teal/rose accents — stylish, **not** flashy bloom
- **Arena:** dark pad; thin low-emission rim; barriers muted cyan → amber → rose when damaged
- **Pawns:** P1 teal `#3DB8C8`, P2 rose `#C84A6A`; soft emission, weak OmniLight
- **HUD:** dark panels, thin accent borders (not glowing discs)
- **Glow:** environment bloom low (`intensity` ~0.35, `bloom` ~0.05); emission energies mostly `< 0.7`
- **Layout:** joystick left, buttons right (same as mockup); rectangular arena with barrier segments on the edges
- **Readability without text:** aim arrow amber when launch is possible, muted grey when not; pawn label = accumulated damage `%` heating toward rose; stun = amber blinking top ring; hit = short white-ish body flash; light camera shake scaled by knockback
- **HUD state:** shield button shows charge pips (`●●○`), dims at 0; countdown / result banner centered

Reference frames (layout only): `concepts/arena_layout_mockup.png`, `concepts/interaction_table.png`.
