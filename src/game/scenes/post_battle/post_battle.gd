extends IScene

@export var root_events: RootEvents
@export var result_label: Label

@onready var _bg: ColorRect = $UI/ColorRect
@onready var _again: Button = $UI/Center/Again
@onready var _menu: Button = $UI/Center/Menu


func initialize(data: Dictionary) -> void:
	_apply_neon_ui()
	if _again:
		_again.text = "ЕЩЁ РАЗ"
	if _menu:
		_menu.text = "В МЕНЮ"
	if result_label:
		var winner: int = int(data.get("winner_id", -1))
		if winner >= 0:
			result_label.text = "ПОБЕДИТЕЛЬ — ИГРОК %d" % (winner + 1)
			result_label.add_theme_color_override(
				"font_color",
				NeonPalette.P1 if winner == 0 else NeonPalette.P2
			)
		else:
			result_label.text = "НИЧЬЯ"
			result_label.add_theme_color_override("font_color", NeonPalette.UI_TEXT)


func _apply_neon_ui() -> void:
	if _bg:
		_bg.color = NeonPalette.UI_BG
	if result_label:
		result_label.add_theme_color_override("font_outline_color", NeonPalette.VOID)
		result_label.add_theme_constant_override("outline_size", 8)
	_style_btn(_again, NeonPalette.UI_ACCENT)
	_style_btn(_menu, NeonPalette.UI_MUTED)


func _style_btn(btn: Button, accent: Color) -> void:
	if btn == null:
		return
	btn.add_theme_color_override("font_color", NeonPalette.UI_TEXT)
	var normal: StyleBoxFlat = NeonPalette.make_flat_panel(Color(0.06, 0.1, 0.18, 0.9), accent, 2.0, 14)
	var hover: StyleBoxFlat = NeonPalette.make_flat_panel(Color(accent.r, accent.g, accent.b, 0.25), accent.lightened(0.15), 2.5, 14)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)


func _on_menu_pressed() -> void:
	if root_events:
		root_events.ev_return_to_menu.emit({})


func _on_again_pressed() -> void:
	if root_events:
		root_events.ev_start_game.emit({})
