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


func on_pawn_hit(pawn: Pawn, impact_velocity: Vector3) -> void:
	## impact_velocity = pawn planar velocity right before the contact
	## (the solver has already eaten the normal component by now).
	if not _alive or pawn == null:
		return

	var v := Vector3(impact_velocity.x, 0.0, impact_velocity.z)
	var speed := v.length()

	# Bounce off the segment face: reflect about its normal, then damp by elasticity.
	var normal := global_transform.basis.z
	normal.y = 0.0
	if normal.length_squared() > 0.0001 and speed > 0.0001:
		var out := v.bounce(normal.normalized()) * elasticity
		pawn.linear_velocity = Vector3(out.x, pawn.linear_velocity.y, out.z)

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
	else:
		_flash()


func _flash() -> void:
	if _mat == null:
		return
	var settle := _mat.emission_energy_multiplier
	_mat.emission_energy_multiplier = settle + 1.2
	create_tween().tween_property(_mat, "emission_energy_multiplier", settle, 0.25)


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
	ev_destroyed.emit(self)
	if _mesh == null:
		queue_free()
		return
	# Short collapse so the gap reads as "broken", not as a missing mesh.
	_mat.emission_energy_multiplier = 1.6
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_mesh, "scale", Vector3(1.0, 0.05, 0.4), 0.3).set_ease(Tween.EASE_IN)
	tw.tween_property(_mat, "emission_energy_multiplier", 0.0, 0.3)
	tw.chain().tween_callback(queue_free)
