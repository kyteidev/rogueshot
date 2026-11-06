extends PanelContainer

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var type_label: Label = $MarginContainer/VBoxContainer/TypeLabel
@onready var extra_label: Label = $MarginContainer/VBoxContainer/ExtraLabel


func _ready() -> void:
	visible = false


func show_tooltip(data: ItemData) -> void:
	name_label.text = data.name
	type_label.text = str(ItemData.ItemType.keys()[data.type]).replace("_", " ").capitalize()

	visible = true

	extra_label.visible = true
	var type_data: ItemTypeData = data.type_data
	if type_data is WeaponData:
		extra_label.text = "Caliber: %s" % str(Helper.caliber_string[type_data.caliber])
	elif type_data is MagData:
		extra_label.text = "Caliber: %s" % str(Helper.caliber_string[type_data.caliber])
	else:
		extra_label.visible = false


func hide_tooltip() -> void:
	visible = false
