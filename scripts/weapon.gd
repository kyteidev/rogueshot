extends Node2D


@onready var gun_sprite = $GunSprite

func _process(_delta: float) -> void:
	look_at(get_global_mouse_position())
	
	var mouse_pos = get_global_mouse_position()
	var direction = mouse_pos - global_position
	
	if direction.x < 0:
		gun_sprite.scale.y = -1
	else:
		gun_sprite.scale.y = 1
