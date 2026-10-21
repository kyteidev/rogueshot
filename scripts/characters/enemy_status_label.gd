extends Label


const FADE_DURATION = 0.3

var fade_tween: Tween

@onready var timer := $FadeTimer


func _ready() -> void:
	visible = false


func show_status_label(status_text: String) -> void:
	text = status_text
	modulate = Color("ffffff00")
	visible = true
	
	# fade in animation
	if fade_tween:
		fade_tween.kill()
		
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate", Color("ffffff"), FADE_DURATION)


func hide_status_label() -> void:
	if not visible:
		return
	
	# fade out animation
	if fade_tween:
		fade_tween.kill()
		
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate", Color("ffffff00"), FADE_DURATION)
	fade_tween.finished.connect(func() -> void: visible = false)
