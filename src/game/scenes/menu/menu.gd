extends IScene

@export var root_events: RootEvents


func initialize(_data: Dictionary) -> void:
	pass


func _on_play_pressed() -> void:
	if root_events:
		root_events.ev_start_game.emit({})
