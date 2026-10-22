extends CanvasLayer


@export var crosshair: CanvasLayer

var sm := StateManager

@onready var cursor := crosshair.get_child(0)


func _ready() -> void:
	visible = false
	

func toggle_inventory() -> void:
	# toggle between mouse cursor and crosshair
	visible = not visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_HIDDEN
	
	# move cursor to crosshair after exiting
	if cursor.position != get_viewport().get_mouse_position():
		get_viewport().warp_mouse(cursor.position)
	
	# cancel reload
	crosshair.cancel_reload()
	
	# lock/unlock input
	sm.set_input_lock("inventory", visible)


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_inventory") or (visible and Input.is_action_just_pressed("ui_cancel")):
		toggle_inventory()
