extends ColorRect

var im := ItemManager
@onready var items_container: Control = $"../ItemsContainer"


func _ready() -> void:
	visible = false


func _physics_process(_delta: float) -> void:
	if not im.dragging_item or not im.dragged_item:
		return

	var item_center_position: Vector2 = im.dragged_item.position + Vector2.ONE * im.SLOT_SIZE / 2
	var item_slot: Vector2 = im.pos_to_slot(item_center_position)
	var item_pos: Vector2 = im.slot_to_pos(item_slot)
	if im.can_place(im.dragged_item.data, item_slot):
		visible = true
		size = im.dragged_item.data.size * im.SLOT_SIZE
		global_position = items_container.global_position + item_pos
	else:
		visible = false
		size = Vector2.ZERO
