class_name InteractionKind
extends RefCounted

## What part of a pawn is colliding right now.

enum Kind {
	PAWN,
	SWORD,
	SHIELD,
}


static func name_of(kind: int) -> String:
	match kind:
		Kind.PAWN:
			return "pawn"
		Kind.SWORD:
			return "sword"
		Kind.SHIELD:
			return "shield"
		_:
			return "unknown"
