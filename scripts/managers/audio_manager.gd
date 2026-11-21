extends Node

const SFX_PATH = "res://assets/sounds/sfx/"

var sounds: Dictionary = { }


func _ready() -> void:
	# preload all sounds
	_load_folder(SFX_PATH)


func play(sound_name: String, position: Variant = null, volume := 0.0, pitch := 0.1) -> void:
	var player: Variant
	if position:
		player = AudioStreamPlayer2D.new()
	else:
		player = AudioStreamPlayer.new()

	player.stream = sounds[sound_name]
	player.volume_db = volume
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
