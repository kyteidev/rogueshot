extends Node

signal new_item_placed(item: ItemData)

const SLOT_SIZE = 24
const TOTAL_SLOTS = 44
const TOTAL_COLUMNS = 11
@warning_ignore("integer_division")
const TOTAL_ROWS = TOTAL_SLOTS / TOTAL_COLUMNS

const DROP_OFFSET = 10.0

const ITEM_SCENE = preload("res://scenes/item.tscn")

var inventory := { }
var equipment_bounds := { }

var hovered_item: ItemData
var context_menu_item: ItemData
var context_menu_open := false

var dragging_item := false


# for placing items in inventory: when final position is known
func place_item(item: ItemData, slot: Vector2i) -> bool:
	if not _can_place(item, slot):
		return false

	# clear item's old slots
	for x in item.size.x:
		for y in item.size.y:
			inventory.erase(Vector2i(x, y) + item.slot)

	# update item's slot data and replace slots with item
	item.slot = slot
	for x in item.size.x:
		for y in item.size.y:
			inventory[Vector2i(x, y) + slot] = item

	return true


# for placing items when final position has to be determined
func add_item(item: ItemData) -> bool:
	# find a free slot
	for x in TOTAL_COLUMNS:
		for y in TOTAL_ROWS:
			var possible_slot := Vector2i(x, y)
			# add item and return status
			if place_item(item, possible_slot):
				new_item_placed.emit(item)
				return true

	return false


func remove_item(item: ItemData) -> void:
	for x in item.size.x:
		for y in item.size.y:
			inventory.erase(Vector2i(x, y) + item.slot)

	var inventory_items_container: Control = get_tree().get_first_node_in_group(
		"unique_inventory_items"
	)
	for child in inventory_items_container.get_children():
		if child.data == item:
			child.queue_free()


func spawn_item(item_data: ItemData, position: Vector2) -> void:
	var inst := ITEM_SCENE.instantiate()
	get_tree().current_scene.add_child(inst)
	inst.global_position = position
	inst.setup(item_data)


func drop_item(item_data: ItemData) -> void:
	remove_item(item_data)
	var spawn_pos: Vector2 = get_tree() \
			.get_first_node_in_group("unique_player") \
			.global_position
	spawn_pos += Vector2(
		randf_range(-DROP_OFFSET * 1.5, DROP_OFFSET * 1.5),
		randf_range(-DROP_OFFSET / 2, -DROP_OFFSET),
	)
	spawn_item(item_data, spawn_pos)


func pos_to_slot(pos: Vector2) -> Vector2:
	return floor(pos / SLOT_SIZE)


func slot_to_pos(slot: Vector2) -> Vector2:
	return slot * SLOT_SIZE


func _in_bounds(slot: Vector2i, size: Vector2i) -> bool:
	# check if in bounds of inventory
	return (
		slot.x >= 0 and slot.y >= 0 and slot.x + size.x <= TOTAL_COLUMNS
		and slot.y + size.y <= TOTAL_ROWS
	)


func _can_place(item: ItemData, slot: Vector2i) -> bool:
	if not _in_bounds(slot, item.size):
		return false

	# check if every slot the item occupies is free
	for x in item.size.x:
		for y in item.size.y:
			var occupant: ItemData = inventory.get(slot + Vector2i(x, y))
			if occupant != null and occupant != item:
				return false

	return true
