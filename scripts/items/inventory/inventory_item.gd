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

		var update := (func() -> void:
			im.dragged_item = self if value else null
		)
		update.call_deferred()

var saved_vars := false
var prev_slot: Vector2
var prev_pos: Vector2

var prev_hovered_item: InventoryItem

var drop_target := false

var exists := true
var pos_set := false

@onready var inventory: CanvasLayer = get_node("../../../")
@onready var tooltip: PanelContainer = inventory.get_node("./Tooltip")

@onready var icon: TextureRect = $Icon
@onready var bg: ColorRect = $Background
@onready var item_label: Label = $ItemName/Label
@onready var count_label: Label = $ItemCount/Label
@onready var container_label: Label = $ContainerCount/Label
@onready var tooltip_timer: Timer = $Timer


func _process(_delta: float) -> void:
	# update count labels
	count_label.text = str(data.count) if data.max_stack > 1 else ""

	var container_text := ""
	if data.container:
		if (
			data.type == ItemData.ItemType.PRIMARY_WEAPON
			or data.type == ItemData.ItemType.SECONDARY_WEAPON
		):
			if (data.container_items.size() > 0):
				if data.container_items[0].container_items.size() == 0:
					container_text = "0"
				else:
					var ammo: int = data.container_items[0].container_items[0].count
					container_text = str(ammo)

					# also update ammo count
					data.type_data.total_ammo = ammo
		elif data.container_max_size > 1:
			var count: int = 0
			for item in data.container_items:
				count += item.count
			container_text = str(count)
	container_label.text = container_text

	# check mouse hover
	var mouse_pos: Vector2 = get_global_mouse_position()
	if (
		mouse_pos.x >= global_position.x and mouse_pos.y >= global_position.y
		and mouse_pos.x <= global_position.x + size.x and mouse_pos.y <= global_position.y + size.y
	):
		mouse_hovered = true

		if not im.dragged_item or im.dragged_item == self:
			im.hovered_item = self
			if not im.context_menu_open:
				im.context_menu_item = self

		# tooltip timer stuff idk
		if tooltip_timer.time_left == 0.0:
			tooltip_timer.start()
	else:
		mouse_hovered = false

		if im.hovered_item and im.hovered_item.data == data:
			im.hovered_item = null

		tooltip_timer.stop()
		if im.hovered_item != prev_hovered_item:
			tooltip.hide_tooltip()

			prev_hovered_item = im.hovered_item

	if mouse_hovered and mouse_dragging:
		pos_set = false
		global_position = get_global_mouse_position() - mouse_offset
	elif not pos_set:
		_release_item()
		pos_set = true

	if not im.context_menu_open:
		bg.modulate = (
			Color(1.5, 1.5, 1.5, 0.784)
			if (im.hovered_item and im.hovered_item.data == data)
			or (
				mouse_hovered and data.container and im.dragged_item != null
				and im.dragged_item != self
				and im.dragged_item.data.type == data.container_item_type
			)
			and _check_compatibility()
			else Color(1.0, 1.0, 1.0)
		)


func _input(event: InputEvent) -> void:
	if mouse_hovered and not im.context_menu_open:
		# ignore if isn't left mouse button
		if event is InputEventMouseButton and event.button_index == 1:
			# dragging item to container logic
			if (
				data.container and im.dragged_item and im.dragged_item != self
				and im.dragged_item.data.type == data.container_item_type
			):
				# weapon compatibility check for magazines
				if not _check_compatibility():
					return

				var present := false
				var overflow := false
				for item in data.container_items:
					if item.type == im.dragged_item.data.type:
						var count: int = 0
						for item2 in data.container_items:
							count += item2.count

						if count + im.dragged_item.data.count > data.container_max_size:
							im.dragged_item.data.count -= data.container_max_size - count
							item.count += data.container_max_size - count
							overflow = true
						else:
							item.count += im.dragged_item.data.count
						present = true

				if not present:
					var item_data: ItemData = im.dragged_item.data
					var count: int = 0
					for item2 in data.container_items:
						count += item2.count

					if count + item_data.count > data.container_max_size:
						item_data.count -= data.container_max_size
						item_data = im.dragged_item.data.duplicate(true)
						item_data.count = data.container_max_size
						overflow = true
					data.container_items.append(item_data)

				if not overflow:
					im.remove_item(im.dragged_item.data)

				im.item_loaded.emit()

			# item drag and drop handling
			elif not im.dragged_item or im.dragged_item == self:
				if event.is_pressed():
					if not saved_vars:
						prev_slot = im.pos_to_slot(position)
						saved_vars = true
					mouse_dragging = true
					mouse_offset = get_global_mouse_position() - global_position
					move_to_front()

					tooltip.hide_tooltip()
				elif event.is_released():
					_release_item()

		# check if item rotation key pressed
		if (
			mouse_dragging and im.dragged_item == self
			and Input.is_action_just_pressed("ui_rotate_item")
		):
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


func unload_items() -> void:
	for item in data.container_items:
		im.add_item(item)
	data.container_items.clear()


func split_stack() -> void:
	if data.count <= 1:
		return

	var new_item_data: ItemData = data.duplicate(true)
	@warning_ignore("integer_division")
	new_item_data.count = floori(new_item_data.count / 2)
	data.count -= new_item_data.count

	im.add_item(new_item_data)


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


func _check_compatibility() -> bool:
	var item_type: ItemData.ItemType = im.dragged_item.data.type
	var types := ItemData.ItemType

	match item_type:
		types.MAGAZINE:
			if im.dragged_item.data.type_data.compatible != data.type_data.weapon:
				return false
		types.AMMO:
			if im.dragged_item.data.type_data.type != data.type_data.caliber:
				return false
	return true


func _release_item() -> void:
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
			await get_tree().process_frame

			if exists:
				var equipped_slot: Variant = im.equipped_items.find_key(data)
				if equipped_slot:
					im.unequip_item(equipped_slot)

				im.drop_item(data)


func _on_tooltip_timer_timeout() -> void:
	if tooltip.visible:
		return

	var mouse_pos: Vector2 = get_global_mouse_position()
	tooltip.global_position = mouse_pos
	tooltip.move_to_front()
	tooltip.show_tooltip(data)
