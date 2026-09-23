class_name CountDownState
extends StateBase

static func get_state() -> String:
	return "countdown"

var _left: float = 1.0
var _active: bool = false


func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	_left = 1.0
	_active = true


func leave(_event_data: Dictionary) -> void:
	_active = false


func _process(delta: float) -> void:
	if not _active:
		return
	_left -= delta
	if _left <= 0.0:
		_active = false
		add_event(FSMGameEvents.START_GAME)
