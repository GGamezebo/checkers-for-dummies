class_name Pawn
extends RigidBody3D

## Core playable piece. Impulse movement, HP knockback, stun/flight gates inputs.

signal ev_hp_changed(hp: float)
signal ev_died(pawn: Pawn)
signal ev_flight_changed(in_flight: bool)
signal ev_stun_changed(stunned: bool)

@export var player_id: int = 0
@export var team_color: Color = Color(0.2, 0.45, 0.95)

var hp: float = 0.0
var base_impulse: float = 12.0
var max_impulse: float = 18.0
var min_flight_speed: float = 3.0
var stun_duration: float = 1.0

var is_in_flight: bool = false
var is_stunned: bool = false
var was_knocked_by_enemy: bool = false
var is_dead: bool = false

var shield: ShieldEntity
var attack: AttackEntity
var movement: MovementComponent
var world_label: Label3D

var _config: GameConfig
var _stun_left: float = 0.0
var _pending_stun: float = 0.0
var _body_collider: CollisionShape3D
var _interacted_pairs: Dictionary = {}


func initialize(config: GameConfig, id: int, color: Color, spawn_pos: Vector3) -> void:
	_config = config
	player_id = id
	team_color = color
	base_impulse = config.pawn_base_impulse
	max_impulse = config.pawn_max_impulse
	min_flight_speed = config.pawn_min_flight_speed
	stun_duration = config.stun_time
	hp = 0.0
	is_dead = false
	mass = config.pawn_mass
	linear_damp = config.pawn_linear_damp
	angular_damp = 8.0
	gravity_scale = 1.0
	lock_rotation = true
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
	collision_layer = 1
	collision_mask = 1 | 4 | 8 | 16 | 32  # pawn, shield, barrier, abyss, world
	global_position = spawn_pos
	_build_visual(config)
	_build_components(config)
	body_entered.connect(_on_body_entered)
	ev_hp_changed.emit(hp)


func _build_visual(config: GameConfig) -> void:
	_body_collider = CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = config.pawn_radius
	cyl.height = config.pawn_height
	_body_collider.shape = cyl
	_body_collider.position = Vector3(0, config.pawn_height * 0.5, 0)
	add_child(_body_collider)

	var mesh := MeshInstance3D.new()
	var mesh_cyl := CylinderMesh.new()
	mesh_cyl.top_radius = config.pawn_radius
	mesh_cyl.bottom_radius = config.pawn_radius
	mesh_cyl.height = config.pawn_height
	mesh.mesh = mesh_cyl
	mesh.position = Vector3(0, config.pawn_height * 0.5, 0)
	var body_col := Color(team_color.darkened(0.55).r, team_color.darkened(0.55).g, team_color.darkened(0.55).b, 1.0)
	var mat := NeonPalette.make_emissive(body_col, 0.25)
	mat.emission = team_color.darkened(0.2)
	mat.emission_energy_multiplier = 0.45
	mesh.material_override = mat
	add_child(mesh)

	# Soft top ring
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = config.pawn_radius * 0.55
	ring_mesh.outer_radius = config.pawn_radius * 0.85
	ring_mesh.rings = 12
	ring_mesh.ring_segments = 24
	ring.mesh = ring_mesh
	ring.position = Vector3(0, config.pawn_height + 0.02, 0)
	ring.material_override = NeonPalette.make_emissive(team_color.darkened(0.15), 0.4)
	add_child(ring)

	# Forward marker
	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.1, 0.1, 0.28)
	nose.mesh = nose_mesh
	nose.position = Vector3(0, config.pawn_height * 0.55, -config.pawn_radius * 0.75)
	nose.material_override = NeonPalette.make_emissive(team_color.lightened(0.1), 0.5)
	add_child(nose)

	var glow := OmniLight3D.new()
	glow.light_color = team_color
	glow.light_energy = 0.35
	glow.omni_range = 1.8
	glow.position = Vector3(0, config.pawn_height * 0.7, 0)
	add_child(glow)

	world_label = Label3D.new()
	world_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	world_label.font_size = 48
	world_label.modulate = NeonPalette.UI_TEXT
	world_label.outline_modulate = NeonPalette.VOID
	world_label.outline_size = 8
	world_label.position = Vector3(0, config.pawn_height + 0.55, 0)
	add_child(world_label)
	_refresh_label()


func _build_components(config: GameConfig) -> void:
	movement = MovementComponent.new()
	movement.setup(self, config)
	add_child(movement)

	shield = ShieldEntity.new()
	shield.name = "Shield"
	add_child(shield)
	shield.setup(self, config)

	attack = AttackEntity.new()
	attack.name = "Attack"
	add_child(attack)
	attack.setup(self, config)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_update_stun_and_flight(delta)
	_interacted_pairs.clear()
	_refresh_label()


func _update_stun_and_flight(delta: float) -> void:
	var speed := Vector3(linear_velocity.x, 0.0, linear_velocity.z).length()

	# Flight: speed crossed threshold due to enemy knockback
	if was_knocked_by_enemy and speed > min_flight_speed:
		if not is_in_flight:
			is_in_flight = true
			ev_flight_changed.emit(true)
	elif is_in_flight and speed <= min_flight_speed:
		is_in_flight = false
		was_knocked_by_enemy = false
		ev_flight_changed.emit(false)
		# Apply pending stun strictly after leaving flight
		if _pending_stun > 0.0:
			_apply_stun(_pending_stun)
			_pending_stun = 0.0

	if is_stunned:
		_stun_left -= delta
		if _stun_left <= 0.0:
			is_stunned = false
			_stun_left = 0.0
			ev_stun_changed.emit(false)


func can_accept_input() -> bool:
	return not is_dead and not is_in_flight and not is_stunned


func can_slingshot() -> bool:
	## "ты можешь толкать пешку только когда она остановилась"
	if not can_accept_input():
		return false
	var speed := Vector3(linear_velocity.x, 0.0, linear_velocity.z).length()
	return speed <= min_flight_speed


func apply_slingshot(joystick_vec: Vector2) -> void:
	## joystick_vec in [-1,1]; pull back → fly opposite (slingshot).
	if not can_slingshot():
		return
	if joystick_vec.length() < 0.08:
		return
	var clamped := joystick_vec
	if clamped.length() > 1.0:
		clamped = clamped.normalized()
	# Opposite of pull = launch direction. Joystick Y+ is screen down typically;
	# we map X→X, Y→-Z so pull-down launches forward (+Z or -Z). Keep simple XZ.
	var dir := Vector3(-clamped.x, 0.0, -clamped.y)
	if dir.length_squared() < 0.0001:
		return
	dir = dir.normalized()
	look_at(global_position + dir, Vector3.UP)
	var strength := clamped.length() * max_impulse
	apply_central_impulse(dir * strength)


func try_attack() -> void:
	if not can_accept_input():
		return
	if attack:
		attack.try_activate()


func try_shield() -> void:
	if not can_accept_input():
		return
	if shield:
		shield.try_activate()


func receive_damage(amount: float, from_pawn: Pawn, impulse_mod: float) -> void:
	## Per TZ: damage is ADDED to HP (accumulated), then knockback scales with HP.
	## Death is abyss / lives — not HP reaching zero.
	if is_dead or amount < 0.0:
		return

	# Front-facing active shield can nullify damage
	if from_pawn and shield and shield.is_active:
		var attack_dir := (global_position - from_pawn.global_position)
		if shield.can_block(attack_dir):
			shield.spend_charge()
			# Still apply reduced impulse as defender per table if caller already set mod
			_apply_knockback(from_pawn, impulse_mod)
			return

	hp += amount
	ev_hp_changed.emit(hp)
	_apply_knockback(from_pawn, impulse_mod)


func _apply_knockback(from_pawn: Pawn, impulse_mod: float) -> void:
	if from_pawn == null or impulse_mod <= 0.0:
		return
	var away := global_position - from_pawn.global_position
	away.y = 0.0
	if away.length_squared() < 0.0001:
		away = -global_transform.basis.z
	away = away.normalized()
	var strength := CombatResolver.compute_knockback_impulse(base_impulse, hp, impulse_mod)
	was_knocked_by_enemy = true
	apply_central_impulse(away * strength)


func queue_stun(duration: float = -1.0) -> void:
	var t := stun_duration if duration < 0.0 else duration
	if is_in_flight:
		_pending_stun = maxf(_pending_stun, t)
	else:
		_apply_stun(t)


func _apply_stun(duration: float) -> void:
	is_stunned = true
	_stun_left = maxf(_stun_left, duration)
	ev_stun_changed.emit(true)


func stop_movement() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func die() -> void:
	if is_dead:
		return
	is_dead = true
	linear_velocity = Vector3.ZERO
	freeze = true
	ev_died.emit(self)
	queue_free()


func resolve_interaction(my_kind: int, other: Pawn, other_kind: int) -> void:
	if other == null or other == self or is_dead or other.is_dead:
		return
	var key := _pair_key(other)
	if _interacted_pairs.has(key):
		return
	_interacted_pairs[key] = true
	other._interacted_pairs[key] = true

	var result := CombatResolver.resolve(self, my_kind, other, other_kind, _config)
	_apply_effect(result["a"], other, my_kind)
	other._apply_effect(result["b"], self, other_kind)


func _apply_effect(effect: Dictionary, other: Pawn, _my_kind: int) -> void:
	if effect.get("spend_shield", false) and shield:
		shield.spend_charge()
	if effect.get("stop_movement", false):
		stop_movement()
	var dmg: float = float(effect.get("damage", 0.0))
	var mod: float = float(effect.get("impulse_mod", 0.0))
	if dmg > 0.0 or mod > 0.0:
		# Damage is applied to ME from OTHER
		if dmg > 0.0:
			receive_damage(dmg, other, mod)
		elif mod > 0.0:
			_apply_knockback(other, mod)
	if effect.get("stun_other", false) and other:
		other.queue_stun(shield.stun_time if shield else stun_duration)


func _on_body_entered(body: Node) -> void:
	if body is Pawn:
		resolve_interaction(InteractionKind.Kind.PAWN, body as Pawn, InteractionKind.Kind.PAWN)
	elif body is BarrierSegment:
		(body as BarrierSegment).on_pawn_hit(self)


func _pair_key(other: Pawn) -> int:
	var a := get_instance_id()
	var b := other.get_instance_id()
	return mini(a, b) * 100000 + maxi(a, b)


func _refresh_label() -> void:
	if world_label == null:
		return
	var flags := ""
	if is_in_flight:
		flags += " F"
	if is_stunned:
		flags += " S"
	# HP here = accumulated damage (scales knockback), not remaining health.
	world_label.text = "P%d  +%.0f%s" % [player_id + 1, hp, flags]


class MovementComponent:
	extends Node

	var pawn: Pawn
	var max_impulse: float = 18.0

	func setup(owner_pawn: Pawn, config: GameConfig) -> void:
		pawn = owner_pawn
		max_impulse = config.pawn_max_impulse
		name = "Movement"

	func slingshot(joystick_vec: Vector2) -> void:
		if pawn:
			pawn.apply_slingshot(joystick_vec)
