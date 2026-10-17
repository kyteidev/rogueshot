extends CharacterBody2D


const MAX_HEALTH = 100.0
const DAMAGE_FLASH_DELAY = 0.04

const BASE_SPEED = 80.0
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

const DEATH_TRANS_DELAY = 1.0

@export var transition: CanvasLayer
@export var crosshair: CanvasLayer

var sm := StateManager

var prev_health: float = MAX_HEALTH
var health: float = MAX_HEALTH:
	set(value):
		health = clamp(value, 0.0, MAX_HEALTH)
		sm.health = health
		
		if value < prev_health:
			sm.lost_health = true
		prev_health = value

var was_airborne: bool = false
var reached_peak: bool = false

var speed: float = 0.0
var sprinting: bool = false

var is_dead: bool = false

var regenerating_stamina: bool = true
var prev_stamina: float = MAX_STAMINA
var stamina: float:
	set(value):
		stamina = clamp(value, 0.0, MAX_STAMINA)
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
var stamina_depleted: bool = false:
	set(value):
		stamina_depleted = value
		sm.stamina_depleted = value
		
@onready var coyote_timer := $CoyoteTimer
@onready var jump_buffer_timer := $JumpBufferTimer

@onready var death_timer := $DeathTimer

@onready var anim_sprite := $AnimatedSprite2D
@onready var stamina_timer := $StaminaTimer

@onready var weapon := $Weapon
@onready var collision := $CollisionShape2D


func _ready() -> void:
	# have this in _ready so max stamina only needs to be adjusted here,
	# otherwise i'd have to change max stamina here and in state manager
	stamina = MAX_STAMINA
	
	death_timer.wait_time = DEATH_TRANS_DELAY
	collision.disabled = false
	
	sm.max_health = MAX_HEALTH


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var was_on_floor: bool = is_on_floor()
	
	# gravity and jump stretch
	if not is_on_floor():
		velocity.y += _get_custom_gravity(velocity) * delta
		was_airborne = true
		
		if not reached_peak and velocity.y >= 0:
			reached_peak = true
			anim_sprite.scale = Vector2(1.0, 1.0)
		
	# player jump system
	if Input.is_action_just_pressed("player_jump"):
		jump_buffer_timer.start(JUMP_BUFFER_TIME)
		
	if Input.is_action_just_released("player_jump") and velocity.y < JUMP_VELOCITY_CUT:
		velocity.y = JUMP_VELOCITY_CUT

	var wants_jump: bool = not jump_buffer_timer.is_stopped()
	var can_jump: bool = is_on_floor() or not coyote_timer.is_stopped()

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
	var direction: float = Input.get_axis("player_left", "player_right")
		
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
		var wall_normal: float = get_wall_normal().x
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


func take_damage(damage: float) -> void:
	# flash red when taking damage
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color("ff0000"), DAMAGE_FLASH_DELAY)
	tween.tween_property(self, "modulate", Color("ffffff"), DAMAGE_FLASH_DELAY)
	
	if not is_dead:
		health -= damage
		if health <= 0:
			# make player red when dead
			is_dead = true
			anim_sprite.play("death")
			weapon.fade_weapon()
			collision.disabled = true
			
			anim_sprite.animation_finished.connect(death_timer.start)


func _get_custom_gravity(vel: Vector2) -> float:
	if vel.y < 0:
		return GRAVITY
	return FALL_GRAVITY


func _on_death_timer_timeout() -> void:
	var scene: PackedScene = preload("res://scenes/menus/death_menu.tscn")
	transition.start_transition(scene)
