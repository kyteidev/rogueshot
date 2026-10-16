extends Camera2D


const SMOOTHNESS = 3
const SHAKE_FADE = 5.0

@onready var player: CharacterBody2D = $"../Player"

var rng := RandomNumberGenerator.new()
var shake_strength: float = 0.0


func _physics_process(delta: float) -> void:
	position = position.lerp(player.global_position, delta * SMOOTHNESS)
	
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, SHAKE_FADE * delta)
		offset = _get_random_offset()


func _get_random_offset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
