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
	MAGAZINE,
	AMMO,
}

enum Capability {
	EQUIP = 1 << 0,
	UNLOAD = 1 << 1,
	SPLIT = 1 << 2,
	DROP = 1 << 3,
}

const CAPABILITIES = {
	ItemType.DEFAULT: Capability.DROP,
	ItemType.PRIMARY_WEAPON: Capability.EQUIP | Capability.UNLOAD | Capability.DROP,
	ItemType.SECONDARY_WEAPON: Capability.EQUIP | Capability.UNLOAD | Capability.DROP,
	ItemType.HELMET: Capability.EQUIP | Capability.DROP,
	ItemType.ARMOR: Capability.EQUIP | Capability.DROP,
	ItemType.BACKPACK: Capability.EQUIP | Capability.DROP,
	ItemType.MELEE: Capability.EQUIP | Capability.DROP,
	ItemType.GRENADE: Capability.EQUIP | Capability.DROP,
	ItemType.GOGGLES: Capability.EQUIP | Capability.DROP,
	ItemType.MAGAZINE: Capability.UNLOAD | Capability.DROP,
	ItemType.AMMO: Capability.SPLIT | Capability.DROP,
}

# basic info
@export var id: StringName
@export var name := "":
	set(value):
		name = value
		if tooltip_name == "":
			tooltip_name = value
@export var tooltip_name := ""
@export_multiline var description: String
@export var type := ItemType.DEFAULT
@export var type_data: ItemTypeData # type specific data
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

# container
@export var container := false
@export var container_load_time := 0.0
@export var container_item_type: ItemType
@export var container_max_size: int = 0
@export var container_items: Array[ItemData]
