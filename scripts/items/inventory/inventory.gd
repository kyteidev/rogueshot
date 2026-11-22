extends CanvasLayer

const ITEM_SCENE = preload("res://scenes/inventory/inventory_item.tscn")
const SLOT_TEXTURE = preload("res://assets/sprites/ui/inventory/inventory-slot.png")

const SLOT_SIZE = 24.0

@export var reticle: Node2D
@export var starting_items: Array[ItemData]

var sm := StateManager
var im := ItemManager

@onready var slots_container: GridContainer = $InventoryContainer/SlotsContainer
@onready var items_container: Control = $InventoryContainer/ItemsContainer
@onready var context_menu: Control = $ContextMenu

@onready var weight_label: Label = $InventoryContainer/WeightLabel


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

	# clear inventory
	im.reset_inventory()

	# place starting items
	for item in starting_items:
		im.add_item(item.duplicate(true))


func _process(_delta: float) -> void:
	weight_label.text = "[%s/%skg]" % [sm.inventory_weight, sm.max_weight]
	var weight_percent: float = sm.inventory_weight / sm.max_weight
	var weight_label_color: Color
	if weight_percent >= 1.0:
		weight_label_color = Color("#ff2e8a")
	elif weight_percent >= 0.5:
		weight_label_color = Color("#ffb49e")
	else:
		weight_label_color = Color("#3cffae")
	weight_label.modulate = weight_label_color


func _input(_event: InputEvent) -> void:
	if (
		Input.is_action_just_pressed("ui_inventory")
		or (visible and Input.is_action_just_pressed("ui_cancel"))
	):
		toggle_inventory()


func toggle_inventory() -> void:
	# toggle between mouse cursor and reticle
	visible = not visible
	sm.inventory_open = visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_HIDDEN
	context_menu.process_mode = Node.PROCESS_MODE_INHERIT if visible else Node.PROCESS_MODE_DISABLED

	# move cursor to reticle after exiting
	if reticle.position != get_viewport().get_mouse_position():
		get_viewport().warp_mouse(reticle.get_global_transform_with_canvas().get_origin())

	reticle.cancel_reload()

	sm.set_input_lock("inventory", visible)


func _new_item_placed(item_data: ItemData) -> void:
	var item := ITEM_SCENE.instantiate() as InventoryItem
	items_container.add_child(item)

	item.setup(item_data)
