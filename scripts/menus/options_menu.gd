extends Control


@onready var tabs_container := $TabsContainer
@onready var tab_view_container := $TabViewContainer

var current_tab_index: int = 0


func _on_tab_pressed() -> void:
	# get current tab index
	var tabs := tabs_container.get_children()
	for index in range(tabs.size()):
		if tabs[index].button_pressed:
			current_tab_index = index
		
	# show correct tab view
	var views := tab_view_container.get_children()
	for index in range(views.size()):
		views[index].visible = current_tab_index == index


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
