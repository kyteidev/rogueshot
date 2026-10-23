extends CheckButton


@export var setting_key: String

var om := OptionsManager


func _ready() -> void:
	toggled.connect(func(enabled: bool) -> void: om.set_option(setting_key, enabled))
	
