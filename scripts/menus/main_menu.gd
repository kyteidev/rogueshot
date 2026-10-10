extends CanvasLayer


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_debug.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
