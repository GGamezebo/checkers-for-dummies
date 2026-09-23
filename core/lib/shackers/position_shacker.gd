class_name PositionShaker
extends RefCounted

var noise := FastNoiseLite.new()
var time := 0.0

var shake_speed: float
var shake_strength: float

var pos_offset := Vector2.ZERO

func _init(_shake_speed :float = 10.0, _shake_strength :float = 2.0, frequency=0.05):
	self.shake_speed = _shake_speed
	self.shake_strength = _shake_strength
	noise.seed = randi()
	noise.frequency = frequency

func update(delta: float) -> void:
	time += delta
	
	# Position shake
	var s_time = time * shake_speed
	pos_offset.x = noise.get_noise_1d(s_time) * shake_strength
	pos_offset.y = noise.get_noise_1d(s_time + 100.0) * shake_strength

func get_pos_offset() -> Vector2:
	return pos_offset
