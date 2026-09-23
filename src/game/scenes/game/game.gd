extends IScene

## Battle scene: arena, two player controllers, HUD, match FSM.

@export var root_events: RootEvents
@export var game_events: GameEvents
@export var game_config: GameConfig
@export var game_manager: GameManager

@onready var world: Node3D = $World
@onready var hud: CanvasLayer = $HUD
@onready var lives_label: Label = $HUD/Margin/TopBar/LivesLabel
@onready var joystick: SlingshotJoystick = $HUD/Joystick
@onready var attack_btn: Button = $HUD/AttackButton
@onready var shield_btn: Button = $HUD/ShieldButton
@onready var aim_arrow: MeshInstance3D = $World/AimArrow

var _arena: Arena
var _controllers: Array[PlayerController] = []
var _listener: EventListener = EventListener.new()
var _match_started: bool = false
var _ai_brain: AiBrain


func initialize(_data: Dictionary) -> void:
	_build_world()
	_setup_players()
	_listener.add(game_events.ev_player_lost, _on_player_lost)
	_listener.add(game_events.ev_pawn_died, _on_pawn_died)
	attack_btn.pressed.connect(_on_attack_pressed)
	shield_btn.pressed.connect(_on_shield_pressed)
	game_manager.initialize(game_config, self)
	_refresh_lives()


func deinit() -> void:
	_listener.deinit()
	super.deinit()


func _build_world() -> void:
	_arena = Arena.new()
	_arena.name = "Arena"
	world.add_child(_arena)
	_arena.build(game_config)

	# Camera
	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 50.0
	cam.position = Vector3(0, 14, 10)
	world.add_child(cam)
	cam.look_at(Vector3(0, 0, 0), Vector3.UP)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, 35, 0)
	light.light_color = Color(0.7, 0.75, 0.85)
	light.light_energy = 0.75
	light.shadow_enabled = false
	world.add_child(light)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 6, 0)
	fill.light_color = Color(0.35, 0.45, 0.55)
	fill.light_energy = 0.35
	fill.omni_range = 18.0
	world.add_child(fill)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = NeonPalette.VOID
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.18, 0.2, 0.26)
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true
	environment.glow_intensity = 0.35
	environment.glow_strength = 0.55
	environment.glow_bloom = 0.05
	environment.glow_hdr_threshold = 1.2
	env.environment = environment
	world.add_child(env)

	_setup_aim_arrow()
	_style_hud()


func _setup_aim_arrow() -> void:
	if aim_arrow == null:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.06, 1.25)
	aim_arrow.mesh = mesh
	aim_arrow.material_override = NeonPalette.make_emissive(NeonPalette.AIM, 0.55)
	aim_arrow.visible = false


func _style_hud() -> void:
	if lives_label:
		lives_label.add_theme_color_override("font_color", NeonPalette.UI_TEXT)
		lives_label.add_theme_color_override("font_outline_color", NeonPalette.VOID)
		lives_label.add_theme_constant_override("outline_size", 6)
	var hint := hud.get_node_or_null("Margin/TopBar/Hint") as Label
	if hint:
		hint.add_theme_color_override("font_color", NeonPalette.UI_MUTED)
		hint.text = "vs AI  ·  joystick move  ·  attack / shield"
	_style_neon_button(attack_btn, NeonPalette.UI_DANGER, "АТАКА")
	_style_neon_button(shield_btn, NeonPalette.SHIELD, "ЩИТ")


func _style_neon_button(btn: Button, accent: Color, caption: String) -> void:
	if btn == null:
		return
	btn.text = caption
	btn.add_theme_color_override("font_color", NeonPalette.UI_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", accent)
	var normal: StyleBoxFlat = NeonPalette.make_flat_panel(Color(0.06, 0.09, 0.16, 0.82), accent, 2.5, 999)
	var hover: StyleBoxFlat = NeonPalette.make_flat_panel(Color(accent.r, accent.g, accent.b, 0.28), accent.lightened(0.2), 3.0, 999)
	var pressed: StyleBoxFlat = NeonPalette.make_flat_panel(Color(accent.r, accent.g, accent.b, 0.45), accent, 3.0, 999)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)


func _setup_players() -> void:
	var half := game_config.arena_half_size * 0.55
	var p1 := PlayerController.new()
	p1.name = "Player1"
	add_child(p1)
	p1.setup(
		game_config, game_events, world, 0,
		NeonPalette.P1, Vector3(0, 0.4, half),
		joystick, false
	)
	p1.ev_lives_changed.connect(func(_l): _refresh_lives())
	joystick.ev_changed.connect(_on_aim_changed)
	joystick.ev_released.connect(func(_v): aim_arrow.visible = false)

	var p2 := PlayerController.new()
	p2.name = "Player2AI"
	add_child(p2)
	p2.setup(
		game_config, game_events, world, 1,
		NeonPalette.P2, Vector3(0, 0.4, -half),
		null, false
	)
	p2.ev_lives_changed.connect(func(_l): _refresh_lives())

	_controllers = [p1, p2]

	if game_config.ai_enabled:
		_ai_brain = AiBrain.new()
		_ai_brain.setup(p2, p1, game_config)
		add_child(_ai_brain)


func on_match_start() -> void:
	_match_started = true
	if _ai_brain:
		_ai_brain.set_active(true)


func on_match_end(data: Dictionary) -> void:
	_match_started = false
	if _ai_brain:
		_ai_brain.set_active(false)
	if root_events:
		root_events.ev_exit_game.emit(data)


func _on_player_lost(player_id: int) -> void:
	var winner := 1 if player_id == 0 else 0
	# If both somehow lost, first signal wins
	if game_manager and game_manager.get_current_state_name() == GameState.get_state():
		game_manager.request_end(winner)


func _on_pawn_died(_player_id: int, _lives_left: int) -> void:
	_refresh_lives()


func _refresh_lives() -> void:
	if lives_label == null or _controllers.is_empty():
		return
	var parts: PackedStringArray = []
	for c in _controllers:
		var tag := "AI" if c.player_id == 1 and game_config.ai_enabled else ("P%d" % (c.player_id + 1))
		parts.append("%s: %d❤" % [tag, c.lives])
	lives_label.text = "  |  ".join(parts)


func _on_attack_pressed() -> void:
	if _controllers.size() > 0:
		_controllers[0].request_attack()


func _on_shield_pressed() -> void:
	if _controllers.size() > 0:
		_controllers[0].request_shield()


func _on_aim_changed(value: Vector2) -> void:
	if aim_arrow == null or _controllers.is_empty():
		return
	var p: Pawn = _controllers[0].pawn
	if p == null or not is_instance_valid(p) or value.length() < 0.08:
		aim_arrow.visible = false
		return
	# Show opposite of pull (launch direction)
	var dir := Vector3(-value.x, 0.0, -value.y)
	if dir.length_squared() < 0.0001:
		aim_arrow.visible = false
		return
	dir = dir.normalized()
	aim_arrow.visible = true
	aim_arrow.global_position = p.global_position + Vector3(0, 0.6, 0) + dir * (0.6 + value.length() * 0.8)
	aim_arrow.look_at(aim_arrow.global_position + dir, Vector3.UP)
	aim_arrow.scale = Vector3(1, 1, 0.5 + value.length())
