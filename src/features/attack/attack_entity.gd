class_name AttackEntity
extends Node3D

## Activates a forward collider; anything hittable receives attack damage via CombatResolver.

signal ev_hit(target: Pawn)
signal ev_activated
signal ev_deactivated

@export var damage: float = 15.0
@export var duration: float = 0.25

var is_active: bool = false

var _owner_pawn: Pawn
var _config: GameConfig
var _active_left: float = 0.0
var _collider: Area3D
var _mesh: MeshInstance3D
var _hit_this_swing: Dictionary = {}


func setup(pawn: Pawn, config: GameConfig) -> void:
	_owner_pawn = pawn
	_config = config
	damage = config.attack_damage
	duration = config.attack_duration
	_build_visual(config)


func _build_visual(config: GameConfig) -> void:
	_collider = Area3D.new()
	_collider.name = "AttackCollider"
	_collider.collision_layer = 2  # attack
	_collider.collision_mask = 1 | 4  # pawn + shield
	_collider.monitoring = false
	_collider.monitorable = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(config.attack_width, config.pawn_height * 1.2, config.attack_reach)
	shape.shape = box
	_collider.add_child(shape)
	_collider.position = Vector3(0, config.pawn_height * 0.5, -config.pawn_radius - config.attack_reach * 0.5)
	_collider.set_meta("interaction_kind", InteractionKind.Kind.SWORD)
	_collider.set_meta("pawn", _owner_pawn)
	_collider.area_entered.connect(_on_area_entered)
	_collider.body_entered.connect(_on_body_entered)
	add_child(_collider)

	_mesh = MeshInstance3D.new()
	var blade := BoxMesh.new()
	blade.size = box.size
	_mesh.mesh = blade
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.2, 0.15, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh.material_override = mat
	_mesh.visible = false
	_collider.add_child(_mesh)
	_set_enabled(false)


func _process(delta: float) -> void:
	if not is_active:
		return
	_active_left -= delta
	if _active_left <= 0.0:
		deactivate()


func try_activate() -> bool:
	if is_active:
		return false
	is_active = true
	_active_left = duration
	_hit_this_swing.clear()
	_set_enabled(true)
	if _mesh:
		_mesh.visible = true
	ev_activated.emit()
	return true


func deactivate() -> void:
	if not is_active:
		return
	is_active = false
	_active_left = 0.0
	_set_enabled(false)
	if _mesh:
		_mesh.visible = false
	ev_deactivated.emit()


func _set_enabled(enabled: bool) -> void:
	if _collider == null:
		return
	_collider.monitoring = enabled
	_collider.monitorable = enabled
	_collider.collision_layer = 2 if enabled else 0


func _on_body_entered(body: Node) -> void:
	_try_hit(body)


func _on_area_entered(area: Area3D) -> void:
	_try_hit(area)


func _try_hit(node: Node) -> void:
	if not is_active or _owner_pawn == null:
		return
	var other: Pawn = _resolve_pawn(node)
	if other == null or other == _owner_pawn:
		return
	if _hit_this_swing.has(other.get_instance_id()):
		return
	_hit_this_swing[other.get_instance_id()] = true

	var other_kind: int = int(node.get_meta("interaction_kind", InteractionKind.Kind.PAWN))
	_owner_pawn.resolve_interaction(InteractionKind.Kind.SWORD, other, other_kind)
	ev_hit.emit(other)


func _resolve_pawn(node: Node) -> Pawn:
	if node is Pawn:
		return node as Pawn
	if node.has_meta("pawn"):
		return node.get_meta("pawn") as Pawn
	var parent := node.get_parent()
	while parent:
		if parent is Pawn:
			return parent as Pawn
		parent = parent.get_parent()
	return null
