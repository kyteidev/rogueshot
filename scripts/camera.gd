extends Camera2D


const SMOOTHNESS = 3

@onready var player = $"../Player"


func _physics_process(delta: float) -> void:
	position = position.lerp(player.global_position, delta * SMOOTHNESS)
