class_name GameState
extends StateBase

static func get_state() -> String:
	return "game"


func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	if game_manager:
		game_manager.start_match()


func leave(_event_data: Dictionary) -> void:
	pass
