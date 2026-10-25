extends Node

signal new_item_placed(item: InventoryItemData)

const SLOT_SIZE = 24
const TOTAL_SLOTS = 44
const TOTAL_COLUMNS = 11
@warning_ignore("integer_division")
const TOTAL_ROWS = TOTAL_SLOTS / TOTAL_COLUMNS

var inventory := { }


# for placing items in inventory: when final position is known
func place_item(item: InventoryItemData, slot: Vector2i) -> bool:
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
func add_item(item: InventoryItemData) -> bool:
	# find a free slot
	for x in TOTAL_COLUMNS:
		for y in TOTAL_ROWS:
			var possible_slot := Vector2i(x, y)
			# add item and return status
			if place_item(item, possible_slot):
				new_item_placed.emit(item)
				return true

	return false


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


func _can_place(item: InventoryItemData, slot: Vector2i) -> bool:
	if not _in_bounds(slot, item.size):
		return false

	# check if every slot the item occupies is free
	for x in item.size.x:
		for y in item.size.y:
			var occupant: InventoryItemData = inventory.get(slot + Vector2i(x, y))
			if occupant != null and occupant != item:
				return false

	return true
