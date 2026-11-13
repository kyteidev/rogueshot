extends PanelContainer

var im := ItemManager

var stat_text := "":
	set(value):
		stat_text = value + "\n"

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var stat_label: Label = $MarginContainer/VBoxContainer/StatLabel
@onready var extra_label: Label = $MarginContainer/VBoxContainer/ExtraLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel


func _ready() -> void:
	visible = false


func show_tooltip(data: ItemData) -> void:
	if im.context_menu_open or im.dragging_item:
		return

	name_label.text = data.tooltip_name
	description_label.text = data.description

	stat_text = ""
	stat_text += str(ItemData.ItemType.keys()[data.type]).replace("_", " ").capitalize()
	stat_text += "Weight: %skg" % (data.weight * data.count + data.container_weight)
	stat_label.text = stat_text.strip_edges()

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
