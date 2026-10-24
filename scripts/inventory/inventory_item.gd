extends Panel

var im := InventoryManager

var mouse_offset: Vector2
var mouse_hovered: bool
var mouse_dragging: bool

@onready var icon: TextureRect = $Icon


func _process(_delta: float) -> void:
	if mouse_dragging:
		global_position = get_global_mouse_position() - mouse_offset
	# check for mosue hovered to reduce redundant checks for snapping
	elif mouse_hovered:
		# snap to slot
		var center_position: Vector2 = position + Vector2.ONE * im.SLOT_SIZE / 2
		var snapped_position: Vector2 = floor(center_position / im.SLOT_SIZE) * im.SLOT_SIZE
		position = snapped_position


func _input(event: InputEvent) -> void:
	# ignore if isn't left mouse button
	if mouse_hovered and event is InputEventMouseButton and event.button_index == 1:
		if event.is_pressed():
			mouse_dragging = true
			mouse_offset = get_global_mouse_position() - global_position
		elif event.is_released():
			mouse_dragging = false


func _on_mouse_entered() -> void:
	mouse_hovered = true


func _on_mouse_exited() -> void:
	mouse_hovered = false
