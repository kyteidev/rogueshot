extends CharacterBody2D


enum State { IDLE, PATROL, INVESTIGATE, ALERT, RETURN, CHASE, SEARCH, ATTACK, RETREAT, DEAD }

const BULLET = preload("res://scenes/weapons/bullet.tscn")
const BULLET_SCALE = 0.2

const ANIM_REF_SPEED = 65.0
const ANIM_MIN_SCALE = 0.4
const ANIM_MAX_SCALE = 2.0
const ANIM_EXP = 0.34

const MAX_HEALTH = 100.0

const BASE_SPEED = 80.0
const RUN_SPEED = BASE_SPEED * 1.5
const PATROL_SPEED = 30.0
const JUMP_VELOCITY = -180.0

const GROUND_ACCEL = 900.0
const GROUND_FRICTION = 1100.0
const AIR_ACCEL = 600.0
const AIR_FRICTION = 300.0
const TURN_MULTIPLIER = 1.5

const GRAVITY = 750
const FALL_GRAVITY = GRAVITY * 1.5

const DAMAGE_FLASH_DELAY = 0.04

const PATROL_WEAPON_TILT = 15.0
const WEAPON_ROTATION_SPEED = 10.0
const WEAPON_SPREAD = 2.0
const WEAPON_KICK = 3.0
const WEAPON_KICK_RECOVERY = 42.0
const WEAPON_RELOAD_TIME = 2.3

const INV_DELAY = 1.0
const INV_MIN_MOVE_DIST = 20.0

const ALERT_DELAY = 0.3

const RETURN_DELAY = 3.5
const RETURN_DELAY_LONG = 8.0

const ATTACK_DELAY = 0.7
const ATTACK_FIRE_RATE = 0.12
const ATTACK_MAX_POS_DIFF = 180.0

const MAX_AMMO = 30

var state = State.PATROL
var target: CharacterBody2D = null
var died = false

var health = MAX_HEALTH
var direction = 1
var speed = 0.0
var ammo = MAX_AMMO

var is_detecting = false
var is_aggroing = false
var in_aggro_area = false

var known_target_pos: Vector2
var bullet_origin_pos: Vector2
var in_los = false

var kick_offset = 0.0
var desired_weapon_rotation = deg_to_rad(PATROL_WEAPON_TILT)

# index 0: question mark, index 1: exclamation mark
var status_icons = [preload("res://assets/sprites/icons/question mark.png"), preload("res://assets/sprites/icons/exclamation mark.png")]

@onready var anim = $AnimatedSprite2D
@onready var weapon = $Weapon
@onready var weapon_sprite = $Weapon/Rifle1
@onready var weapon_muzzle = $Weapon/Rifle1/Marker2D
@onready var weapon_los_ray = $Weapon/WeaponLOSRay
@onready var weapon_shoot_timer = $Weapon/WeaponShootTimer
@onready var weapon_reload_timer = $Weapon/WeaponReloadTimer
@onready var status_icon = $StatusIcon

@onready var wall_ray = $WallRay
@onready var high_wall_ray = $HighWallRay
@onready var ledge_ray = $LedgeRay
@onready var los_ray = $LOSRay

@onready var state_timer = $StateTimer

@onready var patrol_pos = global_position
@onready var weapon_rest_pos = weapon.position


func _process(_delta: float) -> void:
	# flip weapon if necessary
	var weapon_scale = weapon_sprite.scale.y
	if direction < 0:
		weapon_sprite.scale.y = abs(weapon_scale) * -1
	else:
		weapon_sprite.scale.y = abs(weapon_scale)
		

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity.y += _get_custom_gravity(velocity) * delta
		
	_check_awareness()
	
	# rotate weapon smoothly
	weapon.rotation = lerp_angle(weapon.rotation, desired_weapon_rotation, 1.0 - exp(-WEAPON_ROTATION_SPEED * delta))
		
	match state:
		State.IDLE: _state_idle()
		State.PATROL: _state_patrol()
		State.INVESTIGATE: _state_investigate()
		State.ALERT: _state_alert()
		State.RETURN: _state_return()
		State.CHASE: _state_chase()
		State.SEARCH: _state_search()
		State.ATTACK: _state_attack(delta)
		State.RETREAT: _state_retreat()
		State.DEAD: _state_dead(delta)
	
	# calculate x velocity
	var accel: float
	if direction == 0: # apply friction when not moving
		accel = GROUND_FRICTION if is_on_floor() else AIR_FRICTION
	else:
		accel = GROUND_ACCEL if is_on_floor() else AIR_ACCEL
		
		# makes turns faster
		if velocity.x != 0 and sign(velocity.x) != sign(direction):
			accel *= TURN_MULTIPLIER
			
	if state != State.DEAD:
		velocity.x = move_toward(velocity.x, direction * speed, accel * delta)
	
	move_and_slide()
	

func take_damage(damage) -> void:
	if state == State.DEAD:
		return
		
	if state != State.ATTACK and state != State.CHASE:
		# delay changing state to end of frame so that bullet origin pos is correct
		(func(): _change_state(State.ALERT)).call_deferred()
	
	# flash red when taking damage
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("ff0000"), DAMAGE_FLASH_DELAY)
	tween.tween_property(self, "modulate", Color("ffffff"), DAMAGE_FLASH_DELAY)
	
	health -= damage
	if health <= 0:
		_change_state(State.DEAD)
		status_icon.visible = false
		
		# make enemy red when dead
		tween.tween_property(self, "modulate", Color("ff0000"), DAMAGE_FLASH_DELAY)


func set_target_pos(pos) -> void:
	bullet_origin_pos = pos


func _set_run_anim(move_speed) -> void:
	anim.speed_scale = clamp((move_speed / ANIM_REF_SPEED) ** ANIM_EXP, ANIM_MIN_SCALE, ANIM_MAX_SCALE)
	anim.play("run")


func _get_custom_gravity(vel) -> float:
	if vel.y < 0:
		return GRAVITY
	return FALL_GRAVITY
	

func _change_state(new_state, long_delay := false) -> void:
	# make sure state is not changed to same state again
	if state == State.DEAD or state == new_state:
		return
		
	state = new_state
	_enter_state(new_state, long_delay)


func _enter_state(new_state, long_delay) -> void:
	match new_state:
		State.PATROL:
			speed = PATROL_SPEED
		State.INVESTIGATE, State.ALERT, State.ATTACK:
			# stop for a while when entering these states
			anim.play("idle")
			speed = 0.0
			
			status_icon.texture = status_icons[1] if state == State.ATTACK else status_icons[0]
			status_icon.play_anim()
			
			var pos_diff = global_position.x - known_target_pos.x
			
			match new_state:
				State.ATTACK:
					state_timer.start(ATTACK_DELAY)
					status_icon.can_fade = true
				State.INVESTIGATE:
					state_timer.start(INV_DELAY)
				State.ALERT:
					state_timer.start(ALERT_DELAY)
					
					pos_diff = global_position.x - bullet_origin_pos.x
	
			direction = 1 if pos_diff < 0 else -1
			_point_toward(direction)
		State.RETURN:
			speed = 0.0
			state_timer.start(RETURN_DELAY if not long_delay else RETURN_DELAY_LONG)
			
			if high_wall_ray.is_colliding():
				direction *= -1
				_point_toward(direction)


func _check_awareness() -> void:
	# make sure enemy is not dead and player is detected
	if state == State.DEAD or not is_detecting or not target:
		return
	
	# get player los target pos and cast ray if enemy faces player
	# abs(poss_diff) > 3.0 prevents enemy losing sight if target jumps over enemy
	var target_pos = target.get_node("LOSTarget").global_position
	var pos_diff = global_position.x - target_pos.x
	if sign(pos_diff) == sign(direction) and abs(pos_diff) > 3.0:
		return
	
	los_ray.look_at(target_pos)
	los_ray.force_raycast_update()
		
	# make sure enemy has line of sight to player
	var ray_target = los_ray.get_collider()
	if ray_target and ray_target.is_in_group("player"):
		if state != State.CHASE and state != State.ALERT:
			_change_state(State.ATTACK if is_aggroing else State.INVESTIGATE)
		# update known target position if still in line of sight
		known_target_pos = target_pos
		in_los = true
	else:
		in_los = false


func _state_idle() -> void:
	anim.play("idle")
	anim.speed_scale = 1.0
	

func _state_patrol() -> void:
	_set_run_anim(PATROL_SPEED)
	
	# flip necessary values
	if is_on_floor() and (wall_ray.is_colliding() or not ledge_ray.is_colliding()):
		direction *= -1
	_point_toward(direction)
	speed = PATROL_SPEED
	
	# tilt weapon
	# directly set weapon rotation because when enemy flips direction, weapon should instantly flip too
	desired_weapon_rotation = deg_to_rad(PATROL_WEAPON_TILT if direction > 0 else 180.0 - PATROL_WEAPON_TILT)
	weapon.rotation = desired_weapon_rotation
	

func _state_investigate() -> void:
	if state_timer.is_stopped():
		# move towards known target position
		# known target position only updates when it is in detection area
		var pos_diff = _move_toward(known_target_pos, BASE_SPEED, true)
		if pos_diff == 0:
			_change_state(State.RETURN)


func _state_alert() -> void:
	# alert state is same as investigate, but enemy will aggro on detection area entered
	if state_timer.is_stopped():
		# enemy is cautious, so slower movement
		var pos_diff = _move_toward(bullet_origin_pos, PATROL_SPEED, true)
		if pos_diff == 0:
			_change_state(State.RETURN)
			return
		
		if is_detecting and in_los:
			_change_state(State.ATTACK)
			is_aggroing = true


func _state_return() -> void:
	if state_timer.is_stopped():
		# rotate weapon
		desired_weapon_rotation = deg_to_rad(PATROL_WEAPON_TILT if direction > 0 else 180.0 - PATROL_WEAPON_TILT)
		
		# move toward patrol position
		var pos_diff = _move_toward(patrol_pos, PATROL_SPEED)
		if pos_diff == 0:
			_change_state(State.PATROL)
			
			# fade status icon
			status_icon.fade_timer.start()
			status_icon.can_fade = true


func _state_chase() -> void:
	var pos_diff = _move_toward(known_target_pos, RUN_SPEED, true)
	
	if is_detecting and in_los:
		_change_state(State.ATTACK)
		is_aggroing = true
	
	if pos_diff == 0 and (not is_detecting or not in_los):
		_change_state(State.RETURN)
		# TODO: implement search state
	

func _state_search() -> void:
	pass

	
func _state_attack(delta) -> void:
	# chase target if outside detection range
	if not is_detecting:
		_change_state(State.CHASE)
		return
	
	# rotate weapon towards target
	desired_weapon_rotation = (known_target_pos - global_position).angle()
	
	# after attack delay has passed
	if state_timer.is_stopped():
		kick_offset = move_toward(kick_offset, 0.0, WEAPON_KICK_RECOVERY * delta)
		weapon.position = weapon_rest_pos + kick_offset * Vector2.from_angle(weapon.rotation)
		
		# if target in aggro area and has line of sight, don't move
		# if not, move until target is in aggro area and in line of sight.
		var target_pos_diff = abs(global_position - known_target_pos)
		if in_los and target_pos_diff.x < ATTACK_MAX_POS_DIFF:
			# make sure weapon also has line of sight, otherwise enemy just shoots at ground
			# if weapon doesn't have line of sight, move towards known target pos
			weapon_los_ray.force_raycast_update()
			
			var ray_target = weapon_los_ray.get_collider()
			if ray_target and ray_target.is_in_group("player"):
				speed = 0.0
				
				anim.speed_scale = 1.0
				anim.play("idle")
			else:
				_move_toward(known_target_pos, BASE_SPEED)
		else:
			var pos_diff = _move_toward(known_target_pos, BASE_SPEED)
		
			if pos_diff == 0 and not in_los:
				_change_state(State.RETURN, true)
				
		# fire weapon
		if weapon_shoot_timer.is_stopped():
			_shoot()
			weapon_shoot_timer.start(ATTACK_FIRE_RATE)


func _state_retreat() -> void:
	pass


func _state_dead(delta) -> void:
	# if enemy is moving, quickly but smoothly stop
	velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)

	# once enemy has stopped, destroy node
	if velocity.x == 0.0 and is_on_floor():
		if not died:
			died = true
			anim.play("death")
		elif not anim.is_playing():
			var tween = create_tween()
			tween.tween_property(self, "modulate", Color("ffffff00"), 0.5)
			tween.finished.connect(queue_free)
			

func _shoot() -> void:
	if ammo > 0 and weapon_reload_timer.is_stopped():
		var bullet_instance = BULLET.instantiate()
		bullet_instance.type = bullet_instance.Types.ENEMY
		get_tree().root.add_child(bullet_instance)
		
		var spread_angle = deg_to_rad(randf_range(-WEAPON_SPREAD, WEAPON_SPREAD))
		
		bullet_instance.global_position = weapon_muzzle.global_position
		bullet_instance.rotation = weapon.global_rotation + spread_angle
		bullet_instance.scale = Vector2(BULLET_SCALE, BULLET_SCALE)
		
		kick_offset = min(kick_offset + WEAPON_KICK, WEAPON_KICK * 2.0)
		
		ammo -= 1
	elif ammo == 0:
		weapon_reload_timer.start(WEAPON_RELOAD_TIME)
		ammo = MAX_AMMO


func _move_toward(pos, move_speed, raise_weapon := false) -> float:
	var pos_diff = global_position.x - pos.x
		
	if abs(pos_diff) < 1.0:
		speed = 0.0
		anim.play("idle")
		return 0.0
	
	# moving horizontally
	_set_run_anim(move_speed)
	direction = 1 if pos_diff < 0 else -1
	speed = move_speed
	
	_point_toward(direction)
	
	# jump if necessary
	if wall_ray.is_colliding() and not high_wall_ray.is_colliding() and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# tilt weapon if needed
	if raise_weapon:
		desired_weapon_rotation = 0.0 if direction > 0 else PI
	
	return pos_diff
	

func _point_toward(point_direction) -> void:
	anim.flip_h = false
	wall_ray.target_position = abs(wall_ray.target_position)
	high_wall_ray.target_position = abs(high_wall_ray.target_position)
	ledge_ray.position.x = abs(ledge_ray.position.x)
	status_icon.position.x = abs(status_icon.position.x)
	
	if point_direction < 0:
		anim.flip_h = not anim.flip_h
		wall_ray.target_position *= -1
		high_wall_ray.target_position *= -1
		ledge_ray.position.x *= -1
		status_icon.position.x *= -1


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_detecting = true
		target = body
		

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_detecting = false
		target = null
		
		is_aggroing = false


func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_aggroing = true
		in_aggro_area = true


func _on_aggro_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		in_aggro_area = false


func _on_close_range_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_change_state(State.ATTACK) # there's probably a more efficient way to do this
