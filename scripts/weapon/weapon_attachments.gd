class_name WeaponAttachments
extends Resource

enum AttachmentType {
	OPTIC,
	MUZZLE,
	GRIP,
	STOCK,
	TACTICAL,
}

@export var optic: ItemData
@export var muzzle: ItemData
@export var grip: ItemData
@export var stock: ItemData
@export var tactical: ItemData
