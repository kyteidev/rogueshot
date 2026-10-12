extends CharacterBody2D


var sm = StateManager
@export var crosshair: CanvasLayer

const BASE_SPEED = 60.0
const MAX_SPEED = 500.0
const SPRINT_MULTIPLIER = 1.5

const MAX_STAMINA = 100.0
const STAMINA_RECOVERY_DELAY = 2.0
const STAMINA_RECOVERY_RATE = 20.0
const STAMINA_SLOW_RECOVERY_MULTIPLIER = 0.75

const SPRINT_STAMINA_RATE = 25.0
const WALLBOUNCE_STAMINA_RATE = 20.0
const SHOOT_STAMINA_RATE = 2.0

const WALLBOUNCE_VELOCITY = 250
const AIR_MAX_SPEED = 180.0
const AIR_ACCEL = 800.0

const GROUND_FRICTION = 0.7
const AIR_FRICTION = 0.75
const JUMP_VELOCITY = -250.0
const JUMP_VELOCITY_CUT = JUMP_VELOCITY / 3

const GRAVITY = 900
const FALL_GRAVITY = GRAVITY * 1.5

const STRETCH = 0.3

const COYOTE_TIME = 0.1
@onready var coyote_timer = $CoyoteTimer

const JUMP_BUFFER_TIME = 0.1
@onready var jump_buffer_timer = $JumpBufferTimer

@onready var anim_sprite = $AnimatedSprite2D
@onready var stamina_timer = $StaminaTimer

var was_airborne = false
var reached_peak = false

var speed = 0.0
var sprinting = false

var regenerating_stamina = true
var prev_stamina = MAX_STAMINA
var stamina:
	set(value):
		stamina = clamp(value, 0.0, 100.0)
		sm.stamina = stamina
		
		if not regenerating_stamina:
			stamina_timer.start(STAMINA_RECOVERY_DELAY)
		else:
			regenerating_stamina = false
			
		if value < prev_stamina:
			sm.used_stamina = true
		prev_stamina = value
		
		if stamina == 0:
			stamina_depleted = true
var stamina_depleted = false:
	set(value):
		stamina_depleted = value
		sm.stamina_depleted = value
		

func _ready() -> void:
	# have this in _ready so max stamina only needs to be adjusted here,
	# otherwise i'd have to change max stamina here and in state manager
	stamina = MAX_STAMINA


func get_custom_gravity(vel) -> float:
	if vel.y < 0:
		return GRAVITY
	return FALL_GRAVITY


func _physics_process(delta: float) -> void:
	var was_on_floor = is_on_floor()
	
	# gravity and jump stretch
	if not is_on_floor():
		velocity.y += get_custom_gravity(velocity) * delta
		was_airborne = true
		
		if not reached_peak and velocity.y >= 0:
			reached_peak = true
			anim_sprite.scale = Vector2(1.0, 1.0)
		
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
		
		# jump stretch
		anim_sprite.scale = Vector2(1 - STRETCH, 1 + STRETCH)
		reached_peak = false
	
	# reduce y velocity if player hits ceiling
	if is_on_ceiling():
		velocity.y *= 0.5
		
	# sprint system
	speed = BASE_SPEED
	if is_on_floor():
		if Input.is_action_pressed("player_sprint") and stamina > 0.0 and not stamina_depleted:
			sprinting = true
			speed *= SPRINT_MULTIPLIER
			stamina -= SPRINT_STAMINA_RATE * delta
			
			if sm.reloading:
				crosshair.cancel_reload()
		else:
			sprinting = false
			
	# recover stamina when not sprinting
	if stamina_timer.is_stopped():
		regenerating_stamina = true
		stamina += STAMINA_RECOVERY_RATE * delta * (STAMINA_SLOW_RECOVERY_MULTIPLIER if stamina_depleted else 1.0)
		
		if stamina == MAX_STAMINA:
			stamina_depleted = false
	
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
			anim_sprite.speed_scale = 1.5 if sprinting else 1.0
			anim_sprite.play("run")
	else:
		anim_sprite.play("jump")
	
	# calculate x velocity
	if is_on_floor():
		if velocity.x < 0.01 and velocity.x > -0.01: # otherwise velocity x would never be 0
			velocity.x = 0
		velocity.x = (velocity.x + clamp(direction * speed, -MAX_SPEED, MAX_SPEED)) * GROUND_FRICTION
	else:
		velocity.x = move_toward(velocity.x, direction * AIR_MAX_SPEED, AIR_ACCEL * delta)
	
	# wallbounce
	if is_on_wall() and not is_on_floor() and Input.is_action_just_pressed("player_jump") and stamina > 0.0 and not stamina_depleted:
		var wall_normal = get_wall_normal().x
		if wall_normal > 0:
			anim_sprite.flip_h = false
		elif wall_normal < 0:
			anim_sprite.flip_h = true
		
		velocity.x += WALLBOUNCE_VELOCITY * wall_normal
		velocity.y = JUMP_VELOCITY
		
		stamina -= WALLBOUNCE_STAMINA_RATE
		
		coyote_timer.stop()
		jump_buffer_timer.stop()
		
		# jump stretch
		anim_sprite.scale = Vector2(1 - STRETCH, 1 + STRETCH)
		reached_peak = false
	
	# smoothly revert back from jump stretch scale to normal scale
	anim_sprite.scale = anim_sprite.scale.lerp(Vector2(1.0, 1.0), 10.0 * delta)

	move_and_slide()
	
	# coyote time management
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyote_timer.start(COYOTE_TIME)
