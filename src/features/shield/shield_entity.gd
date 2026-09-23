class_name ShieldEntity
extends Node3D

## Blocks damage when active and hit comes from the front hemisphere.
## Spends one charge on successful block / table interaction.

signal ev_charges_changed(charges: int, max_charges: int)
signal ev_activated
signal ev_deactivated

@export var max_charges: int = 3
@export var recharge_time: float = 4.0
@export var stun_time: float = 0.8
@export var active_duration: float = 0.45

var charges: int = 0
var is_active: bool = false

var _owner_pawn: Pawn
var _recharge_left: float = 0.0
var _active_left: float = 0.0
var _collider: Area3D
var _mesh: MeshInstance3D


func setup(pawn: Pawn, config: GameConfig) -> void:
	_owner_pawn = pawn
	max_charges = config.shield_charges
	recharge_time = config.shield_recharge_time
	stun_time = config.shield_stun_time
	active_duration = config.shield_active_duration
	charges = max_charges
	_build_visual(config)
	ev_charges_changed.emit(charges, max_charges)


func _build_visual(config: GameConfig) -> void:
	_collider = Area3D.new()
	_collider.name = "ShieldCollider"
	_collider.collision_layer = 4  # shield
	_collider.collision_mask = 0
	_collider.monitoring = false
	_collider.monitorable = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(config.pawn_radius * 2.2, config.pawn_height * 1.4, 0.2)
	shape.shape = box
	_collider.add_child(shape)
	_collider.position = Vector3(0, config.pawn_height * 0.5, -config.pawn_radius - 0.15)
	_collider.set_meta("interaction_kind", InteractionKind.Kind.SHIELD)
	_collider.set_meta("pawn", _owner_pawn)
	_collider.body_entered.connect(_on_body_entered)
	add_child(_collider)

	_mesh = MeshInstance3D.new()
	var quad := BoxMesh.new()
	quad.size = box.size
	_mesh.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.55, 0.95, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh.material_override = mat
	_mesh.visible = false
	_collider.add_child(_mesh)
	_set_collider_enabled(false)


func _process(delta: float) -> void:
	if charges < max_charges:
		_recharge_left -= delta
		if _recharge_left <= 0.0:
			charges = mini(charges + 1, max_charges)
			ev_charges_changed.emit(charges, max_charges)
			if charges < max_charges:
				_recharge_left = recharge_time

	if is_active:
		_active_left -= delta
		if _active_left <= 0.0:
			deactivate()


func try_activate() -> bool:
	if is_active or charges <= 0:
		return false
	is_active = true
	_active_left = active_duration
	_set_collider_enabled(true)
	if _mesh:
		_mesh.visible = true
	ev_activated.emit()
	return true


func deactivate() -> void:
	if not is_active:
		return
	is_active = false
	_active_left = 0.0
	_set_collider_enabled(false)
	if _mesh:
		_mesh.visible = false
	ev_deactivated.emit()


func spend_charge() -> void:
	if charges <= 0:
		return
	charges -= 1
	if charges < max_charges and _recharge_left <= 0.0:
		_recharge_left = recharge_time
	ev_charges_changed.emit(charges, max_charges)
	deactivate()


func can_block(attack_direction: Vector3) -> bool:
	## Block if attack comes from the front: attack_dir · forward <= 0
	if not is_active:
		return false
	var forward := -_owner_pawn.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return false
	forward = forward.normalized()
	var dir := attack_direction
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return true
	return dir.normalized().dot(forward) <= 0.0


func _set_collider_enabled(enabled: bool) -> void:
	if _collider == null:
		return
	_collider.collision_layer = 4 if enabled else 0
	_collider.collision_mask = 1 if enabled else 0  # detect pawns
	_collider.monitoring = enabled
	_collider.monitorable = enabled


func _on_body_entered(body: Node) -> void:
	if not is_active or _owner_pawn == null:
		return
	if body is Pawn and body != _owner_pawn:
		_owner_pawn.resolve_interaction(InteractionKind.Kind.SHIELD, body as Pawn, InteractionKind.Kind.PAWN)
