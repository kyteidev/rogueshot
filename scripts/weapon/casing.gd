extends RigidBody2D

const LIFETIME = 3.0
const FADE_DURATION = 0.5

const MIN_DIRECTION_WEIGHT = 1.4
const MAX_DIRECTION_WEIGHT = 1.8

const MIN_SPEED = 100.0
const MAX_SPEED = 150.0

const MIN_SPIN = 12.0
const MAX_SPIN = 18.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer


func _ready() -> void:
	timer.start(LIFETIME)


func eject(weapon_rotation: float) -> void:
	var weapon_facing: int = 1 if Vector2.from_angle(weapon_rotation).x >= 0.0 else -1
	var new_weapon_rotation: float = weapon_rotation \
			+ PI / 2.0 * -weapon_facing * randf_range(MIN_DIRECTION_WEIGHT, MAX_DIRECTION_WEIGHT)

	var direction := Vector2.from_angle(new_weapon_rotation)
	var speed: float = randf_range(MIN_SPEED, MAX_SPEED)
	var spin: float = randf_range(MIN_SPIN, MAX_SPIN)

	linear_velocity = direction * speed
	angular_velocity = randf_range(-spin, spin)
	global_rotation = weapon_rotation


# unload casing with fade after lifetime
func _on_timer_timeout() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color("ffffff00"), FADE_DURATION)
	tween.finished.connect(queue_free)
