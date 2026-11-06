extends PanelContainer

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var type_label: Label = $MarginContainer/VBoxContainer/TypeLabel


func _ready() -> void:
	visible = false


func show_tooltip(data: ItemData) -> void:
	name_label.text = data.name
	type_label.text = str(ItemData.ItemType.keys()[data.type]).replace("_", " ").capitalize()

	visible = true


func hide_tooltip() -> void:
	visible = false
