class_name GameManager
extends Node

@export var game_events: GameEvents
@export var states: Array[StateBase]

var fsm: FSM
var time: float = 0.0
var game_scene: Node  # Game scene host


func initialize(config: GameConfig, host: Node) -> void:
	game_scene = host
	for state in states:
		state.initialize(self, config)

	fsm = FSM.new({
		"initial": {"state": CountDownState.get_state()},
		"transitions": [
			{"src": CountDownState.get_state(), "dst": GameState.get_state(), "event": FSMGameEvents.START_GAME},
			{"src": GameState.get_state(), "dst": EndGameState.get_state(), "event": FSMGameEvents.END_GAME},
			{"src": EndGameState.get_state(), "dst": CountDownState.get_state(), "event": FSMGameEvents.RESTART},
		],
		"states": states,
	})
	fsm.ev_state_changed.connect(_on_state_changed)


func _exit_tree() -> void:
	if fsm:
		fsm.deinit()


func get_current_state_name() -> String:
	return fsm.get_current_state_name() if fsm else ""


func _process(delta: float) -> void:
	time += delta


func _on_state_changed(from_state_name: String, to_state_name: String) -> void:
	if game_events:
		game_events.ev_game_state_changed.emit(from_state_name, to_state_name)


func start_match() -> void:
	if game_scene and game_scene.has_method("on_match_start"):
		game_scene.on_match_start()


func finish_match(data: Dictionary) -> void:
	if game_scene and game_scene.has_method("on_match_end"):
		game_scene.on_match_end(data)


func request_end(winner_id: int) -> void:
	if fsm:
		fsm.add_event(FSMGameEvents.END_GAME, {"winner_id": winner_id})
