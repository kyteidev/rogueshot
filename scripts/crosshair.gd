extends CanvasLayer


const STEPS: int = 128

var sm := StateManager
var tween: Tween

var reload_time: float = 0.0

@onready var cursor: Node2D = $Cursor
@onready var reticle: Sprite2D = $Cursor/Reticle
@onready var ring: TextureProgressBar = $Cursor/ReloadRing 


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	ring.max_value = STEPS
	ring.position = -ring.texture_progress.get_size() / 2.0 # center crosshair
	
	visible = true


func _process(_delta: float) -> void:
	if not sm.is_input_locked():
		cursor.position = get_viewport().get_mouse_position()
	

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
