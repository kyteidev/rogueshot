extends CanvasLayer

const ITEM_SCENE = preload("res://scenes/inventory/inventory_item.tscn")
const SLOT_TEXTURE = preload("res://assets/sprites/ui/inventory/inventory-slot.png")

const SLOT_SIZE = 24.0

@export var crosshair: CanvasLayer
@export var starting_items: Array[ItemData]

var sm := StateManager
var im := InventoryManager

@onready var cursor: Node2D = crosshair.get_child(0)
@onready var slots_container: GridContainer = $InventoryContainer/SlotsContainer
@onready var items_container: Control = $InventoryContainer/ItemsContainer
@onready var context_menu: Control = $ContextMenu


func _ready() -> void:
	visible = false

	# set up inventory slots rendering
	slots_container.columns = im.TOTAL_COLUMNS

	for index in range(im.TOTAL_SLOTS):
		var slot := TextureRect.new()
		slot.texture = SLOT_TEXTURE
		slot.custom_minimum_size = Vector2.ONE * SLOT_SIZE
		slots_container.add_child(slot)

	# connect signals
	im.new_item_placed.connect(_new_item_placed)

	# place starting items
	for item in starting_items:
		im.add_item(item)


func _input(_event: InputEvent) -> void:
	if (
		Input.is_action_just_pressed("ui_inventory")
		or (visible and Input.is_action_just_pressed("ui_cancel"))
	):
		toggle_inventory()


func toggle_inventory() -> void:
	# toggle between mouse cursor and crosshair
	visible = not visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_HIDDEN
	context_menu.process_mode = Node.PROCESS_MODE_INHERIT if visible else Node.PROCESS_MODE_DISABLED

	# move cursor to crosshair after exiting
	if cursor.position != get_viewport().get_mouse_position():
		get_viewport().warp_mouse(cursor.position)

	crosshair.cancel_reload()

	sm.set_input_lock("inventory", visible)


func _new_item_placed(item_data: ItemData) -> void:
	var item := ITEM_SCENE.instantiate() as InventoryItem
	items_container.add_child(item)

	item.setup(item_data)
