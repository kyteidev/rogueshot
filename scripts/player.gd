extends CharacterBody2D


const BASE_SPEED = 126.0
const SPRINT_MULTIPLIER = 1.25

const MAX_STAMINA = 100.0
const STAMINA_RECOVERY_DELAY = 1.5
const STAMINA_RECOVERY_RATE = 30.0
const STAMINA_SLOW_RECOVERY_MULTIPLIER = 0.45

const SPRINT_STAMINA_RATE = 20.0
const WALLBOUNCE_STAMINA_RATE = 15.0
const SHOOT_STAMINA_RATE = 2.0

const WALLBOUNCE_VELOCITY = 150

const GROUND_ACCEL = 900.0
const GROUND_FRICTION = 1100.0
const AIR_ACCEL = 600.0
const AIR_FRICTION = 300.0
const TURN_MULTIPLIER = 1.5

const JUMP_VELOCITY = -200.0
const JUMP_VELOCITY_CUT = JUMP_VELOCITY / 3

const GRAVITY = 750
const FALL_GRAVITY = GRAVITY * 1.5

const STRETCH = 0.2

const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.12

@export var crosshair: CanvasLayer

var sm = StateManager

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
		
@onready var coyote_timer = $CoyoteTimer
@onready var jump_buffer_timer = $JumpBufferTimer

@onready var anim_sprite = $AnimatedSprite2D
@onready var stamina_timer = $StaminaTimer


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
	
	# get direction of player
	# right: 1, left: -1, neutral (not moving): 0
	var direction = Input.get_axis("player_left", "player_right")
		
	# sprint system
	if is_on_floor():
		speed = BASE_SPEED
		if Input.is_action_pressed("player_sprint") and stamina > 0.0 and not stamina_depleted:
			sprinting = true
			speed *= SPRINT_MULTIPLIER
			
			# don't deplete stamina if not moving
			if direction != 0.0:
				stamina -= SPRINT_STAMINA_RATE * delta
			
			# cancel reload if sprinting
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
	if direction > 0:
		anim_sprite.flip_h = false
	elif direction < 0:
		anim_sprite.flip_h = true
	
	# plays correct animation
	if is_on_floor():
		if direction == 0:
			anim_sprite.play("idle")
		else:
			anim_sprite.speed_scale = SPRINT_MULTIPLIER if sprinting else 1.0
			anim_sprite.play("run")
	else:
		anim_sprite.play("jump")
	
	# calculate x velocity
	var accel: float
	if direction == 0: # apply friction when not moving
		accel = GROUND_FRICTION if is_on_floor() else AIR_FRICTION
	else:
		accel = GROUND_ACCEL if is_on_floor() else AIR_ACCEL
		
		# makes turns faster
		if velocity.x != 0 and sign(velocity.x) != sign(direction):
			accel *= TURN_MULTIPLIER
	velocity.x = move_toward(velocity.x, direction * speed, accel * delta)
	
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
