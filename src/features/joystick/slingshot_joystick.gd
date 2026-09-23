class_name SlingshotJoystick
extends Control

## Two parts: stick + move zone. Value in [-1,1] per axis, length clamped to 1.
## Release → stick returns to center and emits ev_released with last vector.

signal ev_changed(value: Vector2)
signal ev_released(value: Vector2)

@export var deadzone: float = 0.08
@export var base_radius: float = 90.0
@export var stick_radius: float = 36.0

var value: Vector2 = Vector2.ZERO

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _base: Panel
var _stick: Panel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	resized.connect(_on_resized)
	_on_resized()


func _build() -> void:
	_base = Panel.new()
	_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_sb := StyleBoxFlat.new()
	base_sb.bg_color = Color(0.55, 0.75, 0.9, 0.35)
	base_sb.corner_radius_top_left = 999
	base_sb.corner_radius_top_right = 999
	base_sb.corner_radius_bottom_left = 999
	base_sb.corner_radius_bottom_right = 999
	_base.add_theme_stylebox_override("panel", base_sb)
	add_child(_base)

	_stick = Panel.new()
	_stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stick_sb := StyleBoxFlat.new()
	stick_sb.bg_color = Color(0.75, 0.2, 0.2, 0.85)
	stick_sb.corner_radius_top_left = 999
	stick_sb.corner_radius_top_right = 999
	stick_sb.corner_radius_bottom_left = 999
	stick_sb.corner_radius_bottom_right = 999
	_stick.add_theme_stylebox_override("panel", stick_sb)
	add_child(_stick)


func _on_resized() -> void:
	var joy_size := get_size()
	_center = joy_size * 0.5
	base_radius = minf(joy_size.x, joy_size.y) * 0.45
	stick_radius = base_radius * 0.4
	_base.position = _center - Vector2(base_radius, base_radius)
	_base.size = Vector2(base_radius, base_radius) * 2.0
	_reset_stick()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and _touch_index < 0:
			_touch_index = st.index
			_update_from_pos(st.position)
		elif not st.pressed and st.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _touch_index:
			_update_from_pos(sd.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_touch_index = 0
				_update_from_pos(mb.position)
			elif _touch_index == 0:
				_release()
	elif event is InputEventMouseMotion and _touch_index == 0:
		_update_from_pos((event as InputEventMouseMotion).position)


func _update_from_pos(local_pos: Vector2) -> void:
	var delta := local_pos - _center
	var max_len := base_radius - stick_radius * 0.2
	if delta.length() > max_len:
		delta = delta.normalized() * max_len
	_stick.position = _center + delta - Vector2(stick_radius, stick_radius)
	_stick.size = Vector2(stick_radius, stick_radius) * 2.0
	value = delta / max_len
	if value.length() < deadzone:
		value = Vector2.ZERO
	ev_changed.emit(value)


func _release() -> void:
	var last := value
	_touch_index = -1
	_reset_stick()
	ev_released.emit(last)
	value = Vector2.ZERO
	ev_changed.emit(value)


func _reset_stick() -> void:
	_stick.position = _center - Vector2(stick_radius, stick_radius)
	_stick.size = Vector2(stick_radius, stick_radius) * 2.0
	value = Vector2.ZERO
