extends CharacterBody2D


enum State { IDLE, PATROL, CHASE, ATTACK, RETREAT, DEAD }

const MAX_HEALTH = 100.0

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

var state = State.PATROL
var target: CharacterBody2D = null
var died = false

var health = MAX_HEALTH
var direction = 1
var speed = 0.0

@onready var anim = $AnimatedSprite2D
@onready var wall_ray = $WallRay
@onready var ledge_ray = $LedgeRay


func get_custom_gravity(vel) -> float:
	if vel.y < 0:
		return GRAVITY
	return FALL_GRAVITY


func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity.y += get_custom_gravity(velocity) * delta
		
	match state:
		State.IDLE: _state_idle()
		State.PATROL: _state_patrol()
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
	# flash red when taking damage
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("ff0000"), DAMAGE_FLASH_DELAY)
	tween.tween_property(self, "modulate", Color("ffffff"), DAMAGE_FLASH_DELAY)
	
	
	health -= damage
	if health <= 0:
		state = State.DEAD


func _state_idle() -> void:
	anim.play("idle")
	

func _state_patrol() -> void:
	anim.play("run")
	anim.speed_scale = 0.9
	
	if is_on_floor() and (wall_ray.is_colliding() or not ledge_ray.is_colliding()):
		direction *= -1
		anim.flip_h = not anim.flip_h
		wall_ray.target_position *= -1
		ledge_ray.position.x *= -1
	speed = PATROL_SPEED


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
