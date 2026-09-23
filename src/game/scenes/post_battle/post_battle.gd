extends IScene

@export var root_events: RootEvents
@export var result_label: Label


func initialize(data: Dictionary) -> void:
	if result_label:
		var winner: int = int(data.get("winner_id", -1))
		if winner >= 0:
			result_label.text = "Победитель: Игрок %d" % (winner + 1)
		else:
			result_label.text = "Ничья"


func _on_menu_pressed() -> void:
	if root_events:
		root_events.ev_return_to_menu.emit({})


func _on_again_pressed() -> void:
	if root_events:
		root_events.ev_start_game.emit({})
