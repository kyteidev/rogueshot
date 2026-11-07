extends Node2D

const MAX_STAMINA_SPREAD_MULTIPLIER = 2.0
const NO_AIM_SPREAD_MULTIPLIER = 2.0

const BULLET = preload("res://scenes/weapons/bullet.tscn")
const BULLET_SCALE = 0.15

const CASING = preload("res://scenes/weapons/casing.tscn")

const MUZZLE_FLASH = preload("res://scenes/weapons/muzzle_flash.tscn")
const SMOKE_PARTICLES = preload("res://scenes/particles/muzzle_smoke.tscn")
const SPARK_PARTICLES = preload("res://scenes/particles/muzzle_sparks.tscn")

const FADE_DURATION = 0.15
const SMOKE_FADE_SPEED = 6.0

const MAX_HEAT = 1.0
const SMOKE_BASE_ALPHA = 0.8

var sm := StateManager
var im := ItemManager

var weapon_index: int = -1
var current_weapon: Sprite2D = null
var weapon_name := ""
var weapon_muzzle: Marker2D = null
var weapon_muzzle_orig_pos := Vector2(0.0, 0.0)
var weapon_ejection: Marker2D = null
var weapon_ejection_orig_pos := Vector2(0.0, 0.0)

var base_damage: int = 0:
	set(value):
		base_damage = value
		sm.damage = value
var fire_rate: float = 0.0

var ammo: int = 0:
	set(value):
		ammo = value
		sm.ammo = value

		var weapon: ItemData = im.equipped_weapons[weapon_index]
		if (
			weapon_index != -1 and weapon.container_items.size() > 0
			and weapon.container_items[0].container_items.size() > 0
		):
			# weapon -> mag -> ammo
			weapon.container_items[0].container_items[0].count = value
var max_ammo: int = 0:
	set(value):
		max_ammo = value
		sm.max_ammo = value
var mags: int = 0:
	set(value):
		mags = value
		sm.mags = value

var kick := 0.0
var kick_recovery := 0.0
var spread_per_shot := 0.0
var max_spread := 0.0
var spread_recovery := 0.0

var reload_time := 0.0

var current_spread := 0.0
var kick_offset := 0.0
var weapon_rest_pos := Vector2.ZERO
var camera_shake := 0.0

var heat_per_shot := 0.0
var cooling_rate := 0.0

var speed_multiplier := 1.0

var spread_multiplier := 1.0

var muzzle_flash: Node2D
var smoke: CPUParticles2D
var heat := 0.0

var can_fire := true

@onready var timer: Timer = $Timer
@onready var weapon_node: Node2D = $Weapon

@onready var player: CharacterBody2D = get_parent()
@onready var crosshair: CanvasLayer = player.crosshair

# format: weapon_name: { ammo, mags }
var weapon_state: Dictionary = { }


func _ready() -> void:
	# instantiate muzzle flash and smoke particles
	muzzle_flash = MUZZLE_FLASH.instantiate()
	add_child(muzzle_flash)

	smoke = SMOKE_PARTICLES.instantiate()
	add_child(smoke)

	# weapon unequipping
	im.weapon_unequipped.connect(
		func() -> void:
			_equip_weapon(-1),
	)


func _physics_process(delta: float) -> void:
	if (
		player.is_dead or (not im.equipped_weapons[0] and not im.equipped_weapons[1])
		or weapon_index == -1
	):
		return

	var input_locked: bool = sm.is_input_locked()

	# reset spread multiplier, otherwise it will scale infinitely
	spread_multiplier = 1.0

	# make weapon point towards mouse pointer
	if not input_locked:
		look_at(get_global_mouse_position())

	# flip direction if necessary
	var mouse_pos: Vector2 = get_global_mouse_position()
	var direction: Vector2 = mouse_pos - global_position
	var flipped: bool = direction.x < 0

	if not input_locked:
		current_weapon.flip_v = flipped
		weapon_muzzle.position.y = -weapon_muzzle_orig_pos.y if flipped \
				else weapon_muzzle_orig_pos.y
		weapon_ejection.position.y = -weapon_ejection_orig_pos.y if flipped \
				else weapon_ejection_orig_pos.y

	# recoil and kick recovery and apply kick
	current_spread = move_toward(current_spread, 0.0, spread_recovery * delta)
	kick_offset = move_toward(kick_offset, 0.0, kick_recovery * delta)
	current_weapon.position = weapon_rest_pos + Vector2(-kick_offset, 0)

	# muzzle smoke logic
	heat = max(heat - cooling_rate * delta, 0.0)
	smoke.emitting = true if heat > 0.0 else false

	smoke.modulate.a = lerp(
		smoke.modulate.a,
		smoothstep(0.0, SMOKE_BASE_ALPHA, heat),
		1.0 - exp(-SMOKE_FADE_SPEED * delta),
	)

	# weapon firing
	if not input_locked and Input.is_action_pressed("player_shoot"):
		_fire_weapon()

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

	if not input_locked and Input.is_action_just_pressed("weapon_reload"):
		reload_weapon()


func _input(_event: InputEvent) -> void:
	if player.is_dead:
		return

	# weapon switching
	if Input.is_action_just_pressed("weapon_cycle"):
		var next_index: int
		var equipped := false
		for i in range(1, im.equipped_weapons.size() + 1):
			next_index = (weapon_index + i) % 2

			if im.equipped_weapons.get(next_index) != null:
				if next_index == weapon_index:
					continue

				equipped = true
				_equip_weapon(next_index)
				break

		if not equipped:
			_equip_weapon(-1)

	# manually select primary/secondary weapon
	if Input.is_action_just_pressed("weapon_primary"):
		if im.equipped_weapons[0] and weapon_index != 0:
			_equip_weapon(0)
		else:
			_equip_weapon(-1)
	elif Input.is_action_just_pressed("weapon_secondary"):
		if im.equipped_weapons[1] and weapon_index != 1:
			_equip_weapon(1)
		else:
			_equip_weapon(-1)


func fade_weapon() -> void:
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate", Color("ffffff00"), FADE_DURATION) \
			.set_ease(Tween.EASE_OUT)


func reload_weapon() -> void:
	if mags > 0 and ammo != max_ammo:
		crosshair.start_reload()
		crosshair.tween.finished.connect(_finish_reload)


func _finish_reload() -> void:
	ammo = max_ammo
	mags -= 1


func _fire_weapon() -> void:
	if can_fire and ammo > 0:
		# spawn bullet
		var bullet_instance: CharacterBody2D = BULLET.instantiate()
		bullet_instance.type = bullet_instance.Types.FRIENDLY

		# apply spread
		spread_multiplier *= ((100 - player.stamina) / 100) * MAX_STAMINA_SPREAD_MULTIPLIER
		var spread_angle: float = deg_to_rad(randf_range(-current_spread, current_spread)) \
				* spread_multiplier

		bullet_instance.global_position = weapon_muzzle.global_position
		bullet_instance.rotation = global_rotation + spread_angle
		bullet_instance.scale = Vector2(BULLET_SCALE, BULLET_SCALE)

		bullet_instance.origin_pos = weapon_muzzle.global_position
		bullet_instance.add_collision_exception_with(player)

		get_tree().root.add_child(bullet_instance)

		# muzzle flash
		muzzle_flash.fire(weapon_muzzle.global_position, global_rotation)

		# muzzle sparks
		var spark_instance: CPUParticles2D = SPARK_PARTICLES.instantiate()
		spark_instance.position = muzzle_flash.position
		add_child(spark_instance)

		# smoke
		heat = min(heat + heat_per_shot, MAX_HEAT)
		smoke.global_position = weapon_muzzle.global_position

		# deduct ammo
		ammo -= 1

		# cap spread and kick
		current_spread = min(current_spread + spread_per_shot, max_spread)
		kick_offset = min(kick_offset + kick, kick * 2.0)

		# eject casing
		var casing_instance: RigidBody2D = CASING.instantiate()
		get_tree().root.add_child(casing_instance)

		casing_instance.global_position = weapon_ejection.global_position

		casing_instance.add_collision_exception_with(player)
		casing_instance.eject(global_rotation)

		# deduct stamina
		player.stamina -= player.SHOOT_STAMINA_RATE

		# shake camera
		var camera: Camera2D = get_node("../../Camera")
		camera.shake_strength = camera_shake


func _equip_weapon(index: int) -> void:
	# reset and save weapon stats before switching
	if current_weapon != null:
		current_weapon.flip_v = false
		current_weapon.position = weapon_rest_pos
		weapon_muzzle.position = weapon_muzzle_orig_pos
		weapon_ejection.position = weapon_ejection_orig_pos
		weapon_state[weapon_name] = { "ammo": ammo, "mags": mags }

		heat = 0.0

	# get weapon stuff
	weapon_index = index
	for child in weapon_node.get_children():
		child.queue_free()

	crosshair.cancel_reload()
	speed_multiplier = 1.0

	if weapon_index == -1:
		return

	var weapon_scene: PackedScene = im.equipped_weapons[index].type_data.weapon_scene
	current_weapon = weapon_scene.instantiate()
	weapon_node.add_child(current_weapon)

	weapon_name = current_weapon.name.to_lower()
	weapon_muzzle = current_weapon.get_node("./Muzzle")
	weapon_muzzle_orig_pos = weapon_muzzle.position
	weapon_ejection = current_weapon.get_node("./Ejection")
	weapon_ejection_orig_pos = weapon_ejection.position

	# set weapon stats
	var stats: WeaponData = im.equipped_weapons[index].type_data
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
	var mag_count: int = 0
	for item in im.inventory_items:
		print(stats.weapon, item.type_data.compatible)
		if stats.weapon == item.type_data.compatible:
			mag_count += 1
	if not weapon_state.has(weapon_name):
		weapon_state[weapon_name] = { "ammo": stats.total_ammo, "mags": mag_count }

	# restore saved state
	ammo = weapon_state[weapon_name].ammo
	mags = weapon_state[weapon_name].mags
	can_fire = true
