extends CharacterBody2D


const BASE_SPEED = 300.0
const JUMP_VELOCITY = -200.0

const GROUND_ACCEL = 900.0
const GROUND_FRICTION = 1100.0
const AIR_ACCEL = 600.0
const AIR_FRICTION = 300.0
const TURN_MULTIPLIER = 1.5

const GRAVITY = 750
const FALL_GRAVITY = GRAVITY * 1.5


func get_custom_gravity(vel) -> float:
	if vel.y < 0:
		return GRAVITY
	return FALL_GRAVITY


func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity.y += get_custom_gravity(velocity) * delta

	move_and_slide()
