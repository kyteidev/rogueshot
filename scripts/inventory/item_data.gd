class_name InventoryItemData
extends Resource

@export var id: StringName
@export var name := ""
@export var icon: Texture2D
@export var size := Vector2i.ONE:
	get():
		return Vector2i(size.y, size.x) if rotated else size
@export var max_stack: int = 1

@export var slot := Vector2i(-1, -1)
@export var count: int = 1
@export var rotated := false
