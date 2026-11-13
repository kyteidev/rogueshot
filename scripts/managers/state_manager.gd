extends Node

enum PlayerStatus {
	OVERWEIGHT,
}

# player stats
var health := 100.0
var max_health := 100.0
var enemy_damage := 0.0

var damage := 0.0
var ammo: int = 0
var max_ammo: int = 0
var mags: int = 0

var reloading := false
var weapon_index: int = -1

var lost_health := false

var stamina := 100.0
var stamina_depleted := false
var used_stamina := false

var inventory_weight := 0.0
var max_weight := 25.0

var active_statuses: Array[PlayerStatus] = []

# input lock
var input_locks := { }


func set_input_lock(origin: String, enabled: bool) -> void:
	if enabled:
		input_locks[origin] = true
	else:
		input_locks.erase(origin)


func is_input_locked() -> bool:
	return not input_locks.is_empty()


func update_inventory_weight() -> void:
	inventory_weight = 0.0
	for item in ItemManager.inventory_items:
		inventory_weight += (item.weight * item.count + item.container_weight)
