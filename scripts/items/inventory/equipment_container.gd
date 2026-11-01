extends Control

const SLOT_TYPES := {
	"Primary": ItemData.ItemType.PRIMARY_WEAPON,
	"Secondary": ItemData.ItemType.SECONDARY_WEAPON,
	"Helmet": ItemData.ItemType.HELMET,
	"Armor": ItemData.ItemType.ARMOR,
	"Backpack": ItemData.ItemType.BACKPACK,
	"Knife": ItemData.ItemType.MELEE,
	"Grenade1": ItemData.ItemType.GRENADE,
	"Grenade2": ItemData.ItemType.GRENADE,
	"Goggles": ItemData.ItemType.GOGGLES,
}

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
					if im.dragging_item and im.hovered_item.type == SLOT_TYPES[child.name]:
						child.modulate.a = orig_alpha,
			)
			child.mouse_exited.connect(
				func() -> void:
					if im.dragging_item:
						child.modulate.a = 0.0,
			)
