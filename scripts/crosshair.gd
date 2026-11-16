extends Node2D

const STEPS: int = 128
const RECOIL_SPEED = 3.0

var sm := StateManager
var tween: Tween

var reload_time := 0.0

var recoil_offset := Vector2.ZERO
var recoil_velocity := Vector2.ZERO

var stiffness := 0.0
var damping := 0.0

@onready var reticle: Sprite2D = $Reticle
@onready var ring: TextureProgressBar = $ReloadRing


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	ring.max_value = STEPS
	ring.position = -ring.texture_progress.get_size() / 2.0 # center crosshair

	visible = true


func _process(delta: float) -> void:
	if not sm.is_input_locked():
		var spring_force: Vector2 = -stiffness * recoil_offset
		var damping_force: Vector2 = -damping * recoil_velocity

		recoil_velocity += (spring_force + damping_force) * delta
		recoil_offset += recoil_velocity * delta
		global_position = get_global_mouse_position() + recoil_offset


func apply_recoil(weapon_rotation: float, h_recoil_amount: float, v_recoil_amount: float) -> void:
	var v_direction := Vector2(cos(weapon_rotation), sin(weapon_rotation))
	var h_direction := Vector2(-v_direction.y, v_direction.x)
	var impulse: Vector2 = (v_direction * v_recoil_amount) + (
		h_direction * randf_range(-h_recoil_amount, h_recoil_amount)
	)

	recoil_velocity += impulse


func start_reload() -> void:
	# prevent duplicate reloads
	if tween and tween.is_running():
		return

	sm.reloading = true

	ring.visible = true
	reticle.visible = false
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
	reticle.visible = true

	sm.reloading = false
