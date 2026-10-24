extends Control

var current_tab_index: int = 0

var om := OptionsManager

@onready var tab_buttons_container: VBoxContainer = $TabButtonsContainer
@onready var tabs_container: MarginContainer = $TabsContainer
@onready var tab_buttons: Array[Node] = tab_buttons_container.get_children()
@onready var tabs: Array[Node] = tabs_container.get_children()


func _ready() -> void:
	for tab_index in range(tabs.size()):
		# might be a bad practice to use two get_child() lol
		var options_container: VBoxContainer = tabs[tab_index].get_child(0).get_child(0)
		var options: Array[Node] = options_container.get_children()
		for option_index in range(options.size()):
			# get the button/slider or something of the setting
			# then get value of the setting from options manager
			var control: Control = options[option_index].get_child(1)
			var value: Variant = om.options[tab_index].values()[option_index]

			# each type of value should have one ui element for it
			match typeof(value):
				TYPE_BOOL:
					control.button_pressed = value
				TYPE_STRING:
					control.text = value


func _on_tab_pressed() -> void:
	# get current tab index
	for index in range(tab_buttons.size()):
		if tab_buttons[index].button_pressed:
			current_tab_index = index

	# show correct tab view
	for index in range(tabs.size()):
		tabs[index].visible = current_tab_index == index


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
