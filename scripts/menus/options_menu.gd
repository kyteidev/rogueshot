extends Control


@onready var tab_buttons_container := $TabButtonsContainer
@onready var tabs_container := $TabsContainer
@onready var tab_buttons := tab_buttons_container.get_children()
@onready var tabs := tabs_container.get_children()

var current_tab_index: int = 0

var om := OptionsManager


func _ready() -> void:
	for tab_index in range(tabs.size()):
		var options_container := tabs[tab_index].get_child(0)
		var options := options_container.get_children()
		for option_index in range(options.size()):
			var button := options[option_index].get_child(1)
			button.button_pressed = om.get_options()[tab_index].values()[option_index]


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
