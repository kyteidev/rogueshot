extends Node2D


var weapons: Array = []
var current_weapon_index = 0
var current_weapon: Sprite2D = null
var current_weapon_muzzle: Marker2D = null

const BULLET = preload("res://scenes/bullet.tscn")
const BULLET_SCALE = 0.2


func _ready() -> void:
	weapons = get_children()
	equip_weapon(0)


func _process(_delta: float) -> void:
	# weapon switching
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
	
	# weapon firing
	if Input.is_action_just_pressed("player_shoot"):
		var bullet_instance = BULLET.instantiate()
		get_tree().root.add_child(bullet_instance)
		
		bullet_instance.global_position = current_weapon_muzzle.global_position
		bullet_instance.rotation = global_rotation
		bullet_instance.scale = Vector2(BULLET_SCALE, BULLET_SCALE)
		

func equip_weapon(index: int):
	current_weapon_index = index
	current_weapon = weapons[index]
	current_weapon_muzzle = current_weapon.get_child(0)
	
	for i in range(weapons.size()):
		if i != current_weapon_index:
			weapons[i].hide()
		else:
			weapons[i].show()
