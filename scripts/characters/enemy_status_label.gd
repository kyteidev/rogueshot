extends Label


const FADE_DURATION = 0.3
const VISIBLE_DURATION = 3.0

var fade_tween: Tween

@onready var timer := $FadeTimer


func _ready() -> void:
	visible = false
	timer.wait_time = VISIBLE_DURATION


func set_status_label(status_text: String) -> void:
	text = status_text
	modulate = Color("ffffff00")
	visible = true
	
	# fade in animation
	if fade_tween:
		fade_tween.kill()
		
		fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate", Color("ffffff"), FADE_DURATION)
		fade_tween.finished.connect(timer.start)


func _on_fade_timer_timeout() -> void:
	# fade out animation
	if fade_tween:
		fade_tween.kill()
		
		fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate", Color("ffffff00"), FADE_DURATION)
		fade_tween.finished.connect(func() -> void: visible = false)
