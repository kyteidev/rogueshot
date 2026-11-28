extends Node

signal new_item_placed(item: ItemData)
signal weapon_unequipped
@warning_ignore("unused_signal") # used in other places
signal item_loaded
@warning_ignore("unused_signal") # used in other places
signal item_unloaded(item: ItemData)
@warning_ignore("unused_signal")
signal item_picked_up
signal item_dropped

@warning_ignore("unused_signal")
signal mag_loaded # only used when dragging mag to weapon in inventory
@warning_ignore("unused_signal")
signal attachment_loaded
@warning_ignore("unused_signal")
signal attachment_unloaded

const SLOT_SIZE = 24
const TOTAL_SLOTS = 44
const TOTAL_COLUMNS = 11
@warning_ignore("integer_division")
const TOTAL_ROWS = TOTAL_SLOTS / TOTAL_COLUMNS

const DROP_OFFSET = 10.0
const DROP_RAND_ROT = 0.6

const ITEM_SCENE = preload("res://scenes/item.tscn")

var inventory: Dictionary[Vector2i, ItemData] = { } # { Slot pos: ItemData }
var inventory_items: Array[ItemData] = [] # just an array of items in inventory
var equipped_items: Dictionary[String, ItemData] = { } # { "Equipment slot": ItemData }
var equipment_bounds: Dictionary[String, Dictionary] = { }

var equipped_weapons: Array[ItemData] = [null, null]
var weapon_index: int = -1

var hovered_item: InventoryItem
var dragged_item: InventoryItem
var context_menu_item: InventoryItem
var context_menu_open := false

var dragging_item := false
var hovered_equipment := ""

var hovering_valid_container := false

var sm := StateManager
var rng := Random.rng


# for placing items in inventory: when final position is known
func place_item(item: ItemData, slot: Vector2i) -> bool:
	if not can_place(item, slot):
		return false

	# clear item's old slots
	_clear_item(item)

	# update item's slot data and replace slots with item
	item.slot = slot
	for x in item.size.x:
		for y in item.size.y:
			inventory[Vector2i(x, y) + slot] = item

	inventory_items.append(item)
	sm.update_inventory_weight()
	return true


# for placing items when final position has to be determined
func add_item(item: ItemData, duplicate_item := true, combine_items := true) -> bool:
	# find a free slot
	var new_item: ItemData = item.duplicate() if duplicate_item else item

	if combine_items:
		for existing_item in inventory_items:
			if new_item.id != existing_item.id or existing_item.count == existing_item.max_stack:
				continue

			var new_count: int = new_item.count + existing_item.count
			if new_count > existing_item.max_stack:
				new_item.count = new_count - existing_item.max_stack
				existing_item.count = existing_item.max_stack
			else:
				existing_item.count = new_count
				return true

	for x in TOTAL_COLUMNS:
		for y in TOTAL_ROWS:
			var possible_slot := Vector2i(x, y)
			# add item and return status
			if place_item(new_item, possible_slot):
				new_item_placed.emit(new_item)
				return true

	drop_item(new_item)
	return false


func remove_item(item: ItemData, destroy_item := true) -> void:
	_clear_item(item)

	var inventory_items_container: Control = get_tree().get_first_node_in_group(
		"unique_inventory_items"
	)
	if destroy_item:
		for child in inventory_items_container.get_children():
			if child.data == item:
				child.exists = false
				child.queue_free()

	var equipped_slot: Variant = equipped_items.find_key(item)
	if equipped_slot:
		unequip_item(equipped_slot)


func spawn_item(item_data: ItemData, position: Vector2) -> void:
	var inst := ITEM_SCENE.instantiate()
	get_tree().current_scene.add_child(inst)
	inst.global_position = position
	inst.global_rotation += rng.randf_range(-DROP_RAND_ROT, DROP_RAND_ROT)
	inst.setup(item_data)


func drop_item(item_data: ItemData, from_player := true, pos := Vector2.ZERO) -> void:
	var spawn_pos: Vector2

	if from_player:
		remove_item(item_data)
		spawn_pos = get_tree() \
				.get_first_node_in_group("unique_player") \
				.global_position
		spawn_pos += Vector2(
			rng.randf_range(-DROP_OFFSET * 1.5, DROP_OFFSET * 1.5),
			rng.randf_range(-DROP_OFFSET / 2, -DROP_OFFSET),
		)
	else:
		spawn_pos = pos
	spawn_item(item_data, spawn_pos)
	item_dropped.emit()


func equip_item(equipment_slot: String, item: ItemData) -> bool:
	if equipment_slot in equipped_items:
		return false

	equipped_items[equipment_slot] = item

	if equipment_slot == "Primary":
		equipped_weapons[0] = item
	elif equipment_slot == "Secondary":
		equipped_weapons[1] = item

	return true


func unequip_item(equipment_slot: String) -> void:
	equipped_items.erase(equipment_slot)

	if equipment_slot == "Primary":
		equipped_weapons[0] = null
		weapon_unequipped.emit()
	elif equipment_slot == "Secondary":
		equipped_weapons[1] = null
		weapon_unequipped.emit()


func find_free_slot(item: ItemData) -> Vector2i:
	for x in TOTAL_COLUMNS:
		for y in TOTAL_ROWS:
			var possible_slot := Vector2i(x, y)
			if can_place(item, possible_slot):
				return possible_slot
	return Vector2i(-1, -1)


func reset_inventory() -> void:
	inventory = { }
	inventory_items.clear()
	equipped_items = { }
	equipped_weapons = [null, null]

	hovered_item = null
	dragged_item = null
	context_menu_item = null
	context_menu_open = false
	dragging_item = false
	hovered_equipment = ""
	hovering_valid_container = false

	weapon_index = -1

	var inventory_items_container: Control = get_tree().get_first_node_in_group(
		"unique_inventory_items"
	)
	for child in inventory_items_container.get_children():
		child.queue_free()


func pos_to_slot(pos: Vector2) -> Vector2:
	return floor(pos / SLOT_SIZE)


func slot_to_pos(slot: Vector2) -> Vector2:
	return slot * SLOT_SIZE


func in_bounds(slot: Vector2i, size: Vector2i) -> bool:
	# check if in bounds of inventory
	return (
		slot.x >= 0 and slot.y >= 0 and slot.x + size.x <= TOTAL_COLUMNS
		and slot.y + size.y <= TOTAL_ROWS
	)


func can_place(item: ItemData, slot: Vector2i) -> bool:
	if not in_bounds(slot, item.size):
		return false

	# check if every slot the item occupies is free
	for x in item.size.x:
		for y in item.size.y:
			var occupant: ItemData = inventory.get(slot + Vector2i(x, y))
			if occupant != null and occupant != item:
				return false
	return true


func _clear_item(item: ItemData) -> void:
	for key: Vector2i in inventory.keys():
		if inventory[key] == item:
			inventory.erase(key)

	var index: int = inventory_items.find(item)
	if index != -1:
		inventory_items.pop_at(index)
		sm.update_inventory_weight()
