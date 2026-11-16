class_name WeaponData
extends ItemTypeData

enum Weapon {
	NONE,
	GL18,
	OZ2,
}

@export var weapon: Weapon
@export var caliber: AmmoData.Caliber
@export var weapon_data: WeaponStats
@export var weapon_scene: PackedScene
@export var loaded_icon: Texture2D
@export var mag_attached := false
@export var round_chambered := false
@export var total_ammo: int:
	set(value):
		total_ammo = value
		# SET AMMO COUNT IN MAG TO BE value - 1 if round_chambered else 0
@export var jammed := false
