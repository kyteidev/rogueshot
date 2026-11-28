extends Node2D

const MAX_STAMINA_SPREAD_MULTIPLIER = 2.0
const NO_AIM_SPREAD_MULTIPLIER = 2.0
const MAX_DURA_SPREAD_MULTIPLIER = 2.0
const WALK_SPREAD_MULTIPLIER = 3.0

const JAM_START = 50.0 # durability percent when jamming can start to happen
const MAX_JAM_CHANCE = 0.80

const MAX_HEAT_DURA_MULT = 2.0 # max multiplier for decreasing durability when at max heat
const MAX_HEAT_LIGHT_ENERGY = 10.0

const BULLET = preload("res://scenes/weapons/bullet.tscn")
const BULLET_SCALE = 0.15

const CASING = preload("res://scenes/weapons/casing.tscn")

const MUZZLE_FLASH = preload("res://scenes/weapons/muzzle_flash.tscn")
const SMOKE_PARTICLES = preload("res://scenes/particles/muzzle_smoke.tscn")
const SPARK_PARTICLES = preload("res://scenes/particles/muzzle_sparks.tscn")

const FADE_DURATION = 0.15
const SMOKE_FADE_SPEED = 6.0

const HEAT_THRESHOLD = 3.0
const HEAT_JAM_THRESHOLD = 1.0 # minimum heat for it to influence jamming
const SMOKE_BASE_ALPHA = 0.8

const MAG_FADE_DURATION = 0.3
const MAG_MOVE_AMOUNT = 3.0

var sm := StateManager
var im := ItemManager
var om := OptionsManager
var rng := Random.rng

var weapon_index: int = -1:
	set(value):
		weapon_index = value
		im.weapon_index = value
var current_weapon: Sprite2D = null
var weapon_name := ""
var weapon_muzzle: Marker2D = null
var weapon_muzzle_orig_pos := Vector2(0.0, 0.0)
var weapon_ejection: Marker2D = null
var weapon_ejection_orig_pos := Vector2(0.0, 0.0)
var weapon_heat_light: PointLight2D = null

var weapon_mag: Sprite2D
var mag_orig_pos := Vector2(0.0, 0.0)

var smoke_amount: int

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
			if value == 0:
				weapon.container_items[0].container_items.clear()
var max_ammo: int = 0:
	set(value):
		max_ammo = value
		sm.max_ammo = value
var mags: int = 0:
	set(value):
		mags = value
		sm.mags = value

var effective_range: float:
	set(value):
		effective_range = value
		sm.effective_range = value
var max_range: float:
	set(value):
		max_range = value
		sm.max_range = value

var kick := 0.0
var kick_recovery := 0.0

var hipfire_spread := 0.0
var ads_spread := 0.0
var max_hipfire_spread := 0.0
var max_ads_spread := 0.0
var spread_recovery := 0.0
var spread_multiplier := 1.0
var first_shot_spread_mult := 1.0

var h_recoil: float
var v_recoil: float

var reload_time := 0.0
var ads_time := 0.0

var current_spread := 0.0
var kick_offset := 0.0
var weapon_rest_pos := Vector2.ZERO
var camera_shake := 0.0

var heat_per_shot := 0.0
var cooling_rate := 0.0

var speed_multiplier := 1.0
var ads_speed_multiplier := 1.0

var muzzle_flash: Node2D
var smoke: CPUParticles2D
var heat := 0.0

var can_fire := true
var reloading := false
var ads := false:
	set(value):
		ads = value
		sm.ads = value
var ads_progress := 0.0

var mag_anim_tween: Tween

var flipped: bool
var can_play_empty_sfx := true

var mag_anim_reload_key := true
var unjamming := false

# attachment equipped status
# muzzle
var suppressor_attached := false

# some attachment stats stuff
var sound_multiplier := 1.0
var muzzle_flash_multiplier := 1.0
var smoke_multiplier := 1.0
var attachment_spread_multiplier := 1.0

# format: weapon_name: { ammo, mags }
var weapon_state: Dictionary = { }

@onready var shoot_timer: Timer = %ShootTimer
@onready var mag_anim_timer: Timer = %MagAnimTimer

@onready var weapon_node: Node2D = $Weapon

@onready var player: CharacterBody2D = get_parent()
@onready var status_label: Label = player.get_node("./StatusLabel")
@onready var hud: CanvasLayer = player.get_node("../HUD")
@onready var reticle: Node2D = player.reticle


func _ready() -> void:
	# instantiate muzzle flash and smoke particles
	muzzle_flash = MUZZLE_FLASH.instantiate()
	add_child(muzzle_flash)

	if om.get_option("particles"):
		smoke = SMOKE_PARTICLES.instantiate()
		add_child(smoke)

		smoke_amount = smoke.amount

	# weapon unequipping
	im.weapon_unequipped.connect(
		func() -> void:
			_equip_weapon(-1),
	)

	# update data if e.g. mag is loaded or unloaded
	im.item_loaded.connect(_set_ammo_mag_data.call_deferred)
	im.item_unloaded.connect(_set_ammo_mag_data.call_deferred.unbind(1))

	im.item_picked_up.connect(_set_ammo_mag_data.call_deferred)
	im.item_dropped.connect(_set_ammo_mag_data.call_deferred)

	# gets called immediately when mag is dragged to weapon
	im.mag_loaded.connect(
		func() -> void:
			_schedule_load_mag_anim(reload_time / 2 - MAG_FADE_DURATION, false),
	)

	# attachment loading and unloading
	im.attachment_loaded.connect(_set_attachment_stats)


func _physics_process(delta: float) -> void:
	if (
		player.is_dead or (not im.equipped_weapons[0] and not im.equipped_weapons[1])
		or weapon_index == -1
	):
		return

	var input_locked: bool = sm.is_input_locked()

	# make weapon point towards crosshiar
	if not input_locked:
		look_at(reticle.global_position)

	# flip direction if necessary
	var mouse_pos: Vector2 = get_global_mouse_position()
	var direction: Vector2 = mouse_pos - global_position

	if not input_locked:
		flipped = direction.x < 0

	if not input_locked:
		current_weapon.flip_v = flipped
		weapon_muzzle.position.y = -weapon_muzzle_orig_pos.y if flipped \
				else weapon_muzzle_orig_pos.y
		weapon_ejection.position.y = -weapon_ejection_orig_pos.y if flipped \
				else weapon_ejection_orig_pos.y
		weapon_mag.position.y = -mag_orig_pos.y if flipped else mag_orig_pos.y
		weapon_mag.flip_v = flipped

	var walk_spread_mult := 1.0
	if abs(player.velocity.length()) > 0.0:
		walk_spread_mult = WALK_SPREAD_MULTIPLIER

	# recoil and kick recovery and apply kick
	var target_ads_progress := 1.0 if ads else 0.0
	ads_progress = move_toward(ads_progress, target_ads_progress, delta / ads_time)

	var spread_per_shot: float = lerp(hipfire_spread, ads_spread, ads_progress)
	current_spread = move_toward(
		current_spread,
		spread_per_shot * first_shot_spread_mult * walk_spread_mult,
		spread_recovery * delta,
	)
	kick_offset = move_toward(kick_offset, 0.0, kick_recovery * delta)
	current_weapon.position = weapon_rest_pos + Vector2(-kick_offset, 0)

	# muzzle smoke logic
	heat = max(heat - cooling_rate * delta, 0.0)
	if om.get_option("particles"):
		smoke.emitting = true if heat > 0.0 else false
		smoke.amount = round(smoke_amount * smoke_multiplier)

		smoke.modulate.a = lerp(
			smoke.modulate.a,
			smoothstep(0.0, SMOKE_BASE_ALPHA, heat),
			1.0 - exp(-SMOKE_FADE_SPEED * delta),
		)

	# ADS
	if not input_locked:
		ads = Input.is_action_pressed("player_aim")

	# weapon firing
	if not input_locked and Input.is_action_pressed("player_shoot"):
		_fire_weapon()

		# firing speed timeout
		if fire_rate == 0.0 and can_fire:
			can_fire = false
		elif fire_rate > 0.0:
			if can_fire:
				can_fire = false
				shoot_timer.start(fire_rate)
			elif shoot_timer.is_stopped():
				can_fire = true

	# reset fire lock for semi auto
	if Input.is_action_just_released("player_shoot"):
		can_play_empty_sfx = true
		if fire_rate == 0.0:
			can_fire = true

	if not input_locked and Input.is_action_just_pressed("weapon_reload"):
		reload_weapon()

	# barrel turning red from heat idk
	if weapon_heat_light:
		var heat_weight: float = clamp(heat / HEAT_THRESHOLD, 0.0, 1.0) ** 2
		weapon_heat_light.energy = lerp(0.0, MAX_HEAT_LIGHT_ENERGY, heat_weight)


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
	# this cant run if weapon_index == -1
	var weapon: ItemData = im.equipped_weapons[weapon_index]
	if weapon.type_data.jammed:
		_start_unjam(weapon)
		return

	if unjamming:
		return

	if reloading:
		# fast reload
		var anim_elapsed: float = reticle.tween.get_total_elapsed_time()
		if (weapon.container_items.size() == 0 or anim_elapsed >= reload_time / 2):
			return

		var anim_remaining: float = (reload_time - anim_elapsed) / 2.0
		reticle.tween.set_speed_scale(2.0)

		var mag: ItemData = weapon.container_items[0]
		mag.durability -= mag.durability_rate * 2 # adds 2x on top of the 1x rate
		im.drop_item(mag)
		weapon.container_items.clear()
		weapon.type_data.mag_attached = false

		_schedule_load_mag_anim(anim_remaining - MAG_FADE_DURATION, true)
	elif mags > 0:
		# standard reload
		reloading = true

		status_label.show_status_label("RELOADING")

		var real_reload_time: float = reload_time
		if not weapon.type_data.mag_attached:
			real_reload_time /= 2

		reticle.reload_time = real_reload_time
		reticle.start_reload()
		reticle.tween.finished.connect(_finish_reload, CONNECT_ONE_SHOT)

		if weapon.type_data.mag_attached:
			unload_mag_anim()
		_schedule_load_mag_anim(real_reload_time - MAG_FADE_DURATION, true)

		# durability applies to mag already attached
		if weapon.type_data.mag_attached:
			var mag: ItemData = weapon.container_items[0]
			mag.durability -= mag.durability_rate


func load_mag_anim(reload_key := true) -> void:
	if not reloading and reload_key or weapon_index == -1:
		return

	# play gunshot sfx and apply suppressor sound if necessary
	var weapon: ItemData = im.equipped_weapons[weapon_index]
	AudioManager.play("weapon_" + weapon.id + "_load", global_position, -9.0)

	var sprite: Sprite2D = weapon_node.get_child(0)
	var mag: Sprite2D = sprite.get_node("./Magazine")
	mag.visible = true

	var orig_pos: float = -mag_orig_pos.y - MAG_MOVE_AMOUNT if flipped else mag_orig_pos.y + MAG_MOVE_AMOUNT
	var target_pos: float = -mag_orig_pos.y if flipped else mag_orig_pos.y
	mag.position.y = orig_pos
	mag.modulate.a = 0.0

	if mag_anim_tween:
		mag_anim_tween.kill()
	mag_anim_tween = create_tween()
	mag_anim_tween.set_parallel(true)

	mag_anim_tween.tween_property(mag, "position:y", target_pos, MAG_FADE_DURATION) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	mag_anim_tween.tween_property(mag, "modulate:a", 1.0, MAG_FADE_DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func unload_mag_anim(reload_key := true) -> void:
	if not reloading and reload_key or weapon_index == -1:
		return

	var weapon: ItemData = im.equipped_weapons[weapon_index]
	AudioManager.play("weapon_" + weapon.id + "_unload", global_position, -9.0)

	var sprite: Sprite2D = weapon_node.get_child(0)
	var mag: Sprite2D = sprite.get_node("./Magazine")
	sprite.texture = sprite.base_texture
	mag.visible = true

	if not weapon.type_data.mag_attached:
		mag.modulate.a = 0.0

	if mag_anim_tween:
		mag_anim_tween.kill()
	mag_anim_tween = create_tween()
	mag_anim_tween.set_parallel(true)

	var target_pos: float = -mag_orig_pos.y - MAG_MOVE_AMOUNT if flipped else mag_orig_pos.y + MAG_MOVE_AMOUNT

	mag_anim_tween \
			.tween_property(mag, "position:y", target_pos, MAG_FADE_DURATION) \
			.set_trans(Tween.TRANS_QUAD) \
			.set_ease(Tween.EASE_IN)
	mag_anim_tween.tween_property(mag, "modulate:a", 0.0, MAG_FADE_DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func get_spread_multiplier() -> float:
	if im.weapon_index == -1 or player.is_dead:
		return 1.0

	var weapon_data: ItemData = im.equipped_weapons[im.weapon_index]
	var stamina_weight: float = clamp(((100 - player.stamina) / 100), 0.0, 1.0)
	var durability_weight: float = clamp(((50.0 - weapon_data.durability) / 50.0), 0.0, 1.0)

	var mult := 1.0
	mult *= lerp(1.0, MAX_STAMINA_SPREAD_MULTIPLIER, stamina_weight)
	mult *= lerp(1.0, MAX_DURA_SPREAD_MULTIPLIER, durability_weight)
	return mult


func _finish_reload() -> void:
	status_label.hide_status_label()
	reloading = false

	var weapon: ItemData = im.equipped_weapons[weapon_index]
	var fullest_mag: ItemData = _find_fullest_mag(weapon)
	if not fullest_mag:
		_restore_mag_sprite(weapon.container_items.size() > 0)
		_set_ammo_mag_data()
		return

	weapon.type_data.mag_attached = true

	# applies to new magazine
	fullest_mag.durability -= fullest_mag.durability_rate

	if weapon.container_items.size() > 0:
		# if a magazine is loaded already
		var mag_items: Array[ItemData] = weapon.container_items[0].container_items
		var fullest_mag_items: Array[ItemData] = fullest_mag.container_items
		if mag_items.size() > 0:
			var current_ammo: int = mag_items[0].count
			var most_ammo: int = fullest_mag_items[0].count

			mag_items[0].count = most_ammo
			fullest_mag_items[0].count = current_ammo
		else:
			weapon.container_items[0].container_items = fullest_mag_items.duplicate(true)
			fullest_mag.container_items.clear()
	else:
		# load new magazine
		var new_mag: ItemData = fullest_mag.duplicate(true)
		weapon.container_items.append(new_mag)
		im.remove_item(fullest_mag)
		im.item_loaded.emit()

	_set_ammo_mag_data()
	_restore_mag_sprite(true)


func _fire_weapon() -> void:
	if not can_fire:
		return

	if reloading or unjamming:
		return

	var weapon_data: ItemData = im.equipped_weapons[weapon_index]

	if ammo > 0:
		if weapon_data.durability == 0.0:
			status_label.show_status_label("BROKEN")
			return

		if (
			weapon_data.container_items.size() > 0
			and weapon_data.container_items[0].durability == 0.0
		):
			status_label.show_status_label("MAGAZINE BROKEN")
			return

		if weapon_data.type_data.jammed:
			status_label.show_status_label("JAMMED")
			hud.update_hint_label(true, "weapon_reload", "unjam weapon")
			return

		# spawn bullet
		var bullet_instance: CharacterBody2D = BULLET.instantiate()
		bullet_instance.type = bullet_instance.Types.FRIENDLY

		# apply spread
		var spread_angle: float = deg_to_rad(rng.randf_range(-current_spread, current_spread)) \
				* get_spread_multiplier()

		bullet_instance.global_position = weapon_muzzle.global_position
		bullet_instance.rotation = global_rotation + spread_angle
		bullet_instance.scale = Vector2(BULLET_SCALE, BULLET_SCALE)

		bullet_instance.origin_pos = weapon_muzzle.global_position
		bullet_instance.add_collision_exception_with(player)

		bullet_instance.effective_range = effective_range
		bullet_instance.max_range = max_range

		bullet_instance.caliber = weapon_data.type_data.caliber

		get_tree().root.add_child(bullet_instance)

		# muzzle flash
		muzzle_flash.fire(weapon_muzzle.global_position, global_rotation, muzzle_flash_multiplier)

		# muzzle sparks
		if om.get_option("particles"):
			var spark_instance: CPUParticles2D = SPARK_PARTICLES.instantiate()
			spark_instance.position = muzzle_flash.position
			add_child(spark_instance)

		# smoke
		heat += heat_per_shot
		if om.get_option("particles"):
			smoke.global_position = weapon_muzzle.global_position

		# deduct ammo
		ammo -= 1

		# cap spread and kick
		var spread_per_shot: float = ads_spread if ads else hipfire_spread
		var max_spread: float = max_ads_spread if ads else max_hipfire_spread
		current_spread = min(current_spread + spread_per_shot, max_spread)
		kick_offset = min(kick_offset + kick, kick * 2.0)

		# apply recoil
		reticle.apply_recoil(current_weapon.global_rotation, h_recoil, v_recoil)

		# eject casing
		var casing_instance: RigidBody2D = CASING.instantiate()
		casing_instance.caliber = weapon_data.type_data.caliber
		get_tree().root.add_child(casing_instance)

		casing_instance.global_position = weapon_ejection.global_position

		casing_instance.add_collision_exception_with(player)
		casing_instance.eject(global_rotation)

		# deduct stamina
		player.stamina -= player.SHOOT_STAMINA_RATE

		# shake camera
		var camera: Camera2D = get_node("../../Camera")
		camera.shake_strength = camera_shake

		# weapon jamming
		var heat_weight: float = clamp(heat / HEAT_THRESHOLD, 0.0, 1.0) ** 2

		var mag_data: ItemData = weapon_data.container_items[0]
		var total_durability: float = weapon_data.durability + mag_data.durability
		var dura_weight := 0.0
		if total_durability <= JAM_START * 2:
			dura_weight = 1.0 - total_durability / (JAM_START * 2)
			dura_weight = clamp(dura_weight, 0.0, 1.0)
			dura_weight **= weapon_data.type_data.weapon_stats.jam_weight

		var total_weight: float = 0.0
		total_weight += dura_weight
		if heat >= HEAT_JAM_THRESHOLD:
			total_weight += heat_weight / 2
		total_weight = clamp(total_weight, 0.0, 1.0)

		if total_weight > 0.0:
			var roll: float = rng.randf()
			if roll <= lerp(
				weapon_data.type_data.weapon_stats.jam_chance,
				MAX_JAM_CHANCE,
				total_weight,
			):
				weapon_data.type_data.jammed = true

		# deplete durability
		var depletion_mult: float = lerp(1.0, MAX_HEAT_DURA_MULT, heat_weight)
		weapon_data.durability -= weapon_data.durability_rate * depletion_mult

		# play sfx
		var gunshot_sfx: String = "weapon_" + weapon_data.id + "_fire"
		if suppressor_attached:
			AudioManager.play(
				gunshot_sfx,
				weapon_muzzle.global_position,
				4.0,
				0.1,
				&"SuppressedWeapon",
				true,
				0.06,
				1.8,
			)

			# layer empty fire sfx
			AudioManager.play("weapon_fire_empty", global_position, 2.0)
		else:
			AudioManager.play(gunshot_sfx, weapon_muzzle.global_position, 0.0, 0.1, &"Weapon")
	elif ammo == 0 and can_play_empty_sfx:
		can_play_empty_sfx = false
		AudioManager.play("weapon_fire_empty", global_position)


func _equip_weapon(index: int) -> void:
	_cancel_load_mag_anim()
	unjamming = false
	if mag_anim_tween:
		mag_anim_tween.kill()

	# reset and save weapon stats before switching
	var old_mag: Sprite2D

	if weapon_index != -1:
		old_mag = current_weapon.get_node("Magazine")

	if current_weapon != null:
		current_weapon.flip_v = false
		current_weapon.position = weapon_rest_pos
		weapon_muzzle.position = weapon_muzzle_orig_pos
		weapon_ejection.position = weapon_ejection_orig_pos
		weapon_state[weapon_name] = { "ammo": ammo, "mags": mags }

		if weapon_index != -1:
			old_mag.position = mag_orig_pos
			old_mag.visible = false

		heat = 0.0

	# get weapon stuff
	weapon_index = index
	for child in weapon_node.get_children():
		child.free()

	reticle.cancel_reload()
	status_label.hide_status_label()
	reloading = false

	speed_multiplier = 1.0
	ads_speed_multiplier = 1.0

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
	weapon_heat_light = current_weapon.get_node_or_null("./BarrelHeatLight")

	weapon_mag = current_weapon.get_node("./Magazine")
	mag_orig_pos = weapon_mag.position

	if im.equipped_weapons[index].type_data.mag_attached:
		current_weapon.texture = current_weapon.loaded_texture
	else:
		current_weapon.texture = current_weapon.base_texture

	_set_weapon_stats()

	can_fire = true

	_set_ammo_mag_data()


func _set_weapon_stats() -> void:
	var weapon_data: ItemData = im.equipped_weapons[weapon_index]
	var type_data: WeaponData = weapon_data.type_data
	var stats: WeaponStats = type_data.weapon_stats

	base_damage = stats.damage
	fire_rate = stats.fire_rate
	max_ammo = stats.mag_size

	effective_range = stats.effective_range
	max_range = stats.max_range

	kick = stats.kick
	kick_recovery = stats.kick_recovery

	hipfire_spread = stats.hipfire_spread
	ads_spread = stats.ads_spread
	max_hipfire_spread = stats.max_hipfire_spread
	max_ads_spread = stats.max_ads_spread
	spread_recovery = stats.spread_recovery
	first_shot_spread_mult = stats.first_shot_spread_mult

	h_recoil = stats.horizontal_recoil
	v_recoil = stats.vertical_recoil
	reticle.stiffness = stats.recoil_stiffness
	reticle.damping = stats.recoil_damping

	reload_time = stats.reload_time
	reticle.reload_time = reload_time
	ads_time = stats.ads_time

	current_spread = 0.0
	kick_offset = 0.0
	weapon_rest_pos = current_weapon.position
	camera_shake = stats.camera_shake

	heat_per_shot = stats.heat
	cooling_rate = stats.cooling_rate

	speed_multiplier = stats.speed_multiplier
	ads_speed_multiplier = stats.ads_speed_multiplier

	_set_attachment_stats()


func _set_attachment_stats() -> void:
	if weapon_index == -1:
		return

	var weapon_data: ItemData = im.equipped_weapons[weapon_index]
	var type_data: WeaponData = weapon_data.type_data

	# reset attachment states
	suppressor_attached = false

	# reset weapon stats stuff
	sound_multiplier = 1.0
	muzzle_flash_multiplier = 1.0
	smoke_multiplier = 1.0
	attachment_spread_multiplier = 1.0

	# do stuff for applying attachment stats
	if type_data.attachments.size() > 0:
		for attachment: ItemData in type_data.attachments.values():
			var attachment_data: AttachmentData = attachment.type_data
			var attachment_stats: AttachmentTypeData = attachment_data.type_data
			var type := AttachmentData.AttachmentType
			match attachment_data.type:
				type.OPTIC:
					pass
				type.MUZZLE:
					sound_multiplier = attachment_stats.sound_multiplier
					muzzle_flash_multiplier = attachment_stats.muzzle_flash_multiplier
					smoke_multiplier = attachment_stats.smoke_multiplier
					attachment_spread_multiplier = attachment_stats.spread_multiplier

					base_damage *= attachment_stats.damage_multiplier
					effective_range *= attachment_stats.range_multiplier
					max_range *= attachment_stats.range_multiplier

					# states
					if attachment_stats is SuppressorData:
						suppressor_attached = true
				type.GRIP:
					pass
				type.STOCK:
					pass
				type.TACTICAL:
					pass


func _set_ammo_mag_data() -> void:
	if weapon_index == -1:
		return

	var weapon: ItemData = im.equipped_weapons[weapon_index]
	if not weapon:
		return

	var stats: WeaponData = weapon.type_data

	# save weapon state
	var mag_count: int = 0
	for item in im.inventory_items:
		if item.type == ItemData.ItemType.MAGAZINE and stats.weapon == item.type_data.compatible:
			if item.container_items.size() > 0:
				mag_count += 1

	var total_ammo: int = 0
	if weapon.container_items.size() > 0 and weapon.container_items[0].container_items.size() > 0:
		total_ammo = weapon.container_items[0].container_items[0].count
	stats.total_ammo = total_ammo

	weapon_state[weapon_name] = { "ammo": stats.total_ammo, "mags": mag_count }

	# restore saved state
	ammo = weapon_state[weapon_name].ammo
	mags = weapon_state[weapon_name].mags


func _schedule_load_mag_anim(delay: float, reload_key: bool) -> void:
	mag_anim_reload_key = reload_key
	mag_anim_timer.start(max(delay, 0.001))


func _cancel_load_mag_anim() -> void:
	mag_anim_timer.stop()


func _on_mag_anim_timer_timeout() -> void:
	load_mag_anim(mag_anim_reload_key)


func _get_loaded_ammo(weapon: ItemData) -> int:
	if weapon.container_items.size() == 0:
		return 0

	var mag_items: Array[ItemData] = weapon.container_items[0].container_items
	var count: int = mag_items[0].count if mag_items.size() > 0 else 0
	return count


func _find_fullest_mag(weapon: ItemData) -> ItemData:
	var fullest_mag: ItemData
	var fullest_mag_size: int = 0
	for item in im.inventory_items:
		if (
			item.type == ItemData.ItemType.MAGAZINE
			and weapon.type_data.weapon == item.type_data.compatible
		):
			if item.container_items.size() > 0 and item.container_items[0].count > fullest_mag_size:
				fullest_mag = item
				fullest_mag_size = item.container_items[0].count
	return fullest_mag


func _restore_mag_sprite(attached: bool) -> void:
	var sprite: Sprite2D = weapon_node.get_child(0)
	var mag: Sprite2D = sprite.get_node("./Magazine")
	sprite.texture = sprite.loaded_texture if attached else sprite.bare_texture

	if mag_anim_tween:
		mag_anim_tween.kill()

	var mag_tween := create_tween()
	mag_tween.tween_property(mag, "modulate:a", 0.0, 0.1) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	mag_tween.finished.connect(
		func() -> void:
			if mag:
				mag.visible = false
				mag.modulate.a = 1.0,
	)


func _start_unjam(weapon: ItemData) -> void:
	if unjamming:
		return
	unjamming = true
	var unjam_weapon_index: int = weapon_index

	status_label.show_status_label("UNJAMMING")

	reticle.reload_time = weapon.type_data.weapon_stats.unjam_time
	reticle.start_reload()
	reticle.tween.finished.connect(
		func() -> void:
			AudioManager.play("weapon_unjam", global_position)

			unjamming = false
			if unjam_weapon_index != weapon_index: # handle case if player switches weapon mid unjam
				return

			weapon.type_data.jammed = false
			hud.update_hint_label(false)
			status_label.hide_status_label(),
		CONNECT_ONE_SHOT,
	)
