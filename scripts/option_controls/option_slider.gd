extends HSlider

@export var setting_key: String

var om := OptionsManager


func _ready() -> void:
	drag_ended.connect(
		func(different: bool) -> void:
			if different:
				om.set_option(setting_key, value),
	)
