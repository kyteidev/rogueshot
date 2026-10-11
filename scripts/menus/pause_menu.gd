extends CanvasLayer


func _ready() -> void:
	visible = false
	get_tree().paused = false
	

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			visible = false
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		else:
			visible = true
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_resume_button_pressed() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
