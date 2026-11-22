class_name AttachmentData
extends ItemTypeData

enum AttachmentType {
	OPTIC,
	MUZZLE,
	GRIP,
	STOCK,
	TACTICAL,
}

@export var type: AttachmentType
@export var type_data: AttachmentTypeData
@export var compatible: Array[WeaponData.Weapon]
