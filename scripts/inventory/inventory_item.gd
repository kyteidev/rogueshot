class_name InventoryItem
extends Panel

var im := InventoryManager
var data: InventoryItemData

var mouse_offset: Vector2
var mouse_hovered: bool
var mouse_dragging: bool

var saved_vars := false
var prev_position: Vector2

@onready var icon: TextureRect = $Icon


func _process(_delta: float) -> void:
	if mouse_dragging:
		global_position = get_global_mouse_position() - mouse_offset


func _input(event: InputEvent) -> void:
	# ignore if isn't left mouse button
	if mouse_hovered and event is InputEventMouseButton and event.button_index == 1:
		if event.is_pressed():
			if not saved_vars:
				prev_position = im.pos_to_slot(global_position)
				saved_vars = true
			mouse_dragging = true
			mouse_offset = get_global_mouse_position() - global_position

			move_to_front()
		elif event.is_released():
			mouse_dragging = false
			saved_vars = false

			# snap to slot
			# converting to slot and back to pos coords automatically snaps to grid
			var center_position: Vector2 = position + Vector2.ONE * im.SLOT_SIZE / 2
			var slot: Vector2 = im.pos_to_slot(center_position)
			var new_position: Vector2 = im.slot_to_pos(slot)

			# update inventory
			if im.place_item(data, slot):
				position = new_position
			else:
				position = im.slot_to_pos(prev_position)


func setup(item_data: InventoryItemData) -> void:
	data = item_data
	custom_minimum_size = item_data.size * im.SLOT_SIZE
	icon.texture = item_data.icon
	position = im.slot_to_pos(item_data.slot)


func _on_mouse_entered() -> void:
	mouse_hovered = true


func _on_mouse_exited() -> void:
	mouse_hovered = false
