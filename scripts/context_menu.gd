extends Control

enum MenuTypes {
	DEFAULT,
	EQUIPPABLE,
	UNLOADABLE,
}

var menu_type := MenuTypes.DEFAULT
var menu_size := Vector2.ZERO

var im := ItemManager

@onready var button_scene: PackedScene = preload(
	"res://scenes/context_menu/context_menu_button.tscn"
)


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		# toggle visibility if RMB pressed
		if event.button_index == 2:
			global_position = get_global_mouse_position()
			visible = not visible
			im.context_menu_open = visible

			if visible:
				_load_buttons()
			else:
				_unload_buttons()
		# hide if LMB pressed
		elif visible and event.button_index == 1:
			# check if mouse is not hovering over context menu
			# mouse entered signal doesnt work???
			var mouse_pos: Vector2 = get_global_mouse_position()
			if not (
				(mouse_pos.x >= global_position.x) and (mouse_pos.y >= global_position.y)
				and (mouse_pos.x <= global_position.x + menu_size.x)
				and (mouse_pos.y <= global_position.y + menu_size.y)
			):
				visible = false
				im.context_menu_open = false
				_unload_buttons()


func _load_buttons() -> void:
	# load buttons for each menu type
	var button_count: int = 0
	if menu_type != MenuTypes.DEFAULT:
		var special_button: Button = button_scene.instantiate()
		match menu_type:
			MenuTypes.EQUIPPABLE:
				special_button.text = "Equip"
			MenuTypes.UNLOADABLE:
				special_button.text = "Unload"
		add_child(special_button)
		button_count += 1

	# all menu types have these buttons
	var button: Button = button_scene.instantiate()
	button.text = "Drop"
	add_child(button)
	button_count += 1

	# calculate size of context menu
	menu_size.x = button.size.x
	menu_size.y = button.size.y * button_count

	# add functionality to the buttons
	# loop over contents of get_children
	# because i might add more context menu buttons in the future
	for context_button in get_children():
		context_button.pressed.connect(
			func() -> void:
				_button_functions(context_button.text),
		)


func _unload_buttons() -> void:
	var buttons: Array[Node] = get_children()
	for button in buttons:
		button.queue_free()

	if im.hovered_item == null:
		im.context_menu_item = null
	im.context_menu_open = false


func _button_functions(button_name: String) -> void:
	match button_name:
		"Equip":
			pass
		"Unload":
			pass
		"Drop":
			im.drop_item(im.context_menu_item)

	# hide context menu after action is done
	visible = false
	_unload_buttons()
	im.hovered_item = null
