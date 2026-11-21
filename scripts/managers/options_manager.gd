extends Node

enum Category {
	GAMEPLAY,
	VIDEO,
	AUDIO,
	CONTROLS,
}

var camera_shake := true
var particles := true

var options: Array


func _ready() -> void:
	# default options
	# layer 0: tab type as index
	# 		-> 0: gameplay, 1: video, 2: audio, 3: controls
	# layer 1: options
	options = [
		{ "camera_shake": camera_shake, "particles": particles },
		{ "lorem ipsum": false },
		{ "lorem ipsum": false },
		# keybinds are managed independently in option_keybind_button.gd
		# this is for displaying the keybind in options menu
		{
			"player_left": "A",
			"player_right": "D",
			"player_jump": "W",
			"player_sprint": "Shift",
			"player_facing_lock": "Z",
			"player_interact": "F",
			"ui_inventory": "E",
			"ui_rotate_item": "R",
			"player_shoot": "LMB",
			"player_aim": "RMB",
			"weapon_reload": "R",
			"weapon_cycle": "Q",
			"weapon_primary": "1",
			"weapon_secondary": "2",
		},
	]

	# load options from file
	# setting default values initializes all the fields
	SaveManager.load_settings()

	# set keybinds
	var keybinds: Dictionary = options[Category.CONTROLS]
	for control: String in keybinds.keys():
		InputMap.action_erase_events(control)

		var keybind: String = keybinds[control]
		match keybind:
			"LMB":
				keybind = "MOUSE_BUTTON_LEFT"
			"RMB":
				keybind = "MOUSE_BUTTON_RIGHT"
			"MMB":
				keybind = "MOUSE_BUTTON_MIDDLE"

		var keycode: Key = OS.find_keycode_from_string(keybind)
		var input_key := InputEventKey.new()
		input_key.physical_keycode = keycode

		InputMap.action_add_event(control, input_key)


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
