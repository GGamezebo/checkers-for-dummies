class_name BarrierSegment
extends StaticBody3D

## Perimeter collider. Damaged only when a pawn was knocked by an enemy hits it.
## On hit: pawn speed *= elasticity. At 0 HP → destroyed.

signal ev_destroyed(segment: BarrierSegment)
signal ev_hp_changed(hp: float, max_hp: float)

var max_hp: float = 40.0
var hp: float = 40.0
var elasticity: float = 0.65

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _alive: bool = true


func setup(segment_hp: float, elast: float, size: Vector3) -> void:
	max_hp = segment_hp
	hp = segment_hp
	elasticity = elast
	collision_layer = 8  # barrier
	collision_mask = 0

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	add_child(shape)

	_mesh = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	_mesh.mesh = mesh
	_mat = NeonPalette.make_emissive(NeonPalette.BARRIER_OK, 0.35)
	_mesh.material_override = _mat
	add_child(_mesh)
	ev_hp_changed.emit(hp, max_hp)


func on_pawn_hit(pawn: Pawn) -> void:
	if not _alive or pawn == null:
		return

	var speed := Vector3(pawn.linear_velocity.x, 0.0, pawn.linear_velocity.z).length()

	# Reflect / damp velocity
	var away := pawn.global_position - global_position
	away.y = 0.0
	if away.length_squared() < 0.0001:
		away = Vector3(pawn.linear_velocity.x, 0.0, pawn.linear_velocity.z)
	if away.length_squared() > 0.0001:
		away = away.normalized()
		var new_speed := speed * elasticity
		pawn.linear_velocity = Vector3(away.x * new_speed, pawn.linear_velocity.y, away.z * new_speed)

	# Only enemy-knocked pawns damage the barrier
	if not pawn.was_knocked_by_enemy:
		return

	_take_damage(speed)


func _take_damage(amount: float) -> void:
	hp = maxf(0.0, hp - amount)
	ev_hp_changed.emit(hp, max_hp)
	_refresh_color()
	if hp <= 0.0:
		_destroy()


func _refresh_color() -> void:
	if _mat == null:
		return
	var t := 0.0 if max_hp <= 0.0 else 1.0 - (hp / max_hp)
	var col: Color
	if t < 0.5:
		col = NeonPalette.BARRIER_OK.lerp(NeonPalette.BARRIER_MID, t * 2.0)
	else:
		col = NeonPalette.BARRIER_MID.lerp(NeonPalette.BARRIER_BAD, (t - 0.5) * 2.0)
	_mat.albedo_color = col
	_mat.emission = col.darkened(0.1)
	_mat.emission_energy_multiplier = lerpf(0.35, 0.7, t)


func _destroy() -> void:
	_alive = false
	collision_layer = 0
	if _mesh:
		_mesh.visible = false
	ev_destroyed.emit(self)
	queue_free()
