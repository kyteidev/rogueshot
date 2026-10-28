class_name InventoryItem
extends Panel

var im := InventoryManager
var data: ItemData

var mouse_offset: Vector2
var mouse_hovered: bool
var mouse_dragging: bool

var saved_vars := false
var prev_slot: Vector2

@onready var icon: TextureRect = $Icon


func _process(_delta: float) -> void:
	if mouse_dragging:
		global_position = get_global_mouse_position() - mouse_offset


func _input(event: InputEvent) -> void:
	if mouse_hovered:
		# ignore if isn't left mouse button
		if event is InputEventMouseButton and event.button_index == 1:
			if event.is_pressed():
				if not saved_vars:
					prev_slot = im.pos_to_slot(position)
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
				var slot: Vector2i = im.pos_to_slot(center_position)

				var new_position: Vector2 = im.slot_to_pos(slot)

				# update inventory
				if im.place_item(data, slot):
					position = new_position
				else:
					position = im.slot_to_pos(prev_slot)

		# check if item rotation key pressed
		if Input.is_action_just_pressed("ui_rotate_item"):
			var old_size: Vector2 = im.slot_to_pos(data.size)
			data.rotated = not data.rotated

			custom_minimum_size = im.slot_to_pos(data.size)
			size = custom_minimum_size

			# icon size gets changed when setting InventoryItem size,
			# set icon size to value before rotation so it rotates properly
			icon.size = old_size
			icon.pivot_offset = old_size / 2
			icon.position = (size - old_size) / 2
			icon.rotation = PI / 2 if data.rotated else 0.0

			mouse_offset = size / 2


func setup(item_data: ItemData) -> void:
	data = item_data.duplicate(true)
	custom_minimum_size = data.size * im.SLOT_SIZE
	size = custom_minimum_size
	icon.texture = data.icon
	position = im.slot_to_pos(data.slot)


func _on_mouse_entered() -> void:
	mouse_hovered = true


func _on_mouse_exited() -> void:
	mouse_hovered = false
