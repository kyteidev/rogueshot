extends Node2D


const MIN_SCALE = 0.1
const MAX_SCALE = 0.2

const OFFSET = 1.0

const FLASH_TIME = 0.05

@onready var timer := $Timer


func _ready() -> void:
	visible = false


func fire(muzzle_position: Vector2, weapon_rotation: float) -> void:
	global_position = muzzle_position
	global_rotation = weapon_rotation
	position.x += OFFSET
	
	scale = Vector2.ONE * randf_range(MIN_SCALE, MAX_SCALE)
	visible = true
	
	timer.start(FLASH_TIME)


func _on_timer_timeout() -> void:
	visible = false
