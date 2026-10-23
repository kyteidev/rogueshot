extends Button


const LISTENING_TEXT = "listening..."

@export var action_name: String

var om := OptionsManager
var listening: bool = false


func _ready() -> void:
	pressed.connect(_start_listening)
	
	_refresh_text()
	

func _input(event: InputEvent) -> void:
	if not listening:
		return
	
	# only listen to key presses
	if event.is_pressed():
		listening = false
		button_pressed = true
		get_viewport().set_input_as_handled() # so binding LMB doesn't cause infinite loop
		
		# cancel rebind if pressing escape
		if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
			_refresh_text()
			return
		
		# rebind key
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event)
		_refresh_text()


func _start_listening() -> void:
	listening = true
	text = LISTENING_TEXT


func _refresh_text() -> void:
	# TODO: multi keybind support
	# make sure action actually has a keybind set
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	if events.size() == 0:
		text = "none"
		return
	
	var key: InputEvent = events[0]
	if key is InputEventMouseButton:
		# abbreviate mouse button names
		var converted_text: String
		match key.button_index:
			1: converted_text = "LMB"
			2: converted_text = "RMB"
			3: converted_text = "MMB"
			_:
				converted_text = "none"
				InputMap.action_erase_events(action_name)
		text = converted_text
	else:
		# only need the name itself
		text = key.as_text_physical_keycode()
	
	# sync options with options manager
	om.set_option(action_name, text)
	
	# revert button to default state after finished listening to input
	button_pressed = false
