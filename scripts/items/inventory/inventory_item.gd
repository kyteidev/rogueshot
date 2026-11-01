class_name InventoryItem
extends Panel

var im := ItemManager
var data: ItemData

var mouse_offset: Vector2
var mouse_has_entered := false
var mouse_hovered := false
var mouse_dragging := false:
	set(value):
		mouse_dragging = value
		im.dragging_item = value

var saved_vars := false
var prev_slot: Vector2

@onready var icon: TextureRect = $Icon
@onready var bg: ColorRect = $Background


func _process(_delta: float) -> void:
	# check mouse hover
	if mouse_has_entered:
		var mouse_pos: Vector2 = get_global_mouse_position()
		if (
			mouse_pos.x >= global_position.x and mouse_pos.y >= global_position.y
			and mouse_pos.x <= global_position.x + size.x
			and mouse_pos.y <= global_position.y + size.y
		):
			mouse_hovered = true
			im.hovered_item = data
			if not im.context_menu_open:
				im.context_menu_item = data
		else:
			mouse_hovered = false
			im.hovered_item = null

	if mouse_dragging:
		global_position = get_global_mouse_position() - mouse_offset

	if not im.context_menu_open:
		bg.modulate = (
			Color(1.5, 1.5, 1.5, 0.784)
			if im.hovered_item == data
			else Color(1.0, 1.0, 1.0)
		)


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
					if im.in_bounds(slot, data.size):
						position = im.slot_to_pos(prev_slot)
					else:
						im.drop_item(data)

		# check if item rotation key pressed
		if mouse_dragging and Input.is_action_just_pressed("ui_rotate_item"):
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
	data = item_data
	custom_minimum_size = data.size * im.SLOT_SIZE
	size = custom_minimum_size
	icon.texture = data.icon
	position = im.slot_to_pos(data.slot)


func _on_mouse_entered() -> void:
	mouse_has_entered = true
