class_name WeaponData
extends ItemTypeData

enum Weapon {
	PISTOL,
	RIFLE1,
}

const WEAPON_STATS = {
	Weapon.PISTOL: {
		"scene_path": "res://scenes/weapons/types/pistol.tscn",
		"damage": 25,
		"caliber": AmmoData.Caliber.NINE_MM,
		"fire_rate": 0.0,
		"mag_size": 13,
		"total_mags": 5,
		"kick": 5.0,
		"kick_recovery": 60.0,
		"spread": 3.0,
		"max_spread": 8.0,
		"spread_recovery": 8.0,
		"reload_time": 0.9,
		"camera_shake": 1.0,
		"heat": 0.18,
		"cooling_rate": 1.04,
		"speed_multiplier": 1.0,
	},
	Weapon.RIFLE1: {
		"scene_path": "res://scenes/weapons/types/rifle_1.tscn",
		"damage": 15,
		"caliber": AmmoData.Caliber.FIVE_FIVE_SIX,
		"fire_rate": 0.1,
		"mag_size": 30,
		"total_mags": 4,
		"kick": 3.0,
		"kick_recovery": 40.0,
		"spread": 1.2,
		"max_spread": 7.0,
		"spread_recovery": 5.0,
		"reload_time": 2.6,
		"camera_shake": 0.5,
		"heat": 0.22,
		"cooling_rate": 0.87,
		"speed_multiplier": 0.9,
	},
}

@export var weapon_name: String:
	set(value):
		weapon_name = value
		_apply_values()
@export var mag_attached := false
@export var round_chambered := false
@export var total_ammo: int:
	set(value):
		total_ammo = value
		# SET AMMO COUNT IN MAG TO BE value - 1 if round_chambered else 0

# WEAPON STATS
var damage: int
var caliber: int
var fire_rate: float
var mag_size: int
var kick: float
var kick_recovery: float
var spread: float
var max_spread: float
var spread_recovery: float
var reload_time: float
var camera_shake: float
var heat: float
var cooling_rate: float
var speed_multiplier: float
var weapon_scene: PackedScene


func _apply_values() -> void:
	if not weapon_name in WEAPON_STATS:
		return

	var stats: Dictionary = WEAPON_STATS[weapon_name]
	weapon_scene = load(stats.scene_path)

	damage = stats.damage
	caliber = stats.caliber
	fire_rate = stats.fire_rate
	mag_size = stats.mag_size

	kick = stats.kick
	kick_recovery = stats.kick_recovery
	spread = stats.spread
	max_spread = stats.max_spread
	spread_recovery = stats.spread_recovery

	reload_time = stats.reload_time

	camera_shake = stats.camera_shake

	heat = stats.heat
	cooling_rate = stats.cooling_rate

	speed_multiplier = stats.speed_multiplier
