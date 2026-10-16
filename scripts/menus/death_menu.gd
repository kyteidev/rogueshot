extends CanvasLayer


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_debug.tscn")
