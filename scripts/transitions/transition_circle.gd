extends CanvasLayer

const DURATION = 1.0

@export var player: CharacterBody2D

@onready var rect: ColorRect = $ColorRect

@onready var screen_size: Vector2 = get_viewport().get_visible_rect().size
@onready var shader: ShaderMaterial = rect.material


func _ready() -> void:
	visible = false

	shader.set_shader_parameter("screen_width", screen_size.x)
	shader.set_shader_parameter("screen_height", screen_size.y)
	shader.set_shader_parameter("circle_size", 1.0)


func start_transition(next_scene: PackedScene) -> void:
	visible = true

	var player_screen_pos: Vector2 = player.get_global_transform_with_canvas().origin
	var player_uv_pos: Vector2 = player_screen_pos / screen_size
	shader.set_shader_parameter("center", player_uv_pos)

	var tween := create_tween()
	tween.tween_property(shader, "shader_parameter/circle_size", 0.0, DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(
		func() -> void:
			_switch_scene(next_scene),
	)


func _switch_scene(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)
