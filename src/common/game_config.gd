class_name GameConfig
extends Resource

## Shared battle/tuning knobs. Mutated in-place; assign one .tres to many @exports.

@export_group("Pawn")
@export var pawn_base_impulse: float = 12.0
@export var pawn_max_impulse: float = 18.0
@export var pawn_linear_damp: float = 2.5
@export var pawn_min_flight_speed: float = 3.0
@export var pawn_constant_collision_damage: float = 8.0
@export var pawn_mass: float = 1.0
@export var pawn_radius: float = 0.45
@export var pawn_height: float = 0.35

@export_group("Shield")
@export var shield_charges: int = 3
@export var shield_recharge_time: float = 4.0
@export var shield_stun_time: float = 0.8
@export var shield_active_duration: float = 0.45

@export_group("Attack")
@export var attack_damage: float = 15.0
@export var attack_duration: float = 0.25
@export var attack_reach: float = 0.85
@export var attack_width: float = 0.7

@export_group("Stun / Flight")
@export var stun_time: float = 1.0

@export_group("Player")
@export var player_lives: int = 3
@export var respawn_delay: float = 1.2

@export_group("Arena")
@export var arena_half_size: float = 6.0
@export var barrier_segment_count: int = 16
@export var barrier_hp: float = 40.0
@export var barrier_elasticity: float = 0.65
@export var barrier_height: float = 0.8
@export var barrier_thickness: float = 0.35

@export_group("Impulse modifiers")
@export var impulse_mod_pawn_vs_pawn: float = 0.5
@export var impulse_mod_standard: float = 1.0
@export var impulse_mod_shield_defender: float = 0.5
@export var impulse_mod_shield_attacker: float = 2.0
@export var impulse_mod_shield_vs_shield: float = 2.0
