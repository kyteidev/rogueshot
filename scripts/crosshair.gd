extends Node2D

const STEPS: int = 128
const RECOIL_SPEED = 3.0
const GAP_RECOVERY_SPEED = 10.0

const LINE_COLOR = Color("ffffff")
const LINE_LENGTH = 5.0
const LINE_THICKNESS = 1.5

@export var player: CharacterBody2D

var sm := StateManager
var im := ItemManager
var rng := Random.rng
var tween: Tween

var reload_time := 0.0

# spread stuff idk
var gap: float = 0.0
var target_gap: float = 0.0

# recoil stuff
var recoil_offset := Vector2.ZERO
var recoil_velocity := Vector2.ZERO

var stiffness := 0.0
var damping := 0.0

@onready var ring: TextureProgressBar = $ReloadRing
@onready var weapon: Node2D = player.get_node("./Weapon")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	ring.max_value = STEPS
	ring.position = -ring.texture_progress.get_size() / 2.0 # center crosshair

	visible = true


func _process(delta: float) -> void:
	if sm.is_input_locked():
		visible = false
		return
	visible = true

	var spring_force: Vector2 = -stiffness * recoil_offset
	var damping_force: Vector2 = -damping * recoil_velocity

	recoil_velocity += (spring_force + damping_force) * delta
	recoil_offset += recoil_velocity * delta
	global_position = get_global_mouse_position() + recoil_offset

	if im.weapon_index != -1:
		var dist_to_weapon: float = global_position.distance_to(
			weapon.weapon_muzzle.global_position
		)
		target_gap = dist_to_weapon * tan(
			deg_to_rad(weapon.current_spread * weapon.get_spread_multiplier())
		)
	else:
		target_gap = 0.0
	gap = lerp(gap, target_gap, 1.0 - exp(-GAP_RECOVERY_SPEED * delta))

	queue_redraw()


func _draw() -> void:
	if sm.reloading:
		return

	# top, bottom, left, right
	draw_line(Vector2(0.0, -gap), Vector2(0.0, -gap - LINE_LENGTH), LINE_COLOR, LINE_THICKNESS)
	draw_line(Vector2(0.0, gap), Vector2(0.0, gap + LINE_LENGTH), LINE_COLOR, LINE_THICKNESS)
	draw_line(Vector2(-gap, 0.0), Vector2(-gap - LINE_LENGTH, 0.0), LINE_COLOR, LINE_THICKNESS)
	draw_line(Vector2(gap, 0.0), Vector2(gap + LINE_LENGTH, 0.0), LINE_COLOR, LINE_THICKNESS)

	# draw center dot if ADS
	if sm.ads:
		var rect_size: Vector2 = Vector2.ONE * LINE_THICKNESS
		var rect := Rect2(Vector2.ZERO - (rect_size / 2), rect_size)
		draw_rect(rect, Color(Color.RED))


func apply_recoil(weapon_rotation: float, h_recoil_amount: float, v_recoil_amount: float) -> void:
	var v_direction := Vector2(cos(weapon_rotation), sin(weapon_rotation))
	var h_direction := Vector2(-v_direction.y, v_direction.x)
	var impulse: Vector2 = (v_direction * v_recoil_amount) + (
		h_direction * rng.randf_range(-h_recoil_amount, h_recoil_amount)
	)

	recoil_velocity += impulse


func start_reload() -> void:
	# prevent duplicate reloads
	if tween and tween.is_running():
		return

	sm.reloading = true

	ring.visible = true
	ring.value = STEPS

	# smoothly fill up ring progress bar
	tween = create_tween()
	tween.tween_method(_set_ring, 0.0, 1.0, reload_time)
	tween.finished.connect(_finish_reload)


func cancel_reload() -> void:
	if tween:
		tween.kill()

		# fixes issue where ring and reticle is null when scene is initialized for some reason
		# KEEP INSIDE IF STATEMENT
		_finish_reload()


func _set_ring(tick: float) -> void:
	ring.value = tick * STEPS


func _finish_reload() -> void:
	ring.visible = false
	sm.reloading = false
