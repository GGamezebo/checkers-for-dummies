extends IScene

@export var root_events: RootEvents

@onready var _title: Label = $UI/Center/Title
@onready var _play: Button = $UI/Center/PlayButton
@onready var _bg: ColorRect = $UI/ColorRect
@onready var _subtitle: Label = $UI/Center/Subtitle


func initialize(_data: Dictionary) -> void:
	_apply_neon_ui()


func _apply_neon_ui() -> void:
	if _bg:
		_bg.color = NeonPalette.UI_BG
	if _title:
		_title.text = "CHECKERS NEON"
		_title.add_theme_color_override("font_color", NeonPalette.UI_ACCENT)
		_title.add_theme_color_override("font_outline_color", NeonPalette.VOID)
		_title.add_theme_constant_override("outline_size", 8)
	if _subtitle:
		_subtitle.text = "dark arena / slingshot / neon duel"
		_subtitle.add_theme_color_override("font_color", NeonPalette.UI_MUTED)
	if _play:
		_play.text = "ИГРАТЬ"
		_play.add_theme_color_override("font_color", NeonPalette.UI_TEXT)
		var normal: StyleBoxFlat = NeonPalette.make_flat_panel(Color(0.06, 0.1, 0.18, 0.9), NeonPalette.UI_ACCENT, 2.5, 18)
		var hover: StyleBoxFlat = NeonPalette.make_flat_panel(Color(0.08, 0.22, 0.28, 0.95), NeonPalette.UI_ACCENT.lightened(0.2), 3.0, 18)
		var pressed: StyleBoxFlat = NeonPalette.make_flat_panel(Color(NeonPalette.UI_ACCENT.r, NeonPalette.UI_ACCENT.g, NeonPalette.UI_ACCENT.b, 0.35), NeonPalette.UI_ACCENT, 3.0, 18)
		_play.add_theme_stylebox_override("normal", normal)
		_play.add_theme_stylebox_override("hover", hover)
		_play.add_theme_stylebox_override("pressed", pressed)
		_play.add_theme_stylebox_override("focus", hover)


func _on_play_pressed() -> void:
	if root_events:
		root_events.ev_start_game.emit({})
