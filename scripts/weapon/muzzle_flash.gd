extends Node2D

const MIN_SCALE = 0.1
const MAX_SCALE = 0.2

const OFFSET = 0.5

const FLASH_TIME = 0.05

var rng := Random.rng

var tween: Tween


func _ready() -> void:
	visible = false


func fire(muzzle_position: Vector2, weapon_rotation: float, scale_multiplier := 1.0) -> void:
	global_position = muzzle_position
	global_rotation = weapon_rotation
	position.x += OFFSET

	scale = Vector2.ONE * rng.randf_range(MIN_SCALE, MAX_SCALE) * scale_multiplier
	visible = true

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_interval(FLASH_TIME)
	tween.finished.connect(hide)
