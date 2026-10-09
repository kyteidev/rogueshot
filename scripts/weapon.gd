extends Node2D

var weapons: Array = []
var current_weapon_index = 0
var current_weapon: Sprite2D = null


func _ready() -> void:
	weapons = get_children()
	equip_weapon(0)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("weapon_next"):
		var next_index = (current_weapon_index + 1) % weapons.size()
		equip_weapon(next_index)
	elif Input.is_action_just_pressed("weapon_previous"):
		var prev_index = (current_weapon_index - 1 + weapons.size()) % weapons.size()
		equip_weapon(prev_index)
	
	# make weapon point towards mouse pointer
	look_at(get_global_mouse_position())
	
	# flip direction if necessary
	var mouse_pos = get_global_mouse_position()
	var direction = mouse_pos - global_position
	
	var weapon_scale = current_weapon.scale.y
	if direction.x < 0:
		current_weapon.scale.y = abs(weapon_scale) * -1
	else:
		current_weapon.scale.y = abs(weapon_scale)
		

func equip_weapon(index: int):
	var prev_weapon = current_weapon
	
	current_weapon_index = index
	current_weapon = weapons[index]
	
	if prev_weapon != current_weapon and prev_weapon != null:
		prev_weapon.hide()
	current_weapon.show()
