class_name EndGameState
extends StateBase

static func get_state() -> String:
	return "end_game"


func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	if game_manager:
		game_manager.finish_match(_event_data)
