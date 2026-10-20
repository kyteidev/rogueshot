extends CPUParticles2D


enum Type { DEFAULT, BLOOD }

const COLORS: Dictionary = {
	Type.DEFAULT: [
		Color("#FFF7C2"), Color("#FFD23F"), Color("#F26B1D"), Color("#8A1C0F", 0.0)
	],
	Type.BLOOD: [
		Color("#FF4A4A"), Color("#C41E2E"), Color("#5A0F1A"), Color("#5A0F1A", 0.0)
	]
}

const OFFSETS = [0.0, 0.3, 0.7, 1.0]


func _ready() -> void:
	emitting = true
	
	# fade out animation
	var tween := create_tween()
	tween.tween_interval(lifetime / 2)
	tween.tween_property(self, "modulate", Color("ffffff00"), lifetime / 2)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	finished.connect(queue_free)


func set_impact_color(color_type: Type) -> void:
	# set gradient based on impact object type
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.offsets = OFFSETS
	gradient.colors = COLORS[color_type]
	color_ramp = gradient
