extends TextureProgressBar

var has_hidden := false

@onready var load_timer: Timer = %LoadTimer
@onready var unload_timer: Timer = %UnloadTimer
@onready var overlay: ColorRect = %Overlay


func _ready() -> void:
	visible = false


func _process(_delta: float) -> void:
	if load_timer.time_left != 0.0 or unload_timer.time_left != 0.0:
		has_hidden = false

		visible = true
		overlay.visible = true
		value = max_value - (
			load_timer.time_left if load_timer.time_left != 0.0 else unload_timer.time_left
		)
	else:
		if not has_hidden:
			visible = false
			overlay.visible = false

			has_hidden = true
