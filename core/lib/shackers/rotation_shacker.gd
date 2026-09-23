class_name RotationShaker
extends RefCounted

var _noise := FastNoiseLite.new()
var _time := 0.0
var _rotation := 0.0

var rotation_speed := 8.0
var rotation_strength := 3.0 # In degrees

func _init(_rotation_speed :float = 8.0, _rotation_strength :float = 3.0, frequency=0.05) -> void:
	self.rotation_speed = _rotation_speed
	self.rotation_strength = _rotation_strength
	_noise.seed = randi()
	_noise.frequency = frequency

func update(delta: float) -> void:
	_time += delta
	_rotation = deg_to_rad(_noise.get_noise_1d(_time * rotation_speed + 300.0) * rotation_strength)

func get_rotation_offset() -> float:
	return _rotation
