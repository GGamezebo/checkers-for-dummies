extends IScene

## App-root HFSM scene: RootEvents → HFSM bridge.

@export var root_events: RootEvents

var _listener: EventListener = EventListener.new()


func initialize(_data: Dictionary) -> void:
	_listener.add(root_events.ev_start_game, _on_ev_start_game)
	_listener.add(root_events.ev_exit_game, _on_ev_exit_game)
	_listener.add(root_events.ev_return_to_menu, _on_ev_return_to_menu)


func deinit() -> void:
	_listener.deinit()
	super.deinit()


func _on_ev_start_game(data: Dictionary) -> void:
	add_event("ev.start_game", data)


func _on_ev_exit_game(data: Dictionary = {}) -> void:
	add_event("ev.exit_game", data)


func _on_ev_return_to_menu(data: Dictionary = {}) -> void:
	add_event("ev.open_menu", data)
