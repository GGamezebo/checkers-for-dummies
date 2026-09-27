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
@onready var banner: Label = $HUD/Banner
@onready var aim_arrow: MeshInstance3D = $World/AimArrow

const _AIM_MIN := 0.08

var _arena: Arena
var _camera: Camera3D
var _camera_base: Vector3
var _shaker := PositionShaker.new(300.0, 1.0)
var _trauma: float = 0.0
var _controllers: Array[PlayerController] = []
var _listener: EventListener = EventListener.new()
var _match_started: bool = false
var _ai_brain: AiBrain
var _banner_tween: Tween

var _aim_shaft: MeshInstance3D
var _aim_head: MeshInstance3D
var _aim_ready_mat: StandardMaterial3D
var _aim_blocked_mat: StandardMaterial3D


func initialize(_data: Dictionary) -> void:
	_build_world()
	_setup_players()
	_listener.add(game_events.ev_player_lost, _on_player_lost)
	_listener.add(game_events.ev_pawn_died, _on_pawn_died)
	attack_btn.pressed.connect(_on_attack_pressed)
	shield_btn.pressed.connect(_on_shield_pressed)
	banner.text = ""
	game_manager.initialize(game_config, self)
	_refresh_lives()


func deinit() -> void:
	_listener.deinit()
	super.deinit()


func _process(delta: float) -> void:
	_update_aim()
	_update_camera_shake(delta)


func _build_world() -> void:
	_arena = Arena.new()
	_arena.name = "Arena"
	world.add_child(_arena)
	_arena.build(game_config)

	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = 50.0
	_camera.position = Vector3(0, 14, 10)
	world.add_child(_camera)
	_camera.look_at(Vector3(0, 0, 0), Vector3.UP)
	_camera_base = _camera.position

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
	# Void fades into depth instead of a hard pad edge against flat color
	environment.fog_enabled = true
	environment.fog_light_color = NeonPalette.ABYSS
	environment.fog_density = 0.012
	env.environment = environment
	world.add_child(env)

	_setup_aim_arrow()
	_style_hud()


func _setup_aim_arrow() -> void:
	## Runtime overlay (allowed programmatic exception): shaft + head, laid flat
	## on the pad. Local -Z is the launch direction.
	if aim_arrow == null:
		return
	_aim_ready_mat = NeonPalette.make_emissive(NeonPalette.AIM, 0.55)
	_aim_blocked_mat = NeonPalette.make_emissive(NeonPalette.UI_MUTED.darkened(0.2), 0.1)

	_aim_shaft = MeshInstance3D.new()
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.1, 0.04, 1.0)
	_aim_shaft.mesh = shaft
	aim_arrow.add_child(_aim_shaft)

	_aim_head = MeshInstance3D.new()
	var head := PrismMesh.new()
	head.size = Vector3(0.36, 0.3, 0.04)
	_aim_head.mesh = head
	_aim_head.rotation.x = -PI * 0.5  # prism tip (+Y) → -Z
	aim_arrow.add_child(_aim_head)
	aim_arrow.visible = false


func _style_hud() -> void:
	if lives_label:
		lives_label.add_theme_color_override("font_color", NeonPalette.UI_TEXT)
		lives_label.add_theme_color_override("font_outline_color", NeonPalette.VOID)
		lives_label.add_theme_constant_override("outline_size", 6)
	var hint := hud.get_node_or_null("Margin/TopBar/Hint") as Label
	if hint:
		hint.add_theme_color_override("font_color", NeonPalette.UI_MUTED)
	_style_neon_button(attack_btn, NeonPalette.UI_DANGER)
	_style_neon_button(shield_btn, NeonPalette.SHIELD)


func _style_neon_button(btn: Button, accent: Color) -> void:
	if btn == null:
		return
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

	var p2 := PlayerController.new()
	p2.name = "Player2AI"
	add_child(p2)
	p2.setup(
		game_config, game_events, world, 1,
		NeonPalette.P2, Vector3(0, 0.4, -half),
		null, false
	)

	_controllers = [p1, p2]
	for c in _controllers:
		c.ev_lives_changed.connect(func(_l): _refresh_lives())
		c.ev_pawn_spawned.connect(_on_pawn_spawned.bind(c))
		# First pawn was spawned inside setup(), before we could listen.
		if c.pawn:
			_on_pawn_spawned(c.pawn, c)

	if game_config.ai_enabled:
		_ai_brain = AiBrain.new()
		_ai_brain.setup(p2, p1, game_config)
		add_child(_ai_brain)


func _on_pawn_spawned(pawn: Pawn, controller: PlayerController) -> void:
	pawn.ev_knocked.connect(_on_pawn_knocked)
	if controller.player_id == 0 and pawn.shield:
		pawn.shield.ev_charges_changed.connect(_refresh_shield_button)
		_refresh_shield_button(pawn.shield.charges, pawn.shield.max_charges)


# --- Match flow (called by GameManager states) ---

func on_countdown_tick(seconds_left: int) -> void:
	_show_banner(str(seconds_left), NeonPalette.UI_TEXT, true)


func on_match_start() -> void:
	_match_started = true
	for c in _controllers:
		c.set_input_enabled(true)
	if _ai_brain:
		_ai_brain.set_active(true)
	_show_banner("СТАРТ!", NeonPalette.UI_ACCENT, false)


func on_match_result(data: Dictionary) -> void:
	_match_started = false
	for c in _controllers:
		c.set_input_enabled(false)
	if _ai_brain:
		_ai_brain.set_active(false)
	var winner: int = int(data.get("winner_id", -1))
	if winner < 0:
		_show_banner("НИЧЬЯ", NeonPalette.UI_TEXT, true)
	elif game_config.ai_enabled:
		_show_banner("ПОБЕДА" if winner == 0 else "ПОРАЖЕНИЕ", NeonPalette.P1 if winner == 0 else NeonPalette.P2, true)
	else:
		_show_banner("ПОБЕДИЛ ИГРОК %d" % (winner + 1), NeonPalette.P1 if winner == 0 else NeonPalette.P2, true)


func on_match_end(data: Dictionary) -> void:
	if root_events:
		var payload := data.duplicate()
		payload["vs_ai"] = game_config.ai_enabled
		root_events.ev_exit_game.emit(payload)


func _show_banner(text: String, color: Color, persist: bool) -> void:
	if banner == null:
		return
	if _banner_tween:
		_banner_tween.kill()
	banner.text = text
	banner.add_theme_color_override("font_color", color)
	banner.modulate.a = 1.0
	banner.scale = Vector2(1.4, 1.4)
	_banner_tween = create_tween()
	_banner_tween.tween_property(banner, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not persist:
		_banner_tween.tween_interval(0.35)
		_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.3)


# --- Events ---

func _on_player_lost(player_id: int) -> void:
	var winner := 1 if player_id == 0 else 0
	# If both somehow lost, first signal wins
	if game_manager and game_manager.get_current_state_name() == GameState.get_state():
		game_manager.request_end(winner)


func _on_pawn_died(_player_id: int, _lives_left: int) -> void:
	_refresh_lives()
	_add_trauma(0.6)


func _on_pawn_knocked(strength: float) -> void:
	_add_trauma(strength / maxf(game_config.pawn_max_impulse, 0.001))


func _refresh_lives() -> void:
	if lives_label == null or _controllers.is_empty():
		return
	var parts: PackedStringArray = []
	var max_lives: int = game_config.player_lives
	for c in _controllers:
		var tag := "AI" if c.player_id == 1 and game_config.ai_enabled else ("P%d" % (c.player_id + 1))
		var alive := maxi(c.lives, 0)
		parts.append("%s  %s%s" % [tag, "❤".repeat(alive), "·".repeat(maxi(max_lives - alive, 0))])
	lives_label.text = "     ".join(parts)


func _refresh_shield_button(charges: int, max_charges: int) -> void:
	if shield_btn == null:
		return
	shield_btn.text = "ЩИТ\n%s%s" % ["●".repeat(charges), "○".repeat(maxi(max_charges - charges, 0))]
	shield_btn.modulate.a = 1.0 if charges > 0 else 0.45


func _on_attack_pressed() -> void:
	if _controllers.size() > 0:
		_controllers[0].request_attack()


func _on_shield_pressed() -> void:
	if _controllers.size() > 0:
		_controllers[0].request_shield()


# --- Aim arrow ---

func _update_aim() -> void:
	if aim_arrow == null or _aim_shaft == null or _controllers.is_empty():
		return
	var value: Vector2 = joystick.value if joystick else Vector2.ZERO
	var p: Pawn = _controllers[0].pawn
	if p == null or not is_instance_valid(p) or value.length() < _AIM_MIN:
		aim_arrow.visible = false
		return
	# Show opposite of pull (launch direction)
	var dir := Vector3(-value.x, 0.0, -value.y).normalized()
	var power := minf(value.length(), 1.0)
	var can_launch := _match_started and p.can_slingshot()
	var mat := _aim_ready_mat if can_launch else _aim_blocked_mat
	_aim_shaft.material_override = mat
	_aim_head.material_override = mat

	# Length ∝ charge
	var start := game_config.pawn_radius + 0.1
	var length := 0.35 + power * 1.6
	_aim_shaft.scale = Vector3(1.0, 1.0, length)
	_aim_shaft.position = Vector3(0, 0, -(start + length * 0.5))
	_aim_head.position = Vector3(0, 0, -(start + length + 0.14))

	aim_arrow.visible = true
	aim_arrow.global_position = Vector3(p.global_position.x, 0.06, p.global_position.z)
	aim_arrow.look_at(aim_arrow.global_position + dir, Vector3.UP)


# --- Camera shake ---

func _add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount * 0.6, 0.0, 1.0)


func _update_camera_shake(delta: float) -> void:
	if _camera == null:
		return
	if _trauma <= 0.0:
		_camera.position = _camera_base
		return
	_trauma = maxf(0.0, _trauma - game_config.camera_shake_decay * delta)
	_shaker.update(delta)
	var offset := _shaker.get_pos_offset() * (_trauma * _trauma) * game_config.camera_shake_strength * 2.0
	var cam_basis := _camera.global_transform.basis
	_camera.position = _camera_base + cam_basis.x * offset.x + cam_basis.y * offset.y
