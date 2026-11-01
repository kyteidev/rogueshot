class_name ItemData
extends Resource

enum ItemType {
	DEFAULT,
	PRIMARY_WEAPON,
	SECONDARY_WEAPON,
	HELMET,
	ARMOR,
	BACKPACK,
	MELEE,
	GRENADE,
	GOGGLES,
}

# basic info
@export var id: StringName
@export var name := ""
@export var type := ItemType.DEFAULT
@export var icon: Texture2D
@export var max_stack: int = 1
@export var count: int = 1

# world
@export var scale := 1.0

# inventory
@export var size := Vector2i.ONE:
	get():
		return Vector2i(size.y, size.x) if rotated else size
@export var slot := Vector2i(-1, -1)
@export var rotated := false
