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

const EMPTY_COLOR = Color("ffffff00")
const HOVERED_COLOR = Color("ffffff37")
const EQUIPPED_COLOR = Color("342945")

var im := ItemManager


func _ready() -> void:
	# retrieve and save bounds of equipment slots
	if im.equipment_bounds.is_empty():
		for child in get_children():
			im.equipment_bounds[child.name] = { "pos": child.global_position, "size": child.size }
			child.modulate.a = 0.0


# this code is so fucking bad and unreadble
# future me: dont touch this pls <3
func _process(_delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var hovered := ""

	for child in get_children():
		# looking at this makes my brain hurt :(
		var color: Color = (
			EQUIPPED_COLOR
			if (
				child.name in im.equipped_items.keys()
				and not (
					im.dragging_item and im.hovered_item
					and im.hovered_item.data == im.equipped_items[child.name]
				)
			)
			else EMPTY_COLOR
		)
		var occupant: ItemData = im.equipped_items.get(child.name)
		# check if mouse is hovering over equipment slot
		if im.dragging_item and im.hovered_item:
			if (
				mouse_pos.x >= child.global_position.x and mouse_pos.y >= child.global_position.y
				and mouse_pos.x <= child.global_position.x + child.size.x
				and mouse_pos.y <= child.global_position.y + child.size.y
			):
				if (im.hovered_item.data.type == SLOT_TYPES[child.name]):
					if not occupant or occupant == im.hovered_item.data:
						color = HOVERED_COLOR
						hovered = child.name

		child.modulate = color
	im.hovered_equipment = hovered
