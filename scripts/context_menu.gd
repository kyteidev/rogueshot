extends Control

enum MenuTypes {
	DEFAULT,
	EQUIPPABLE,
	UNLOADABLE,
}

var menu_type := MenuTypes.DEFAULT

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

			if visible:
				_load_buttons()
			else:
				_unload_buttons()
		# hide if LMB pressed
		elif event.button_index == 1:
			visible = false
			_unload_buttons()


func _load_buttons() -> void:
	var button: Button = button_scene.instantiate()

	# load buttons for each menu type
	if menu_type != MenuTypes.DEFAULT:
		match menu_type:
			MenuTypes.EQUIPPABLE:
				button.text = "Equip"
			MenuTypes.UNLOADABLE:
				button.text = "Unload"
		add_child(button)

	# all menu types have these buttons
	button.text = "Drop"
	add_child(button)


func _unload_buttons() -> void:
	var buttons: Array[Node] = get_children()
	for button in buttons:
		button.queue_free()
