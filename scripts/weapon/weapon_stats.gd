class_name WeaponStats
extends Resource

@export var damage: int
## Fire rate in seconds. 0.0 is semi-auto
@export var fire_rate: float
@export var mag_size: int
@export var reload_time: float
@export var ads_time: float
## Effective range, in pixels
@export var effective_range: float
## Maximum range, in pixels. Damage won't be dealt after this threshold
@export var max_range: float

## Weapon kick, in pixels
@export var kick: float
## Weapon kick recovery, in pixels per second
@export var kick_recovery: float

## Horizontal recoil, in pixels
@export var horizontal_recoil: float
## Vertical recoil, in pixels
@export var vertical_recoil: float
## Recoil stiffness, in pixels
@export var recoil_stiffness: float
## Recoil damping, in pixels
@export var recoil_damping: float

## Weapon hipfire spread per shot, in degrees
@export var hipfire_spread: float
## Weapon ADS spread per shot, in degrees
@export var ads_spread: float
## Maximum weapon spread during hip fire, in degrees
@export var max_hipfire_spread: float
## Maximum weapon spread when ADS, in degrees
@export var max_ads_spread: float

## Spead recovery, in degrees per second
@export var spread_recovery: float
@export var first_shot_spread_mult: float

@export var camera_shake: float

@export var heat: float
@export var cooling_rate: float

@export var speed_multiplier: float
@export var ads_speed_multiplier: float

@export var jam_chance: float
@export var jam_weight: float
@export var unjam_time: float

@export var compatible_attachments: Array[AttachmentData.AttachmentType]
