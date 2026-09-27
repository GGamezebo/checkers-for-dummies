class_name EndGameState
extends StateBase

static func get_state() -> String:
	return "end_game"

## Holds the result banner for `end_game_delay`, then leaves the battle.

var _left: float = 0.0
var _data: Dictionary = {}
var _active: bool = false


func enter(_prev_state: FSMState, event_data: Dictionary) -> void:
	_data = event_data
	_left = game_config.end_game_delay if game_config else 0.0
	_active = true
	if game_manager:
		game_manager.show_result(_data)


func leave(_event_data: Dictionary) -> void:
	_active = false


func _process(delta: float) -> void:
	if not _active:
		return
	_left -= delta
	if _left <= 0.0:
		_active = false
		if game_manager:
			game_manager.finish_match(_data)
