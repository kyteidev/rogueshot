extends PanelContainer

var im := ItemManager

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var type_label: Label = $MarginContainer/VBoxContainer/TypeLabel
@onready var extra_label: Label = $MarginContainer/VBoxContainer/ExtraLabel


func _ready() -> void:
	visible = false


func show_tooltip(data: ItemData) -> void:
	if im.context_menu_open or im.dragging_item:
		return

	name_label.text = data.tooltip_name
	type_label.text = str(ItemData.ItemType.keys()[data.type]).replace("_", " ").capitalize()

	extra_label.visible = true
	var type_data: ItemTypeData = data.type_data
	if type_data is WeaponData or type_data is MagData:
		extra_label.text = "Caliber: %s" % str(Helper.caliber_string[type_data.caliber])
	else:
		extra_label.visible = false

	visible = true
	reset_size()


func hide_tooltip() -> void:
	visible = false
	extra_label.visible = false
