extends Node

var camera_shake := true

var options: Array


func _ready() -> void:
	# default options
	# TODO: options saving and loading from file

	# layer 0: tab type as index
	# 		-> 0: gameplay, 1: video, 2: audio, 3: controls
	# layer 1: options
	options = [
		{ "camera_shake": camera_shake },
		{ "lorem ipsum": false },
		{ "lorem ipsum": false },
		# keybinds are managed independently
		# this is for displaying the keybind in options menu
		{
			"player_left": "A",
			"player_right": "D",
			"player_jump": "W",
			"player_sprint": "Shift",
			"player_facing_lock": "Z",
			"ui_inventory": "E",
			"player_shoot": "LMB",
			"weapon_reload": "R",
			"weapon_cycle": "Q",
			"weapon_primary": "1",
			"weapon_secondary": "2",
		},
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
