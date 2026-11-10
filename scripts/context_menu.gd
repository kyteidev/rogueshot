extends Control

var menu_size := Vector2.ZERO

var im := ItemManager

@onready var button_scene: PackedScene = preload(
	"res://scenes/context_menu/context_menu_button.tscn"
)

@onready var tooltip: PanelContainer = get_node("../Tooltip")


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		# toggle visibility if RMB pressed
		if event.button_index == 2:
			if not im.hovered_item:
				return

			global_position = get_global_mouse_position()
			visible = not visible
			im.context_menu_open = visible

			if visible:
				var item_type: ItemData.ItemType = im.context_menu_item.data.type
				var item_capabilities: Variant = ItemData.CAPABILITIES.get(item_type)
				if not item_capabilities:
					item_capabilities = ItemData.CAPABILITIES.get(ItemData.ItemType.DEFAULT)
				_load_buttons(item_capabilities)

				tooltip.hide_tooltip()
			else:
				_unload_buttons()
		# hide if LMB pressed
		elif visible and event.button_index == 1:
			# check if mouse is not hovering over context menu
			# mouse entered signal doesnt work???
			var mouse_pos: Vector2 = get_global_mouse_position()
			if not (
				(mouse_pos.x >= global_position.x) and (mouse_pos.y >= global_position.y)
				and (mouse_pos.x <= global_position.x + menu_size.x)
				and (mouse_pos.y <= global_position.y + menu_size.y)
			):
				visible = false
				im.context_menu_open = false
				_unload_buttons()


func _load_buttons(capabilities: int) -> void:
	# load buttons for each menu type
	var button_count: int = 0
	for action_name: String in ItemData.Capability:
		var action: ItemData.Capability = ItemData.Capability[action_name]
		if (capabilities & action) == 0:
			continue

		var button: Button = button_scene.instantiate()
		var button_text: String = action_name.capitalize()
		if button_text == "Equip" and im.context_menu_item.data in im.equipped_items.values():
			button_text = "Unequip"

		button.text = button_text

		add_child(button)
		button.pressed.connect(
			func() -> void:
				_button_functions(button.text),
		)

		button_count += 1

		# calculate size of context menu
		menu_size.x = button.size.x
		menu_size.y = button.size.y * button_count


func _unload_buttons() -> void:
	var buttons: Array[Node] = get_children()
	for button in buttons:
		button.queue_free()

	if im.hovered_item == null:
		im.context_menu_item = null
	im.context_menu_open = false


func _button_functions(button_name: String) -> void:
	if not im.context_menu_item:
		return

	match button_name:
		# idk why i have a separate context_menu_item :sob:
		# this works so im not gonna touch this
		# hovered_item is InventoryItem and context_menu_item is ItemData
		"Equip":
			im.context_menu_item.equip_item()
		"Unequip":
			im.context_menu_item.unequip_item()
		"Unload":
			im.item_unloaded.emit()
			im.context_menu_item.unload_items()
		"Drop":
			im.drop_item(im.context_menu_item.data)

	# hide context menu after action is done
	visible = false
	_unload_buttons()
	im.hovered_item = null
