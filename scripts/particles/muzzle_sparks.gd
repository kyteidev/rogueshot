extends CPUParticles2D


func _ready() -> void:
	emitting = true

	# fade out animation
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color("ffffff00"), lifetime) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	finished.connect(queue_free)
