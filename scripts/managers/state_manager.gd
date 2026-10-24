extends Node

# player stats
var health := 100.0
var max_health := 100.0
var enemy_damage := 0.0

var damage := 0.0
var ammo: int = 0
var max_ammo: int = 0
var mags: int = 0

var reloading := false

var lost_health := false

var stamina := 100.0
var stamina_depleted := false
var used_stamina := false

# input lock
var input_locks := { }


func set_input_lock(origin: String, enabled: bool) -> void:
	if enabled:
		input_locks[origin] = true
	else:
		input_locks.erase(origin)


func is_input_locked() -> bool:
	return not input_locks.is_empty()
