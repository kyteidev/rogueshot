class_name InventoryItemData
extends Resource

@export var id: StringName
@export var name := ""
@export var icon: Texture2D
@export var size := Vector2.ONE
@export var max_stack: int = 1

var slot := Vector2(0, 0)
var count: int = 1
