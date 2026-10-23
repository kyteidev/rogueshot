extends Node


var camera_shake: bool = true

var options: Array


func _ready() -> void:
	# default options
	# TODO: options saving and loading from file
	
	# layer 0: tab type as index
	# 		0: gameplay, 1: video, 2: audio, 3: controls
	# layer 1: options
	options = [
		{
			"camera_shake": camera_shake
		},
		{
			"lorem ipsum": false
		},
		{
			"lorem ipsum": false
		},
		{
			"lorem ipsum": false
		}
	]


func get_option(option: String) -> Variant:
	var value: Variant = null
	for category: Dictionary in options:
		if category.has(option):
			value = category.get(option)
	return value
			

func set_option(option: String, value: Variant) -> void:
	for category: Dictionary in options:
		if category.has(option):
			category[option] = value
