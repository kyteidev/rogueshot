extends CanvasLayer


@export var crosshair: CanvasLayer

@onready var cursor := crosshair.get_child(0)


func _ready() -> void:
	visible = false
	

func toggle_inventory() -> void:
	# toggle between mouse cursor and crosshair
	visible = not visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_HIDDEN
	crosshair.process_mode = Node.PROCESS_MODE_DISABLED if visible else Node.PROCESS_MODE_INHERIT
	
	# move cursor to crosshair after exiting
	if cursor.position != get_viewport().get_mouse_position():
		get_viewport().warp_mouse(cursor.position)
	
	# cancel reload
	crosshair.cancel_reload()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_inventory") or (visible and Input.is_action_just_pressed("ui_cancel")):
		toggle_inventory()
