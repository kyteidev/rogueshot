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
			print(orig_alpha)
			child.modulate.a = 0.0

			child.mouse_entered.connect(
				func() -> void:
					if (
						im.dragging_item and im.hovered_item
						and im.hovered_item.type == SLOT_TYPES[child.name]
					):
						child.modulate = Color(1.0, 1.0, 1.0, orig_alpha)
						im.hovered_equipment = child.name,
			)
			child.mouse_exited.connect(
				func() -> void:
					if im.dragging_item:
						child.modulate = Color(1.0, 1.0, 1.0, 0.0)
						im.hovered_equipment = "",
			)


func _process(_delta: float) -> void:
	if not im.dragging_item:
		for child in get_children():
			if child.name in im.equipped_items.keys():
				child.modulate = Color("342945")
