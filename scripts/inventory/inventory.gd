extends CanvasLayer


const SLOT_TEXTURE = preload("res://assets/sprites/ui/inventory/inventory-slot.png")

const SLOT_SIZE = 24.0
const TOTAL_SLOTS = 44
const TOTAL_COLUMNS = 11

@export var crosshair: CanvasLayer

var sm := StateManager

@onready var cursor := crosshair.get_child(0)
@onready var slots_container := $InventoryContainer/Slots


func _ready() -> void:
	visible = false
	
	# set up inventory slots rendering
	slots_container.columns = TOTAL_COLUMNS
	
	for index in range(TOTAL_SLOTS):
		var slot := TextureRect.new()
		slot.texture = SLOT_TEXTURE
		slot.custom_minimum_size = Vector2.ONE * SLOT_SIZE
		slots_container.add_child(slot)
	

func toggle_inventory() -> void:
	# toggle between mouse cursor and crosshair
	visible = not visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_HIDDEN
	
	# move cursor to crosshair after exiting
	if cursor.position != get_viewport().get_mouse_position():
		get_viewport().warp_mouse(cursor.position)
	
	# cancel reload
	crosshair.cancel_reload()
	
	# lock/unlock input
	sm.set_input_lock("inventory", visible)


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_inventory") or (visible and Input.is_action_just_pressed("ui_cancel")):
		toggle_inventory()
