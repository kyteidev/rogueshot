extends Sprite2D


const STRETCH = 0.2
const FADE_DURATION = 0.3
const FADE_DELAY = 0.3

var stretch_tween: Tween
var fade_tween: Tween
var can_fade = false

@onready var original_pos = position
@onready var original_scale = scale

@onready var fade_timer = $FadeTimer
@onready var enemy = get_parent()


func _ready() -> void:
	visible = false
	fade_timer.wait_time = FADE_DELAY
	

func _on_fade_timer_timeout() -> void:
	if can_fade:
		if fade_tween:
			fade_tween.kill()
		
		fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate", Color("ffffff00"), FADE_DURATION)
		fade_tween.finished.connect(_finish_anim)


func _finish_anim() -> void:
	visible = false
	modulate = Color("ffffffff")
	
	can_fade = false


# this is called from enemy.gd
func play_anim() -> void:
	if stretch_tween:
		stretch_tween.kill()
	
	visible = true
	
	# icon squash and stretch animation
	scale = Vector2(original_scale.x + STRETCH, 0.0)
	modulate = Color("ffffff00")
	
	stretch_tween = create_tween()
	
	# part 1
	stretch_tween.parallel().tween_property(self, "scale", original_scale + Vector2(-STRETCH, STRETCH), 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	stretch_tween.parallel().tween_property(self, "modulate", Color("ffffffff"), 0.05)
	
	# part 2
	stretch_tween.chain().tween_property(self, "scale", original_scale, 0.18)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)\
			.finished.connect(fade_timer.start)
