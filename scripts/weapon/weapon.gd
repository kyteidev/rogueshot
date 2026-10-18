extends Node2D


const MAX_STAMINA_SPREAD_MULTIPLIER = 2.0

const BULLET = preload("res://scenes/weapons/bullet.tscn")
const BULLET_SCALE = 0.15

const CASING = preload("res://scenes/weapons/casing.tscn")

const SMOKE_PARTICLES = preload("res://scenes/particles/muzzle_smoke.tscn")

const FADE_DURATION = 0.15
const SMOKE_FADE_SPEED = 6.0

const MAX_HEAT = 1.0
const SMOKE_BASE_ALPHA = 0.8

var sm := StateManager

var weapons: Array = []
var equipped_weapons: Array = []
var weapon_index: int = 0
var current_weapon: Sprite2D = null
var weapon_name: String = ""
var weapon_muzzle: Marker2D = null
var weapon_muzzle_orig_pos: Vector2 = Vector2(0.0, 0.0)
var weapon_ejection: Marker2D = null
var weapon_ejection_orig_pos: Vector2 = Vector2(0.0, 0.0)

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
var camera_shake: float = 0.0

var heat_per_shot: float = 0.0
var cooling_rate: float = 0.0

var speed_multiplier: float = 0.0

var smoke: CPUParticles2D
var heat: float = 0.0

var can_fire: bool = true

@onready var timer := $Timer

@onready var player := get_node("../")
@onready var crosshair: CanvasLayer = player.crosshair

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
		"reload_time": 0.9,
		"camera_shake": 1.0,
		"heat": 0.18,
		"cooling_rate": 1.04,
		"speed_multiplier": 1.0,
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
		"reload_time": 2.6,
		"camera_shake": 0.5,
		"heat": 0.22,
		"cooling_rate": 0.87,
		"speed_multiplier": 0.9
	}
}

# format: weapon_name: { ammo, mags }
var weapon_state: Dictionary = {}


func _ready() -> void:
	weapons = get_children()
	weapons.pop_front() # first element is the timer
	equip_weapon(0)
	
	# instantiate smoke particles
	smoke = SMOKE_PARTICLES.instantiate()
	add_child(smoke)


func _physics_process(delta: float) -> void:
	if player.is_dead:
		return

	# make weapon point towards mouse pointer
	look_at(get_global_mouse_position())
	
	# flip direction if necessary
	var mouse_pos: Vector2 = get_global_mouse_position()
	var direction: Vector2 = mouse_pos - global_position
	var flipped: bool = direction.x < 0
	
	current_weapon.flip_v = flipped
	weapon_muzzle.position.y = -weapon_muzzle_orig_pos.y if flipped else weapon_muzzle_orig_pos.y
	weapon_ejection.position.y = -weapon_ejection_orig_pos.y if flipped else weapon_ejection_orig_pos.y
	
	# recoil and kick recovery and apply kick
	current_spread = move_toward(current_spread, 0.0, spread_recovery * delta)
	kick_offset = move_toward(kick_offset, 0.0, kick_recovery * delta)
	current_weapon.position = weapon_rest_pos + Vector2(-kick_offset, 0)
	
	# muzzle smoke logic
	heat = max(heat - cooling_rate * delta, 0.0)
	smoke.emitting = true if heat > 0.0 else false
	
	smoke.modulate.a = lerp(smoke.modulate.a, smoothstep(0.0, SMOKE_BASE_ALPHA, heat), 1.0 - exp(-SMOKE_FADE_SPEED * delta))
	
	# weapon firing
	if Input.is_action_pressed("player_shoot"):
		if can_fire and ammo > 0:
			# spawn bullet
			var bullet_instance := BULLET.instantiate()
			bullet_instance.type = bullet_instance.Types.FRIENDLY

			# apply spread
			var spread_angle: float = deg_to_rad(randf_range(-current_spread, current_spread)) \
					* ((100 - player.stamina) / 100) * MAX_STAMINA_SPREAD_MULTIPLIER

			bullet_instance.global_position = weapon_muzzle.global_position
			bullet_instance.rotation = global_rotation + spread_angle
			bullet_instance.scale = Vector2(BULLET_SCALE, BULLET_SCALE)
			
			bullet_instance.origin_pos = weapon_muzzle.global_position
			bullet_instance.add_collision_exception_with(player)
			
			get_tree().root.add_child(bullet_instance)
			
			ammo -= 1

			# cap spread and kick
			current_spread = min(current_spread + spread_per_shot, max_spread)
			kick_offset = min(kick_offset + kick, kick * 2.0)
			
			# eject casing
			var casing_instance := CASING.instantiate()
			get_tree().root.add_child(casing_instance)
			
			casing_instance.global_position = weapon_ejection.global_position
			
			casing_instance.add_collision_exception_with(player)
			casing_instance.eject(global_rotation)
			
			# deduct stamina
			player.stamina -= player.SHOOT_STAMINA_RATE
			
			# shake camera
			var camera := get_node("../../Camera")
			camera.shake_strength = camera_shake
			
			# smoke
			heat = min(heat + heat_per_shot, MAX_HEAT)
			smoke.global_position = weapon_muzzle.global_position
		
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
	if player.is_dead:
		return

	# weapon switching
	if Input.is_action_just_pressed("weapon_cycle"):
		var next_index: int = (weapon_index + 1) % weapons.size()
		equip_weapon(next_index)
	
	# manually select primary/secondary weapon
	if Input.is_action_just_pressed("weapon_1"):
		equip_weapon(0)
	elif Input.is_action_just_pressed("weapon_2"):
		equip_weapon(1)


func fade_weapon() -> void:
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate", Color("ffffff00"), FADE_DURATION)\
			.set_ease(Tween.EASE_OUT)


func reload_weapon() -> void:
	if mags > 0 and ammo != max_ammo:
		crosshair.start_reload()
		crosshair.tween.finished.connect(_finish_reload)
		

func _finish_reload() -> void:
	ammo = max_ammo
	mags -= 1
	

func equip_weapon(index: int) -> void:
	# reset and save weapon stats before switching
	if current_weapon != null:
		current_weapon.flip_v = false
		current_weapon.position = weapon_rest_pos
		weapon_muzzle.position = weapon_muzzle_orig_pos
		weapon_ejection.position = weapon_ejection_orig_pos
		weapon_state[weapon_name] = {"ammo": ammo, "mags": mags}
	
	# get weapon stuff
	weapon_index = index
	current_weapon = weapons[index]
	weapon_name = current_weapon.name.to_lower()
	weapon_muzzle = current_weapon.get_node("./Muzzle")
	weapon_muzzle_orig_pos = weapon_muzzle.position
	weapon_ejection = current_weapon.get_node("./Ejection")
	weapon_ejection_orig_pos = weapon_ejection.position
	
	# set weapon stats
	var stats: Dictionary = WEAPON_STATS[weapon_name]
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
	camera_shake = stats.camera_shake
	
	heat_per_shot = stats.heat
	cooling_rate = stats.cooling_rate
	
	speed_multiplier = stats.speed_multiplier
	
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
