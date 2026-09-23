class_name Abyss
extends Area3D

## Catch volume below the arena. Any pawn that falls in dies.


func setup(half_extent: float, fall_y: float = -1.5) -> void:
	collision_layer = 16
	collision_mask = 1
	monitoring = true
	monitorable = false
	position = Vector3(0, fall_y, 0)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Wide plate under the whole map (arena + outside)
	box.size = Vector3(half_extent * 8.0, 1.0, half_extent * 8.0)
	shape.shape = box
	add_child(shape)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Pawn:
		(body as Pawn).die()
