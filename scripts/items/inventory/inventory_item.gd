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
var prev_pos: Vector2

@onready var icon: TextureRect = $Icon
@onready var bg: ColorRect = $Background
@onready var item_label: Label = $ItemName/Label
@onready var count_label: Label = $ItemCount/Label


func _process(_delta: float) -> void:
	# update item count label
	count_label.text = str(data.count) if data.max_stack > 1 else ""

	# check mouse hover
	if mouse_has_entered:
		var mouse_pos: Vector2 = get_global_mouse_position()
		if (
			mouse_pos.x >= global_position.x and mouse_pos.y >= global_position.y
			and mouse_pos.x <= global_position.x + size.x
			and mouse_pos.y <= global_position.y + size.y
		):
			mouse_hovered = true
			im.hovered_item = self
			if not im.context_menu_open:
				im.context_menu_item = data
		else:
			mouse_hovered = false
			if im.hovered_item and im.hovered_item.data == data:
				im.hovered_item = null

	if mouse_dragging:
		global_position = get_global_mouse_position() - mouse_offset

	if not im.context_menu_open:
		bg.modulate = (
			Color(1.5, 1.5, 1.5, 0.784)
			if im.hovered_item and im.hovered_item.data == data
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

					if data in im.equipped_items.values():
						im.unequip_item(im.equipped_items.find_key(data))
				else:
					if im.in_bounds(slot, data.size):
						if data in im.equipped_items.values():
							global_position = prev_pos
						else:
							position = im.slot_to_pos(prev_slot)
					elif im.hovered_equipment != "":
						equip_item()
					else:
						var equipped_slot: Variant = im.equipped_items.find_key(data)
						if equipped_slot:
							im.unequip_item(equipped_slot)
						im.drop_item(data)

		# check if item rotation key pressed
		if mouse_dragging and Input.is_action_just_pressed("ui_rotate_item"):
			_rotate()


func setup(item_data: ItemData) -> void:
	data = item_data
	custom_minimum_size = data.size * im.SLOT_SIZE
	size = custom_minimum_size
	icon.texture = data.icon
	item_label.text = data.name
	position = im.slot_to_pos(data.slot)


func equip_item() -> void:
	if data.rotated:
		_rotate()

	var old_slot: Variant = im.equipped_items.find_key(data)
	if old_slot != null:
		im.unequip_item(old_slot)
	im.remove_item(data, false)

	var correct_equipment_slot: String
	if not im.hovered_equipment:
		var equipment_container: Control = get_tree().get_first_node_in_group(
			"unique_inventory_equipment"
		)
		for child in equipment_container.get_children():
			if (
				im.hovered_item
				and im.hovered_item.data.type == equipment_container.SLOT_TYPES[child.name]
			):
				correct_equipment_slot = child.name
	else:
		correct_equipment_slot = im.hovered_equipment
	var equipment_slot_data: Dictionary = im.equipment_bounds[correct_equipment_slot]
	var equipment_slot_pos: Vector2 = equipment_slot_data["pos"]
	var equipment_slot_size: Vector2 = equipment_slot_data["size"]
	global_position.x = equipment_slot_pos.x + (equipment_slot_size.x - size.x) / 2
	global_position.y = equipment_slot_pos.y

	bg.modulate.a = 0.0

	im.equip_item(correct_equipment_slot, data)

	prev_pos = global_position


func unequip_item() -> void:
	im.remove_item(data)
	im.add_item(data)


func _rotate() -> void:
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


func _on_mouse_entered() -> void:
	mouse_has_entered = true
