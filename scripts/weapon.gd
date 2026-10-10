extends Node2D


var weapons: Array = []
var equipped_weapons = []
var weapon_index: int = 0
var current_weapon: Sprite2D = null
var weapon_name: String = ""
var weapon_muzzle: Marker2D = null

var base_damage: int = 0
var fire_rate: float = 0.0
var ammo: int = 0
var max_ammo: int = 0
var mags: int = 0

@onready var timer = $Timer

const BULLET = preload("res://scenes/bullet.tscn")
const BULLET_SCALE = 0.2

var can_fire = true

"""
format of weapon stats:
"weapon_name": {
	"damage": base weapon damage,
	"fire_rate": fire rate in seconds (0 for semi auto),
	"mag_size": ammo per mag
	"total_mags": base number of mags available
}
"""
const WEAPON_STATS = {
	"pistol": {
		"damage": 25,
		"fire_rate": 0.0,
		"mag_size": 13,
		"total_mags": 5
	},
	"rifle1": {
		"damage": 15,
		"fire_rate": 0.1,
		"mag_size": 30,
		"total_mags": 4
	}
}

var sm = StateManager
# format: [weapon_name, ammo, mags]
var weapon_state: Dictionary = {}


func sync_state() -> void:
	sm.ammo = ammo
	sm.max_ammo = max_ammo
	sm.mags = mags

func _ready() -> void:
	weapons = get_children()
	weapons.pop_front() # first element is the timer
	equip_weapon(0)


func _process(_delta: float) -> void:
	# weapon switching
	if Input.is_action_just_pressed("weapon_next"):
		var next_index = (weapon_index + 1) % weapons.size()
		equip_weapon(next_index)
	elif Input.is_action_just_pressed("weapon_previous"):
		var prev_index = (weapon_index - 1 + weapons.size()) % weapons.size()
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
	if Input.is_action_pressed("player_shoot"):
		# spawn bullet and set necessary values
		if can_fire and ammo > 0:
			var bullet_instance = BULLET.instantiate()
			get_tree().root.add_child(bullet_instance)
			
			bullet_instance.global_position = weapon_muzzle.global_position
			bullet_instance.rotation = global_rotation
			bullet_instance.scale = Vector2(BULLET_SCALE, BULLET_SCALE)
			
			ammo -= 1
			sync_state()
		
		# firing speed timeout
		if fire_rate == 0.0 and can_fire:
			can_fire = false
		elif fire_rate > 0.0:
			if can_fire:
				can_fire = false
				timer.start(fire_rate)
			elif timer.is_stopped():
				can_fire = true
	
	# reset fire lock for semi auto
	if fire_rate == 0.0 and Input.is_action_just_released("player_shoot"):
		can_fire = true
		
	if Input.is_action_just_pressed("weapon_reload") and mags > 0 and ammo != max_ammo:
		ammo = max_ammo
		mags -= 1
		sync_state()
		

func equip_weapon(index: int):
	# save weapon stats before switching
	if current_weapon != null:
		weapon_state[weapon_name] = {"ammo": ammo, "mags": mags}
	
	# get weapon stuff
	weapon_index = index
	current_weapon = weapons[index]
	weapon_name = current_weapon.name.to_lower()
	weapon_muzzle = current_weapon.get_child(0)
	
	# set weapon stats
	var current_weapon_stats = WEAPON_STATS[weapon_name]
	base_damage = current_weapon_stats.damage
	fire_rate = current_weapon_stats.fire_rate
	max_ammo = current_weapon_stats.mag_size
	
	# save weapon state if not saved previously
	if not weapon_state.has(weapon_name):
		weapon_state[weapon_name] = {
			"ammo": current_weapon_stats.mag_size,
			"mags": current_weapon_stats.total_mags
		}
	
	# restore saved state
	ammo = weapon_state[weapon_name].ammo
	mags = weapon_state[weapon_name].mags
	can_fire = true
	sync_state()
	
	# only show active weapon
	for i in range(weapons.size()):
		if i != weapon_index:
			weapons[i].hide()
		else:
			weapons[i].show()
