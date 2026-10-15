extends CharacterBody2D


enum State { IDLE, PATROL, INVESTIGATE, RETURN, CHASE, ATTACK, RETREAT, DEAD }

const MAX_HEALTH = 100.0

const BASE_SPEED = 80.0
const PATROL_SPEED = 30.0
const JUMP_VELOCITY = -200.0

const GROUND_ACCEL = 900.0
const GROUND_FRICTION = 1100.0
const AIR_ACCEL = 600.0
const AIR_FRICTION = 300.0
const TURN_MULTIPLIER = 1.5

const GRAVITY = 750
const FALL_GRAVITY = GRAVITY * 1.5

const DAMAGE_FLASH_DELAY = 0.04

const PATROL_WEAPON_TILT = 15.0

const INV_DELAY = 1.0
const INV_MIN_MOVE_DIST = 20.0

const RETURN_DELAY = 2.5

var state = State.PATROL
var target: CharacterBody2D = null
var died = false

var health = MAX_HEALTH
var direction = 1
var speed = 0.0

var is_detecting = false
var is_aggroing = false

var known_target_pos: Vector2

# index 0: question mark, index 1: exclamation mark
var status_icons = [preload("res://assets/sprites/icons/question mark.png"), preload("res://assets/sprites/icons/exclamation mark.png")]

@onready var anim = $AnimatedSprite2D
@onready var weapon = $Weapon
@onready var weapon_sprite = $Weapon/Rifle1
@onready var status_icon = $StatusIcon

@onready var wall_ray = $WallRay
@onready var ledge_ray = $LedgeRay
@onready var los_ray = $LOSRay

@onready var state_timer = $StateTimer

@onready var patrol_pos = global_position


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
		
	match state:
		State.IDLE: _state_idle()
		State.PATROL: _state_patrol()
		State.INVESTIGATE: _state_investigate()
		State.RETURN: _state_return()
		State.CHASE: _state_chase()
		State.ATTACK: _state_attack()
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
	
	# flash red when taking damage
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("ff0000"), DAMAGE_FLASH_DELAY)
	tween.tween_property(self, "modulate", Color("ffffff"), DAMAGE_FLASH_DELAY)
	
	
	health -= damage
	if health <= 0:
		_change_state(State.DEAD)
		
		# make enemy red when dead
		tween.tween_property(self, "modulate", Color("ff0000"), DAMAGE_FLASH_DELAY)


func _get_custom_gravity(vel) -> float:
	if vel.y < 0:
		return GRAVITY
	return FALL_GRAVITY
	

func _change_state(new_state) -> void:
	# make sure state is not changed to same state again
	if state == State.DEAD or state == new_state:
		return
		
	state = new_state
	_enter_state(new_state)


func _enter_state(new_state) -> void:
	match new_state:
		State.PATROL:
			speed = PATROL_SPEED
		State.INVESTIGATE, State.ATTACK:
			anim.play("idle")
			speed = 0.0
			
			status_icon.texture = status_icons[0] if state == State.INVESTIGATE else status_icons[1]
			status_icon.play_anim()
			
			state_timer.start(INV_DELAY)
			
			if state == State.ATTACK:
				status_icon.can_fade = true
		State.RETURN:
			speed = 0.0
			state_timer.start(RETURN_DELAY)
			# TODO: hide status icon


func _check_awareness() -> void:
	# make sure enemy is not dead and player is detected
	if state == State.DEAD or not is_detecting or not target:
		return
	
	# get player los target pos and cast ray if enemy faces player
	var target_pos = target.get_node("LOSTarget").global_position
	if sign(global_position.x - target_pos.x) == sign(direction):
		return
	
	los_ray.look_at(target_pos)
	los_ray.force_raycast_update()
		
	# make sure enemy has line of sight to player
	var ray_target = los_ray.get_collider()
	if ray_target and ray_target.is_in_group("player"):
		_change_state(State.ATTACK if is_aggroing else State.INVESTIGATE)
		
		# update known target position if still in line of sight
		known_target_pos = target_pos


func _state_idle() -> void:
	anim.play("idle")
	anim.speed_scale = 1.0
	

func _state_patrol() -> void:
	anim.play("run")
	anim.speed_scale = 0.7
	
	# flip necessary values
	if is_on_floor() and (wall_ray.is_colliding() or not ledge_ray.is_colliding()):
		direction *= -1
	_point_toward(direction)
	speed = PATROL_SPEED
	

func _state_investigate() -> void:
	if state_timer.is_stopped():
		anim.speed_scale = 1.0
		
		# move towards known target position
		# known target position only updates when it is in detection area
		var pos_diff = _move_toward(known_target_pos, BASE_SPEED)
		if pos_diff == 0:
			_change_state(State.RETURN)


func _state_return() -> void:
	if state_timer.is_stopped():
		anim.speed_scale = 0.7
		
		# move toward patrol position
		var pos_diff = _move_toward(patrol_pos, PATROL_SPEED)
		if pos_diff == 0:
			_change_state(State.PATROL)
			
			# fade status icon
			status_icon.fade_timer.start()
			status_icon.can_fade = true


func _state_chase() -> void:
	pass
	
	
func _state_attack() -> void:
	pass


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
			

func _move_toward(pos, move_speed) -> float:
	var pos_diff = global_position.x - pos.x
		
	if abs(pos_diff) < 1.0:
		speed = 0.0
		anim.play("idle")
		return 0.0

	anim.play("run")
	direction = 1 if pos_diff < 0 else -1
	speed = move_speed
	
	_point_toward(direction)
	
	return pos_diff
	

func _point_toward(point_direction) -> void:
	weapon.rotation = deg_to_rad(PATROL_WEAPON_TILT if point_direction > 0 else 180.0 - PATROL_WEAPON_TILT)
	
	anim.flip_h = false
	wall_ray.target_position = abs(wall_ray.target_position)
	ledge_ray.position.x = abs(ledge_ray.position.x)
	status_icon.position.x = abs(status_icon.position.x)
	
	if point_direction < 0:
		anim.flip_h = not anim.flip_h
		wall_ray.target_position *= -1
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
