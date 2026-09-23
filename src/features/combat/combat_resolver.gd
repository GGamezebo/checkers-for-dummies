class_name CombatResolver
extends RefCounted

## Resolves the interaction table between two pawn contact surfaces.


static func resolve(_a: Pawn, a_kind: int, _b: Pawn, b_kind: int, config: GameConfig) -> Dictionary:
	## Returns { a: {...}, b: {...} } effect dicts.
	## Effect keys: damage, impulse_mod, stop_movement, spend_shield, stun_other
	var pair := _normalize(a_kind, b_kind)
	var effects := _table(pair[0], pair[1], config)
	if pair[0] == a_kind:
		return {"a": effects["left"], "b": effects["right"]}
	return {"a": effects["right"], "b": effects["left"]}


static func _normalize(ka: int, kb: int) -> Array[int]:
	## Order: PAWN < SWORD < SHIELD so table is lower-triangle style.
	if ka <= kb:
		return [ka, kb]
	return [kb, ka]


static func _table(left_kind: int, right_kind: int, config: GameConfig) -> Dictionary:
	var empty := _effect()
	match [left_kind, right_kind]:
		[InteractionKind.Kind.PAWN, InteractionKind.Kind.PAWN]:
			return {
				"left": _effect(config.pawn_constant_collision_damage, config.impulse_mod_pawn_vs_pawn),
				"right": _effect(config.pawn_constant_collision_damage, config.impulse_mod_pawn_vs_pawn),
			}
		[InteractionKind.Kind.PAWN, InteractionKind.Kind.SWORD]:
			## Sword hits pawn: pawn takes weapon damage + standard impulse; sword owner stops.
			return {
				"left": _effect(config.attack_damage, config.impulse_mod_standard),
				"right": _effect(0.0, 0.0, true),
			}
		[InteractionKind.Kind.SWORD, InteractionKind.Kind.SWORD]:
			return {
				"left": _effect(config.attack_damage, config.impulse_mod_standard),
				"right": _effect(config.attack_damage, config.impulse_mod_standard),
			}
		[InteractionKind.Kind.PAWN, InteractionKind.Kind.SHIELD]:
			## Shield vs pawn: shield owner 0 dmg / 0.5 / spend; pawn constant / 2x
			return {
				"left": _effect(config.pawn_constant_collision_damage, config.impulse_mod_shield_attacker),
				"right": _effect(0.0, config.impulse_mod_shield_defender, false, true, true),
			}
		[InteractionKind.Kind.SWORD, InteractionKind.Kind.SHIELD]:
			return {
				"left": _effect(0.0, config.impulse_mod_shield_attacker),
				"right": _effect(0.0, config.impulse_mod_shield_defender, false, true, true),
			}
		[InteractionKind.Kind.SHIELD, InteractionKind.Kind.SHIELD]:
			return {
				"left": _effect(0.0, config.impulse_mod_shield_vs_shield, false, true),
				"right": _effect(0.0, config.impulse_mod_shield_vs_shield, false, true),
			}
		_:
			return {"left": empty, "right": empty}


static func _effect(
	damage: float = 0.0,
	impulse_mod: float = 1.0,
	stop_movement: bool = false,
	spend_shield: bool = false,
	stun_other: bool = false,
) -> Dictionary:
	return {
		"damage": damage,
		"impulse_mod": impulse_mod,
		"stop_movement": stop_movement,
		"spend_shield": spend_shield,
		"stun_other": stun_other,
	}


static func compute_knockback_impulse(base_impulse: float, hp: float, impulse_mod: float) -> float:
	## Final impulse = BaseImpulse * (1 + HP/100) * impulse_mod
	return base_impulse * (1.0 + hp / 100.0) * impulse_mod
