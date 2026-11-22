extends Node

const SFX_PATH = "res://assets/sounds/sfx/"

var sounds: Dictionary = { }
var master_volume := 1.0

var om := OptionsManager


func _ready() -> void:
	# preload all sounds
	_load_folder(SFX_PATH)

	om.option_changed.connect(
		func() -> void:
			master_volume = om.get_option("master_volume"),
	)


func play(sound_name: String, position: Variant = null, volume := 0.0, pitch := 0.1) -> void:
	if not om.get_option("sfx"):
		return

	var player: Variant
	if position:
		player = AudioStreamPlayer2D.new()
	else:
		player = AudioStreamPlayer.new()

	player.stream = sounds[sound_name]
	player.volume_db = linear_to_db(master_volume) + volume
	player.pitch_scale = randf_range(1.0 - pitch, 1.0 + pitch)

	if position:
		player.global_position = position

	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func _load_folder(path: String) -> void:
	for dir in DirAccess.get_directories_at(path):
		_load_folder(path + dir + "/")

	for file in DirAccess.get_files_at(path):
		file = file.trim_suffix(".import")
		sounds[file.get_basename()] = load(path + file)
