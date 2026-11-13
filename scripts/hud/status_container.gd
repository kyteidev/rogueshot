extends VBoxContainer

const STATUS_LABEL = preload("res://scenes/hud/status_label.tscn")

var prev_status_count: int = 0

var sm := StateManager


func _process(_delta: float) -> void:
	if sm.active_statuses.size() != prev_status_count:
		prev_status_count = sm.active_statuses.size()

		for child in get_children():
			child.queue_free()

		for status in sm.active_statuses:
			var label: PanelContainer = STATUS_LABEL.instantiate()
			# panel container > margin container > label
			label.get_child(0).get_child(0).text = sm.PlayerStatus.keys()[status].capitalize()
			add_child(label)
