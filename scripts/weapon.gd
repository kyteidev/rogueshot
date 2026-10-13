extends Node2D


const MAX_STAMINA_SPREAD_MULTIPLIER = 2.0

const BULLET = preload("res://scenes/weapons/bullet.tscn")
const BULLET_SCALE = 0.2

var sm = StateManager

var weapons: Array = []
var equipped_weapons: Array = []
var weapon_index: int = 0
var current_weapon: Sprite2D = null
var weapon_name: String = ""
var weapon_muzzle: Marker2D = null

var base_damage: int = 0:
	set(value):
		base_damage = value
		sm.damage = value
var fire_rate: float = 0.0

var ammo: int = 0:
	set(value):
		ammo = value
		sm.ammo = value
var max_ammo: int = 0:
	set(value):
		max_ammo = value
		sm.max_ammo = value
var mags: int = 0:
	set(value):
		mags = value
		sm.mags = value

var kick: float = 0.0
var kick_recovery: float = 0.0
var spread_per_shot: float = 0.0
var max_spread: float = 0.0
var spread_recovery: float = 0.0

var reload_time: float = 0.0

var current_spread: float = 0.0
var kick_offset: float = 0.0
var weapon_rest_pos: Vector2 = Vector2.ZERO

var can_fire = true

@onready var timer = $Timer

@onready var player = get_node("../")
@onready var crosshair = player.crosshair

# weapon stats and state, have them here and dont move these up!!!
const WEAPON_STATS = {
	"pistol": {
		"damage": 25,
		"fire_rate": 0.0,
		"mag_size": 13,
		"total_mags": 5,
		"kick": 5.0,
		"kick_recovery": 60.0,
		"spread": 3.0,
		"max_spread": 8.0,
		"spread_recovery": 8.0,
		"reload_time": 0.9
	},
	"rifle1": {
		"damage": 15,
		"fire_rate": 0.1,
		"mag_size": 30,
		"total_mags": 4,
		"kick": 3.0,
		"kick_recovery": 40.0,
		"spread": 1.2,
		"max_spread": 7.0,
		"spread_recovery": 5.0,
		"reload_time": 2.6
	}
}

# format: weapon_name: { ammo, mags }
var weapon_state: Dictionary = {}


func _ready() -> void:
	weapons = get_children()
	weapons.pop_front() # first element is the timer
	equip_weapon(0)


func _process(delta: float) -> void:
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
		
	# recoil recovery
	current_spread = move_toward(current_spread, 0.0, spread_recovery * delta)
	kick_offset = move_toward(kick_offset, 0.0, kick_recovery * delta)
	current_weapon.position = weapon_rest_pos + Vector2(-kick_offset, 0)
	
	# weapon firing
	if Input.is_action_pressed("player_shoot"):
		if can_fire and ammo > 0:
			# spawn bullet
			var bullet_instance = BULLET.instantiate()
			get_tree().root.add_child(bullet_instance)

			# apply spread
			var spread_angle = deg_to_rad(randf_range(-current_spread, current_spread)) \
									* ((100 - player.stamina) / 100) * MAX_STAMINA_SPREAD_MULTIPLIER

			bullet_instance.global_position = weapon_muzzle.global_position
			bullet_instance.rotation = global_rotation + spread_angle
			bullet_instance.scale = Vector2(BULLET_SCALE, BULLET_SCALE)
			
			# subtract ammo and sync state with state manager
			ammo -= 1

			# apply recoil
			current_spread = min(current_spread + spread_per_shot, max_spread)
			kick_offset = min(kick_offset + kick, kick * 2.0)
			
			# deduct stamina
			player.stamina -= player.SHOOT_STAMINA_RATE
		
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
		
	if Input.is_action_just_pressed("weapon_reload"):
		reload_weapon()
		

func _input(_event: InputEvent) -> void:
	# weapon switching
	if Input.is_action_just_pressed("weapon_cycle"):
		var next_index = (weapon_index + 1) % weapons.size()
		equip_weapon(next_index)
	
	# manually select primary/secondary weapon
	if Input.is_action_just_pressed("weapon_1"):
		equip_weapon(0)
	elif Input.is_action_just_pressed("weapon_2"):
		equip_weapon(1)
		

func reload_weapon() -> void:
	if mags > 0 and ammo != max_ammo:
		crosshair.start_reload()
		crosshair.tween.finished.connect(_finish_reload)
		

func _finish_reload() -> void:
	ammo = max_ammo
	mags -= 1
	

func equip_weapon(index: int) -> void:
	# save weapon stats before switching
	if current_weapon != null:
		current_weapon.position = weapon_rest_pos
		weapon_state[weapon_name] = {"ammo": ammo, "mags": mags}
	
	# get weapon stuff
	weapon_index = index
	current_weapon = weapons[index]
	weapon_name = current_weapon.name.to_lower()
	weapon_muzzle = current_weapon.get_child(0)
	
	# set weapon stats
	var stats = WEAPON_STATS[weapon_name]
	base_damage = stats.damage
	fire_rate = stats.fire_rate
	max_ammo = stats.mag_size
	
	kick = stats.kick
	kick_recovery = stats.kick_recovery
	spread_per_shot = stats.spread
	max_spread = stats.max_spread
	spread_recovery = stats.spread_recovery
	
	reload_time = stats.reload_time
	crosshair.reload_time = reload_time

	current_spread = 0.0
	kick_offset = 0.0
	weapon_rest_pos = current_weapon.position
	
	# save weapon state if not saved previously
	if not weapon_state.has(weapon_name):
		weapon_state[weapon_name] = {
			"ammo": stats.mag_size,
			"mags": stats.total_mags
		}
	
	# restore saved state
	ammo = weapon_state[weapon_name].ammo
	mags = weapon_state[weapon_name].mags
	can_fire = true
	
	# only show active weapon
	for i in range(weapons.size()):
		weapons[i].visible = true if i == weapon_index else false
			
	crosshair.cancel_reload()
