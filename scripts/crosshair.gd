extends CanvasLayer


const STEPS: int = 16

@onready var cursor = $Cursor
@onready var reticle = $Cursor/Reticle
@onready var ring = $Cursor/ReloadRing 

var sm = StateManager
var tween: Tween


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	ring.max_value = STEPS
	ring.position = -ring.texture_progress.get_size() / 2.0 # center crosshair


func _process(_delta: float) -> void:
	cursor.position = get_viewport().get_mouse_position()
	

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("weapon_reload"):
		start_reload() # temporary


func start_reload() -> void:
	# prevent duplicate reloads
	if tween and tween.is_running():
		return
	ring.visible = true
	reticle.visible = false
	ring.value = STEPS
	
	# smoothly fill up ring progress bar
	tween = create_tween()
	tween.tween_method(_set_ring, 0.0, 1.0, sm.reload_time)
	tween.finished.connect(_finish_reload)
	

func _set_ring(tick: float) -> void:
	ring.value = tick * STEPS


func _finish_reload() -> void:
	ring.visible = false
	reticle.visible = true
