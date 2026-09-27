class_name Arena
extends Node3D

## Quiet dark pad + rectangular barrier perimeter + abyss outside.

const FLOOR_SHADER := preload("arena_floor.gdshader")

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
	var mat := ShaderMaterial.new()
	mat.shader = FLOOR_SHADER
	mat.set_shader_parameter("base_color", NeonPalette.FLOOR)
	mat.set_shader_parameter("grid_color", NeonPalette.FLOOR_GRID)
	mat.set_shader_parameter("edge_color", NeonPalette.FLOOR_EDGE)
	mat.set_shader_parameter("half_size", half_size)
	floor_mesh.material_override = mat
	add_child(floor_mesh)

	# Thin muted edge line along the pad border (no floodlight)
	var rim_mat := NeonPalette.make_emissive(NeonPalette.FLOOR_EDGE, 0.55)
	for side in 4:
		var angle := side * PI * 0.5
		var rim := MeshInstance3D.new()
		var rim_mesh := BoxMesh.new()
		rim_mesh.size = Vector3(half_size * 2.0, 0.02, 0.08)
		rim.mesh = rim_mesh
		rim.material_override = rim_mat
		rim.position = Vector3(sin(angle), 0.0, cos(angle)) * (half_size - 0.04) + Vector3(0, 0.01, 0)
		rim.rotation.y = angle
		add_child(rim)

	# Faint center mark — gives the dark pad a sense of scale and spawn symmetry
	var center := MeshInstance3D.new()
	var center_mesh := TorusMesh.new()
	center_mesh.inner_radius = half_size * 0.16
	center_mesh.outer_radius = half_size * 0.16 + 0.04
	center_mesh.rings = 64
	center_mesh.ring_segments = 6
	center.mesh = center_mesh
	center.scale = Vector3(1, 0.1, 1)
	center.position = Vector3(0, 0.005, 0)
	center.material_override = NeonPalette.make_emissive(NeonPalette.GRID_LINE.lightened(0.15), 0.1)
	add_child(center)

	var body := StaticBody3D.new()
	body.collision_layer = 32  # world
	body.collision_mask = 0
	var ice := PhysicsMaterial.new()
	ice.friction = 0.0
	body.physics_material_override = ice
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = plane.size
	shape.shape = box
	shape.position = floor_mesh.position
	body.add_child(shape)
	add_child(body)


func _build_barriers(config: GameConfig) -> void:
	## Rectangular perimeter (mockup): barrier_segment_count split over 4 sides,
	## segments sit just outside the pad edge; side length covers the corners.
	var per_side: int = maxi(1, int(config.barrier_segment_count / 4.0))
	var thickness: float = config.barrier_thickness
	var side_len: float = half_size * 2.0 + thickness * 2.0
	var segment_len: float = side_len / float(per_side)
	var size := Vector3(segment_len * 0.96, config.barrier_height, thickness)

	var index := 0
	for side in 4:
		var angle := side * PI * 0.5
		# rotation.y = angle → local Z = outward normal, local X = along the side
		var outward := Vector3(sin(angle), 0.0, cos(angle))
		var along := Vector3(cos(angle), 0.0, -sin(angle))
		for i in per_side:
			var t := -side_len * 0.5 + segment_len * (float(i) + 0.5)
			var pos := outward * (half_size + thickness * 0.5) + along * t
			pos.y = config.barrier_height * 0.5
			var seg := BarrierSegment.new()
			seg.name = "Barrier_%d" % index
			index += 1
			add_child(seg)
			seg.global_position = global_position + pos
			seg.rotation.y = angle
			seg.setup(config.barrier_hp, config.barrier_elasticity, size)


func _build_abyss(_config: GameConfig) -> void:
	var abyss := Abyss.new()
	abyss.name = "Abyss"
	add_child(abyss)
	abyss.setup(half_size)
