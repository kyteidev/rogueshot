extends CharacterBody2D

const MAX_HEALTH = 100.0
const DAMAGE_FLASH_DELAY = 0.04

const BASE_SPEED = 80.0
const SPRINT_MULTIPLIER = 1.5

const MAX_STAMINA = 100.0
const STAMINA_RECOVERY_DELAY = 1.5
const STAMINA_RECOVERY_RATE = 30.0
const STAMINA_SLOW_RECOVERY_MULTIPLIER = 0.45

const STAMINA_COLOR = Color("3cffae")
const STAMINA_FLASH_COLOR = Color("32757c")
const STAMINA_FLASH_DELAY = 0.5
const STAMINA_BAR_DELAY = 0.5
const STAMINA_BAR_FADE_DURATION = 0.3
const STAMINA_BAR_FADE_DELAY = 1.0

const SPRINT_STAMINA_RATE = 20.0
const WALLBOUNCE_STAMINA_RATE = 15.0
const SHOOT_STAMINA_RATE = 2.0

const WALLBOUNCE_VELOCITY = 150

const GROUND_ACCEL = 900.0
const GROUND_FRICTION = 1100.0
const AIR_ACCEL = 600.0
const AIR_FRICTION = 300.0
const TURN_MULTIPLIER = 1.5

const JUMP_VELOCITY = -200.0
const JUMP_VELOCITY_CUT = JUMP_VELOCITY / 3

const GRAVITY = 750
const FALL_GRAVITY = GRAVITY * 1.5

const STRETCH = 0.2

const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.12

const DEATH_TRANS_DELAY = 1.0

@export var transition: CanvasLayer
@export var crosshair: CanvasLayer
@export var temp_item: ItemData

var sm := StateManager
var im := InventoryManager

var prev_health: float = MAX_HEALTH
var health: float = MAX_HEALTH:
	set(value):
		health = clamp(value, 0.0, MAX_HEALTH)
		sm.health = health

		if value < prev_health:
			sm.lost_health = true
		prev_health = value

var was_airborne := false
var reached_peak := false

var speed := 0.0:
	set(value):
		speed = value

		# dynamically change player animation speed
		# possibly change to exponential formula?
		# this linear formula seems to work fine for player,
		# but not so well for enemy (maybe I'm stupid lmao)
		var multiplier: float = value / BASE_SPEED
		anim_sprite.speed_scale = 1.0 * multiplier
var sprinting := false

var is_dead := false
var started_death_sequence := false

var regenerating_stamina := true
var prev_stamina: float = MAX_STAMINA
var stamina: float:
	set(value):
		stamina = clamp(value, 0.0, MAX_STAMINA)
		sm.stamina = stamina

		if not regenerating_stamina:
			stamina_timer.start(STAMINA_RECOVERY_DELAY)
		else:
			regenerating_stamina = false

		if value < prev_stamina:
			sm.used_stamina = true
		prev_stamina = value

		if stamina == 0:
			stamina_depleted = true
var stamina_depleted := false:
	set(value):
		stamina_depleted = value
		sm.stamina_depleted = value

var displayed_stamina_loss := 100.0
var stamina_bar_faded := false
var stamina_bar_fading := false
var stamina_fade_timer_started := false

var health_tween: Tween
var stamina_tween: Tween
var stamina_fade_tween: Tween
var stamina_was_depleted := false

var flipped := false

var items_in_range: Array[Node2D]
var closest_item: Node2D

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

@onready var death_timer: Timer = $DeathTimer

@onready var anim_sprite: AnimatedSprite2D = $AnimSprite
@onready var stamina_timer: Timer = $StaminaTimer

@onready var weapon: Node2D = $Weapon
@onready var collision: CollisionShape2D = $FullCollision

@onready var stamina_bar_outline: TextureRect = $StaminaBarOutline
@onready var stamina_bar: TextureProgressBar = $StaminaBarOutline/StaminaBar
@onready var stamina_loss_bar: TextureProgressBar = $StaminaBarOutline/StaminaLossBar
@onready var stamina_bar_timer: Timer = $StaminaBarOutline/StaminaBarTimer
@onready var stamina_bar_fade_timer: Timer = $StaminaBarOutline/StaminaBarFadeTimer

@onready var hud: CanvasLayer = get_node("../HUD")


func _ready() -> void:
	# have this in _ready so max stamina only needs to be adjusted here,
	# otherwise i'd have to change max stamina here and in state manager
	stamina = MAX_STAMINA

	death_timer.wait_time = DEATH_TRANS_DELAY
	collision.disabled = false

	# sync values with state manager
	sm.health = health
	sm.max_health = MAX_HEALTH
	sm.stamina = stamina

	# TEMPORARY
	_spawn.call_deferred()


func _physics_process(delta: float) -> void:
	var input_locked: bool = sm.is_input_locked()
	var was_on_floor: bool = is_on_floor()

	# get direction of player
	# right: 1, left: -1, neutral (not moving): 0
	var direction: float = 0.0 if input_locked else Input.get_axis("player_left", "player_right")

	# flip direction if needed
	var mouse_pos: Vector2 = get_global_mouse_position()
	var cursor_direction: Vector2 = mouse_pos - global_position

	# force turn if keybind held down when moving
	if Input.is_action_pressed("player_facing_lock") and direction != 0.0:
		flipped = direction < 0.0
	elif not Input.is_action_pressed("player_facing_lock"):
		flipped = cursor_direction.x < 0

	if not input_locked:
		anim_sprite.flip_h = flipped
	var same_direction: bool = (direction == -1 and flipped) or (direction == 1 and not flipped)

	# apply no aim multiplier if needed
	if not same_direction:
		weapon.spread_multiplier *= weapon.NO_AIM_SPREAD_MULTIPLIER

	# gravity and jump stretch
	if not is_on_floor():
		velocity.y += _get_custom_gravity(velocity) * delta
		was_airborne = true

		if not reached_peak and velocity.y >= 0:
			reached_peak = true
			anim_sprite.scale = Vector2(1.0, 1.0)

	if is_dead:
		if not is_on_floor():
			move_and_slide()
		elif not started_death_sequence:
			started_death_sequence = true

			# make player red when dead
			anim_sprite.play("death")
			weapon.fade_weapon()
			collision.disabled = true

			# fade stamina bar
			var stamina_hide_fade_tween := create_tween()
			stamina_hide_fade_tween.tween_property(stamina_bar_outline, "modulate", Color(
				"ffffff00"
			), 0.25) \
					.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

			anim_sprite.animation_finished.connect(death_timer.start)
		return

	# player jump system
	if not input_locked and Input.is_action_just_pressed("player_jump"):
		jump_buffer_timer.start(JUMP_BUFFER_TIME)

	if Input.is_action_just_released("player_jump") and velocity.y < JUMP_VELOCITY_CUT:
		velocity.y = JUMP_VELOCITY_CUT

	var wants_jump: bool = not jump_buffer_timer.is_stopped()
	var can_jump: bool = is_on_floor() or not coyote_timer.is_stopped()

	if wants_jump and can_jump:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer.stop()
		coyote_timer.stop()

		# jump stretch
		anim_sprite.scale = Vector2(1 - STRETCH, 1 + STRETCH)
		reached_peak = false

	# reduce y velocity if player hits ceiling
	if is_on_ceiling():
		velocity.y *= 0.5

	# sprint system
	speed = BASE_SPEED
	if is_on_floor():
		var enough_stamina: bool = stamina > 0.0 and not stamina_depleted
		if Input.is_action_pressed("player_sprint") and enough_stamina and same_direction:
			sprinting = true

			# cancel reload if sprinting
			if sm.reloading:
				crosshair.cancel_reload()
		else:
			sprinting = false

	if sprinting:
		speed *= SPRINT_MULTIPLIER

		# don't deplete stamina if not moving
		if direction != 0.0:
			stamina -= SPRINT_STAMINA_RATE * delta

	# recover stamina when not sprinting
	if stamina_timer.is_stopped():
		regenerating_stamina = true
		stamina += STAMINA_RECOVERY_RATE * delta * (
			STAMINA_SLOW_RECOVERY_MULTIPLIER if stamina_depleted else 1.0
		)

		if stamina == MAX_STAMINA:
			stamina_depleted = false

	# apply weapon speed multiplier
	speed *= weapon.speed_multiplier

	# plays correct animation
	if is_on_floor():
		if direction == 0:
			anim_sprite.animation = "idle"
		else:
			anim_sprite.animation = "run"
	else:
		anim_sprite.animation = "jump"

	if flipped:
		anim_sprite.play_backwards()
	else:
		anim_sprite.play()

	# calculate x velocity
	var accel: float
	if direction == 0: # apply friction when not moving
		accel = GROUND_FRICTION if is_on_floor() else AIR_FRICTION
	else:
		accel = GROUND_ACCEL if is_on_floor() else AIR_ACCEL

		# makes turns faster
		if velocity.x != 0 and sign(velocity.x) != sign(direction):
			accel *= TURN_MULTIPLIER
	velocity.x = move_toward(velocity.x, direction * speed, accel * delta)

	# wallbounce
	if (
		is_on_wall() and not is_on_floor() and Input.is_action_just_pressed("player_jump")
		and stamina > 0.0 and not stamina_depleted
	):
		var wall_normal: float = get_wall_normal().x
		if wall_normal > 0:
			anim_sprite.flip_h = false
		elif wall_normal < 0:
			anim_sprite.flip_h = true

		velocity.x += WALLBOUNCE_VELOCITY * wall_normal
		velocity.y = JUMP_VELOCITY

		stamina -= WALLBOUNCE_STAMINA_RATE

		coyote_timer.stop()
		jump_buffer_timer.stop()

		# jump stretch
		anim_sprite.scale = Vector2(1 - STRETCH, 1 + STRETCH)
		reached_peak = false

	# smoothly revert back from jump stretch scale to normal scale
	anim_sprite.scale = anim_sprite.scale.lerp(Vector2(1.0, 1.0), 10.0 * delta)

	move_and_slide()

	# coyote time management
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyote_timer.start(COYOTE_TIME)

	# stamina
	_update_stamina_bar(delta)

	# item stuff
	_highlight_items()
	_item_pickup()


func take_damage(damage: float, _global_position: Vector2) -> void:
	# flash red when taking damage
	var tween := create_tween()
	tween.tween_property(anim_sprite, "modulate", Color("ff0000"), DAMAGE_FLASH_DELAY)
	tween.tween_property(anim_sprite, "modulate", Color("ffffff"), DAMAGE_FLASH_DELAY)

	if not is_dead:
		health -= damage
		if health <= 0:
			is_dead = true


# temporary, only for testing item pickup
func _spawn() -> void:
	var item_scene := preload("res://scenes/item.tscn")
	var inst := item_scene.instantiate()
	get_tree().current_scene.add_child(inst)
	inst.global_position = global_position + Vector2(50.0, -10.0)
	inst.setup(temp_item)

	var inst2 := item_scene.instantiate()
	get_tree().current_scene.add_child(inst2)
	inst2.global_position = global_position + Vector2(80.0, -10.0)
	inst2.setup(temp_item)


func _start_stamina_flash() -> void:
	if stamina_tween:
		stamina_tween.kill()

	stamina_tween = create_tween().set_loops()
	stamina_tween.tween_property(
		stamina_bar,
		"tint_progress",
		STAMINA_FLASH_COLOR,
		STAMINA_FLASH_DELAY,
	)
	stamina_tween.tween_property(stamina_bar, "tint_progress", STAMINA_COLOR, STAMINA_FLASH_DELAY)


func _stop_stamina_flash() -> void:
	if stamina_tween:
		stamina_tween.kill()

	create_tween().tween_property(stamina_bar, "tint_progress", STAMINA_COLOR, STAMINA_FLASH_DELAY)


func _get_custom_gravity(vel: Vector2) -> float:
	if vel.y < 0:
		return GRAVITY
	return FALL_GRAVITY


func _on_death_timer_timeout() -> void:
	var scene: PackedScene = preload("res://scenes/menus/death_menu.tscn")
	transition.start_transition(scene)


func _update_stamina_bar(delta: float) -> void:
	# fade stamina bar if stamina is full
	if sm.stamina == MAX_STAMINA:
		# apply delay before fade
		if not stamina_bar_faded:
			stamina_bar_faded = true
			if not stamina_fade_timer_started:
				stamina_bar_fade_timer.start(STAMINA_BAR_FADE_DELAY)
				stamina_fade_timer_started = true

		if (
			not stamina_bar_fading and stamina_fade_timer_started
			and stamina_bar_fade_timer.is_stopped()
		):
			stamina_bar_fading = true

			stamina_fade_tween = create_tween()
			stamina_fade_tween \
					.tween_property(stamina_bar_outline, "modulate", Color("ffffff00"), 0.5) \
					.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		if stamina_fade_tween:
			stamina_fade_tween.kill()

		stamina_bar_faded = false
		stamina_bar_fading = false
		stamina_fade_timer_started = false
		stamina_bar_outline.modulate = Color("ffffffff")

	# update stamina info
	stamina_bar.value = sm.stamina

	# flash stamina bar if completely depleted
	if sm.stamina_depleted and not stamina_was_depleted:
		_start_stamina_flash()
	elif not sm.stamina_depleted and stamina_was_depleted:
		_stop_stamina_flash()
	stamina_was_depleted = sm.stamina_depleted

	# delay the stamina loss bar
	if sm.used_stamina:
		sm.used_stamina = false
		stamina_bar_timer.start(STAMINA_BAR_DELAY)

	if sm.stamina >= displayed_stamina_loss:
		displayed_stamina_loss = sm.stamina
	elif stamina_bar_timer.is_stopped():
		displayed_stamina_loss = lerpf(displayed_stamina_loss, sm.stamina, 1.0 - exp(-10.0 * delta))

		# snap to value if close enough
		if absf(displayed_stamina_loss - sm.stamina) < 0.1:
			displayed_stamina_loss = sm.stamina

	stamina_loss_bar.value = displayed_stamina_loss


func _item_pickup() -> void:
	if items_in_range.size() == 0 or not Input.is_action_just_pressed("player_interact"):
		return

	im.add_item(closest_item.data)
	closest_item.queue_free()


# YAY THIS WORKS NOW :D
# there's probably a more efficient method but I'm too lazy to fix that rn
func _highlight_items() -> void:
	if items_in_range.size() == 0:
		hud.update_hint_label(false)
		closest_item = null
		return

	var closest_distance: float

	# get closest item and highlight it
	for item: Node2D in items_in_range:
		var distance: float = global_position.distance_to(item.global_position)
		if not closest_distance or distance < closest_distance:
			closest_item = item
			closest_distance = distance
		item.hide_outline()
	closest_item.show_outline()
	hud.update_hint_label(true, "player_interact", "pick up item")


func _on_item_pickup_area_body_entered(body: Node2D) -> void:
	items_in_range.append(body)


func _on_item_pickup_area_body_exited(body: Node2D) -> void:
	var index: int = items_in_range.find(body)
	var popped_body: Node2D = items_in_range.pop_at(index)
	popped_body.hide_outline()
