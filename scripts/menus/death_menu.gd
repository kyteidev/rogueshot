extends CanvasLayer

const DURATION = 1.0

@onready var overlay: ColorRect = $Overlay


func _ready() -> void:
	overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var tween := create_tween()
	tween.tween_property(overlay, "modulate", Color("ffffff00"), DURATION) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_debug.tscn")
