extends CharacterBody2D


const SPEED = 60.0
const MAX_SPEED = 500.0

const WALLBOUNCE_VELOCITY = 300
const AIR_MAX_SPEED = 180.0
const AIR_ACCEL = 800.0

const GROUND_FRICTION = 0.7
const AIR_FRICTION = 0.75
const JUMP_VELOCITY = -250.0
const JUMP_VELOCITY_CUT = JUMP_VELOCITY / 3

const GRAVITY = 900
const FALL_GRAVITY = GRAVITY * 1.5

const COYOTE_TIME = 0.1
@onready var coyote_timer = $CoyoteTimer

const JUMP_BUFFER_TIME = 0.1
@onready var jump_buffer_timer = $JumpBufferTimer

@onready var anim_sprite = $AnimatedSprite2D


func get_custom_gravity(vel) -> float:
	if vel.y < 0:
		return GRAVITY
	return FALL_GRAVITY


func _physics_process(delta: float) -> void:
	var was_on_floor = is_on_floor()
	
	# gravity
	if not is_on_floor():
		velocity.y += get_custom_gravity(velocity) * delta
		
	# player jump system
	if Input.is_action_just_pressed("player_jump"):
		jump_buffer_timer.start(JUMP_BUFFER_TIME)
		
	if Input.is_action_just_released("player_jump") and velocity.y < JUMP_VELOCITY_CUT:
		velocity.y = JUMP_VELOCITY_CUT

	var wants_jump = not jump_buffer_timer.is_stopped()
	var can_jump = is_on_floor() or not coyote_timer.is_stopped()

	if wants_jump and can_jump:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer.stop()
		coyote_timer.stop()
	
	# reduce y velocity if player hits ceiling
	if is_on_ceiling():
		velocity.y *= 0.5
	
	# flip direction
	var direction := Input.get_axis("player_left", "player_right")
	if direction > 0:
		anim_sprite.flip_h = false
	elif direction < 0:
		anim_sprite.flip_h = true
	
	# plays correct animation
	if is_on_floor():
		if direction == 0:
			anim_sprite.play("idle")
		else:
			anim_sprite.play("run")
	else:
		anim_sprite.play("jump")
	
	# calculate x velocity
	if is_on_floor():
		if velocity.x < 0.01 and velocity.x > -0.01: # otherwise velocity x would never be 0
			velocity.x = 0
		velocity.x = (velocity.x + clamp(direction * SPEED, -MAX_SPEED, MAX_SPEED)) * GROUND_FRICTION
	else:
		velocity.x = move_toward(velocity.x, direction * AIR_MAX_SPEED, AIR_ACCEL * delta)
	
	# wallbounce
	if is_on_wall() and not is_on_floor() and Input.is_action_just_pressed("player_jump"):
		velocity.x += WALLBOUNCE_VELOCITY * get_wall_normal().x
		velocity.y = JUMP_VELOCITY
		
		coyote_timer.stop()
		jump_buffer_timer.stop()

	move_and_slide()
	
	# coyote time management
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyote_timer.start(COYOTE_TIME)
