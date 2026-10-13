extends CharacterBody2D


enum State { IDLE, PATROL, CHASE, ATTACK, RETREAT, DEAD }

const MAX_HEALTH = 100.0

const BASE_SPEED = 300.0
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

var health = MAX_HEALTH

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
	
	move_and_slide()
	

func take_damage(damage) -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("ff0000"), DAMAGE_FLASH_DELAY)
	tween.tween_property(self, "modulate", Color("ffffff"), DAMAGE_FLASH_DELAY)
	
	
	health -= damage
	if health <= 0:
		state = State.DEAD


func _state_idle() -> void:
	anim.play("idle")
	

func _state_patrol() -> void:
	pass
	

func _state_chase() -> void:
	pass
	
	
func _state_attack() -> void:
	pass


func _state_retreat() -> void:
	pass
	

func _state_dead(delta) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	
	if velocity.x == 0.0:
		queue_free()
