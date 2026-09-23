class_name Arena
extends Node3D

## Quiet dark pad + barrier ring + abyss outside.

var half_size: float = 6.0
var floor_mesh: MeshInstance3D


func build(config: GameConfig) -> void:
	half_size = config.arena_half_size
	_build_floor()
	_build_barriers(config)
	_build_abyss(config)


func _build_floor() -> void:
	floor_mesh = MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(half_size * 2.0, 0.18, half_size * 2.0)
	floor_mesh.mesh = plane
	floor_mesh.position = Vector3(0, -0.09, 0)
	var mat := NeonPalette.make_emissive(NeonPalette.FLOOR, 0.08)
	mat.emission = NeonPalette.GRID_LINE
	mat.emission_energy_multiplier = 0.05
	floor_mesh.material_override = mat
	add_child(floor_mesh)

	# Thin muted edge line (no floodlight torus)
	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = half_size - 0.08
	rim_mesh.outer_radius = half_size + 0.02
	rim_mesh.rings = 24
	rim_mesh.ring_segments = 40
	rim.mesh = rim_mesh
	rim.position = Vector3(0, 0.015, 0)
	rim.material_override = NeonPalette.make_emissive(NeonPalette.FLOOR_EDGE, 0.25)
	add_child(rim)

	var body := StaticBody3D.new()
	body.collision_layer = 32  # world
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = plane.size
	shape.shape = box
	shape.position = floor_mesh.position
	body.add_child(shape)
	add_child(body)


func _build_barriers(config: GameConfig) -> void:
	var count: int = config.barrier_segment_count
	var radius: float = half_size
	var circumference: float = TAU * radius
	var segment_len: float = circumference / float(count)
	var size := Vector3(segment_len * 0.95, config.barrier_height, config.barrier_thickness)

	for i in count:
		var angle := (TAU * float(i)) / float(count)
		var pos := Vector3(sin(angle) * radius, config.barrier_height * 0.5, cos(angle) * radius)
		var seg := BarrierSegment.new()
		seg.name = "Barrier_%d" % i
		add_child(seg)
		seg.global_position = global_position + pos
		seg.rotation.y = angle
		seg.setup(config.barrier_hp, config.barrier_elasticity, size)


func _build_abyss(_config: GameConfig) -> void:
	var abyss := Abyss.new()
	abyss.name = "Abyss"
	add_child(abyss)
	abyss.setup(half_size)
