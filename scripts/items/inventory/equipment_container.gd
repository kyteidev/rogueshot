extends Control

var im := ItemManager


func _ready() -> void:
	# retrieve and save bounds of equipment slots
	if im.equipment_bounds.is_empty():
		for child in get_children():
			im.equipment_bounds[child.name] = { "pos": child.global_position, "size": child.size }

			var orig_alpha: float = child.modulate.a
			child.modulate.a = 0.0

			child.mouse_entered.connect(
				func() -> void:
					if im.dragging_item:
						child.modulate.a = orig_alpha,
			)
			child.mouse_exited.connect(
				func() -> void:
					if im.dragging_item:
						child.modulate.a = 0.0,
			)
