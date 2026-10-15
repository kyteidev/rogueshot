extends CanvasLayer


@export var crosshair: CanvasLayer

@onready var cursor = crosshair.get_child(0)


func _ready() -> void:
	visible = false
	get_tree().paused = false
	

func _toggle_pause() -> void:
	visible = not visible
	get_tree().paused = not get_tree().paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_HIDDEN
	
	if cursor.position != get_viewport().get_mouse_position():
		get_viewport().warp_mouse(cursor.position)


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_pause()


func _on_resume_button_pressed() -> void:
	_toggle_pause()


func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
