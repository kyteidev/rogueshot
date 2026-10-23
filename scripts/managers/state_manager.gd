extends Node


# player stats
var health: float = 100.0
var max_health: float = 100.0
var enemy_damage: float = 0.0

var damage: float = 0.0
var ammo: int = 0
var max_ammo: int = 0
var mags: int = 0

var reloading: bool = false

var lost_health: bool = false

var stamina: float = 100.0
var stamina_depleted: bool = false
var used_stamina: bool = false

# input lock
var input_locks: Dictionary = {}


func set_input_lock(origin: String, enabled: bool) -> void:
	if enabled:
		input_locks[origin] = true
	else:
		input_locks.erase(origin)


func is_input_locked() -> bool:
	return not input_locks.is_empty()
