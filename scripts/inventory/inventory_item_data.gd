class_name InventoryItemData
extends ItemData

@export var size := Vector2i.ONE:
	get():
		return Vector2i(size.y, size.x) if rotated else size

@export var slot := Vector2i(-1, -1)
@export var rotated := false
