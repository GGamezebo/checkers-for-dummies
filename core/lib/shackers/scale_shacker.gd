class_name ScaleShacker
extends RefCounted

var noise := FastNoiseLite.new()
var time := 0.0

var pulse_speed: float
var pulse_strength: float

# Current computed offset
var scale_offset := Vector2.ZERO

func _init(_pulse_speed := 5.0, _pulse_strength := 0.05, frequency=0.05):
	self.pulse_speed = _pulse_speed
	self.pulse_strength = _pulse_strength
	
	noise.seed = randi()
	noise.frequency = frequency

func update(delta: float) -> void:
	time += delta
	
	# Scale pulse
	var p_time = time * pulse_speed
	var p_val = noise.get_noise_1d(p_time + 200.0) * pulse_strength
	scale_offset = Vector2(p_val, p_val)

func get_scale_offset() -> Vector2:
	return scale_offset
