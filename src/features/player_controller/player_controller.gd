class_name PlayerController
extends Node

## Reads player input and forwards it to the pawn.
## On death: after delay respawns a pawn and spends a life. Lives == 0 → lose.

signal ev_lives_changed(lives: int)
signal ev_lost(player_id: int)
signal ev_pawn_spawned(pawn: Pawn)

@export var player_id: int = 0
@export var team_color: Color = Color(0.2, 0.45, 0.95)
@export var spawn_point: Vector3 = Vector3(0, 0.5, 3)
@export var pawn_scene: PackedScene
@export var use_keyboard_fallback: bool = false

var lives: int = 3
var pawn: Pawn
var joystick: SlingshotJoystick
var game_config: GameConfig
var game_events: GameEvents
var arena_parent: Node3D

var _respawn_left: float = -1.0
var _aim_vector: Vector2 = Vector2.ZERO
var _aiming: bool = false


func setup(
	config: GameConfig,
	events: GameEvents,
	parent_3d: Node3D,
	id: int,
	color: Color,
	spawn: Vector3,
	joy: SlingshotJoystick = null,
	keyboard: bool = false,
) -> void:
	game_config = config
	game_events = events
	arena_parent = parent_3d
	player_id = id
	team_color = color
	spawn_point = spawn
	joystick = joy
	use_keyboard_fallback = keyboard
	lives = config.player_lives
	if pawn_scene == null:
		pawn_scene = preload("res://src/features/pawn/pawn.tscn")
	if joystick:
		joystick.ev_released.connect(_on_joystick_released)
		joystick.ev_changed.connect(_on_joystick_changed)
	ev_lives_changed.emit(lives)
	_spawn_pawn()


func _process(delta: float) -> void:
	if _respawn_left >= 0.0:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_respawn_left = -1.0
			if lives > 0:
				_spawn_pawn()
		return

	if pawn == null or not is_instance_valid(pawn):
		return

	if use_keyboard_fallback:
		_poll_keyboard()
		if Input.is_action_just_pressed("attack"):
			pawn.try_attack()
		if Input.is_action_just_pressed("shield"):
			pawn.try_shield()


func request_attack() -> void:
	if pawn and is_instance_valid(pawn):
		pawn.try_attack()


func request_shield() -> void:
	if pawn and is_instance_valid(pawn):
		pawn.try_shield()


func _on_joystick_changed(value: Vector2) -> void:
	_aim_vector = value
	_aiming = value.length() > 0.05


func _on_joystick_released(value: Vector2) -> void:
	_aiming = false
	if pawn and is_instance_valid(pawn):
		pawn.apply_slingshot(value)
	_aim_vector = Vector2.ZERO


func _poll_keyboard() -> void:
	## WASD as slingshot pull (release Space to launch is awkward); use hold+release via keys:
	## hold direction keys to aim, press Enter/E to launch.
	var pull := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		pull.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		pull.x += 1.0
	if Input.is_key_pressed(KEY_W):
		pull.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		pull.y += 1.0
	if pull.length() > 0.0:
		_aim_vector = pull.limit_length(1.0)
		_aiming = true
	if Input.is_key_pressed(KEY_E) and _aiming:
		if pawn:
			pawn.apply_slingshot(_aim_vector)
		_aiming = false
		_aim_vector = Vector2.ZERO


func _spawn_pawn() -> void:
	if arena_parent == null:
		return
	pawn = pawn_scene.instantiate() as Pawn
	arena_parent.add_child(pawn)
	pawn.initialize(game_config, player_id, team_color, spawn_point)
	pawn.ev_died.connect(_on_pawn_died)
	ev_pawn_spawned.emit(pawn)


func _on_pawn_died(_p: Pawn) -> void:
	pawn = null
	lives -= 1
	ev_lives_changed.emit(lives)
	if game_events:
		game_events.ev_pawn_died.emit(player_id, lives)
	if lives <= 0:
		ev_lost.emit(player_id)
		if game_events:
			game_events.ev_player_lost.emit(player_id)
		return
	_respawn_left = game_config.respawn_delay
