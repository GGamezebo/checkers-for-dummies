class_name AiBrain
extends Node

## Simple arena AI: slingshot toward the player, attack in range, shield under threat.
## Drives a PlayerController's pawn — no raw input.

enum State { WAIT, WINDUP, RECOVER }

var self_controller: PlayerController
var foe_controller: PlayerController
var config: GameConfig
var active: bool = false

var _state: int = State.WAIT
var _think_left: float = 0.0
var _windup_left: float = 0.0
var _recover_left: float = 0.0
var _planned_pull: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func setup(mine: PlayerController, foe: PlayerController, game_config: GameConfig) -> void:
	self_controller = mine
	foe_controller = foe
	config = game_config
	_rng.randomize()
	_think_left = _rng.randf_range(0.2, 0.6)
	name = "AiBrain"


func set_active(on: bool) -> void:
	active = on
	_state = State.WAIT
	_planned_pull = Vector2.ZERO
	if on:
		_think_left = config.ai_think_interval if config else 0.4


func _process(delta: float) -> void:
	if not active or config == null or not config.ai_enabled:
		return
	if self_controller == null or foe_controller == null:
		return

	var me := self_controller.pawn
	if me == null or not is_instance_valid(me) or me.is_dead:
		_state = State.WAIT
		return

	match _state:
		State.WINDUP:
			_tick_windup(delta, me)
		State.RECOVER:
			_recover_left -= delta
			if _recover_left <= 0.0:
				_state = State.WAIT
				_think_left = config.ai_think_interval * _rng.randf_range(0.6, 1.2)
		_:
			_tick_wait(delta, me)


func _tick_wait(delta: float, me: Pawn) -> void:
	_think_left -= delta
	if _think_left > 0.0:
		return
	_think_left = config.ai_think_interval

	var foe := _foe_pawn()
	if foe == null:
		return

	_try_defensive(me, foe)
	_try_offensive(me, foe)

	if not me.can_slingshot():
		return

	_planned_pull = _choose_sling_pull(me, foe)
	if _planned_pull.length() < 0.2:
		return

	_state = State.WINDUP
	_windup_left = _rng.randf_range(0.12, 0.35)


func _tick_windup(delta: float, me: Pawn) -> void:
	_windup_left -= delta
	if _windup_left > 0.0:
		return
	if me.can_slingshot():
		me.apply_slingshot(_planned_pull)
	_state = State.RECOVER
	_recover_left = _rng.randf_range(0.25, 0.55)
	_planned_pull = Vector2.ZERO


func _try_defensive(me: Pawn, foe: Pawn) -> void:
	if not me.can_accept_input():
		return
	if me.shield == null or me.shield.charges <= 0 or me.shield.is_active:
		return

	var dist := _planar_dist(me, foe)
	var foe_speed := Vector3(foe.linear_velocity.x, 0.0, foe.linear_velocity.z).length()
	var incoming := foe_speed > me.min_flight_speed * 0.85 and dist < config.ai_shield_range
	var close_threat := dist < config.ai_shield_range * 0.65 and foe.attack != null and foe.attack.is_active

	if incoming or close_threat:
		# Face the threat so shield forward check can work
		_face_toward(me, foe.global_position)
		me.try_shield()


func _try_offensive(me: Pawn, foe: Pawn) -> void:
	if not me.can_accept_input():
		return
	var dist := _planar_dist(me, foe)
	if dist > config.ai_attack_range:
		return
	# Prefer attack when roughly aimed at foe
	var to_foe := foe.global_position - me.global_position
	to_foe.y = 0.0
	if to_foe.length_squared() < 0.0001:
		return
	var forward := -me.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		_face_toward(me, foe.global_position)
		forward = -me.global_transform.basis.z
	if forward.normalized().dot(to_foe.normalized()) < 0.35:
		_face_toward(me, foe.global_position)
		return
	if _rng.randf() <= config.ai_aggression:
		me.try_attack()


func _choose_sling_pull(me: Pawn, foe: Pawn) -> Vector2:
	var my_pos := me.global_position
	var foe_pos := foe.global_position

	# Lead target a bit by velocity
	var lead := Vector3(foe.linear_velocity.x, 0.0, foe.linear_velocity.z) * 0.18
	var aim_at := foe_pos + lead

	var arena_r: float = config.arena_half_size
	var radial := Vector3(my_pos.x, 0.0, my_pos.z).length()
	var near_edge := radial > arena_r - config.ai_edge_margin

	var launch := Vector3.ZERO
	if near_edge:
		# First priority: pull back toward center safety
		var to_center := Vector3(-my_pos.x, 0.0, -my_pos.z)
		if to_center.length_squared() > 0.0001:
			launch = to_center.normalized()
		# Blend a bit toward enemy so we don't only hug the middle
		var to_foe := aim_at - my_pos
		to_foe.y = 0.0
		if to_foe.length_squared() > 0.0001:
			launch = (launch * 0.65 + to_foe.normalized() * 0.35).normalized()
	else:
		var to_foe := aim_at - my_pos
		to_foe.y = 0.0
		if to_foe.length_squared() < 0.0001:
			return Vector2.ZERO
		launch = to_foe.normalized()

	# Jitter aim
	var jitter := config.ai_aim_jitter
	launch = launch.rotated(Vector3.UP, _rng.randf_range(-jitter, jitter))

	# Power from distance + aggression; slingshot pull is OPPOSITE of launch
	var dist := _planar_dist(me, foe)
	var power := clampf(dist / (arena_r * 1.4), config.ai_min_sling_power, 1.0)
	power = clampf(power * lerpf(0.85, 1.05, config.ai_aggression), 0.4, 1.0)
	if near_edge:
		power = minf(power, 0.85)

	var pull3 := -launch * power
	# Map world XZ → joystick XY (same as Pawn.apply_slingshot inverse)
	# apply_slingshot: dir = (-pull.x, 0, -pull.y) → pull = (-dir.x, -dir.z)
	return Vector2(pull3.x, pull3.z)


func _foe_pawn() -> Pawn:
	if foe_controller == null:
		return null
	var p: Pawn = foe_controller.pawn
	if p == null or not is_instance_valid(p) or p.is_dead:
		return null
	return p


func _planar_dist(a: Pawn, b: Pawn) -> float:
	var d := b.global_position - a.global_position
	d.y = 0.0
	return d.length()


func _face_toward(me: Pawn, target: Vector3) -> void:
	var dir := target - me.global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return
	me.look_at(me.global_position + dir.normalized(), Vector3.UP)
