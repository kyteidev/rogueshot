extends Control

var sm := StateManager

@onready var weapon_texture: TextureRect = %WeaponTexture
@onready var weapon_name_label: Label = %WeaponNameLabel

@onready var equipment_layout: TextureRect = %EquipmentLayout
@onready var equipment_container: Control = %EquipmentContainer


func _ready() -> void:
	visible = false
	equipment_layout.visible = true
	equipment_container.visible = true


func show_weapon_info(weapon: ItemData) -> void:
	sm.weapon_info_shown = true

	visible = true
	equipment_layout.visible = false
	equipment_container.visible = false

	weapon_texture.texture = weapon.icon
	weapon_name_label.text = weapon.name


func hide_weapon_info() -> void:
	sm.weapon_info_shown = false

	visible = false
	equipment_layout.visible = true
	equipment_container.visible = true


func _on_back_button_pressed() -> void:
	hide_weapon_info()
