extends Node

const SFX_PATH = "res://assets/sounds/sfx/"
const MAX_DISTANCE = 350.0
const ATTENUATION = 1.5

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


func play(
	sound_name: String,
	position: Variant = null,
	volume := 0.0,
	pitch := 0.1,
	bus := &"",
	fade := false,
	keep_time := 0.0,
	fade_time := 0.0,
) -> Variant:
	if not om.get_option("sfx"):
		return null

	var player: Variant
	if position:
		player = AudioStreamPlayer2D.new()
	else:
		player = AudioStreamPlayer.new()

	player.stream = sounds[sound_name]
	player.volume_db = linear_to_db(master_volume) + volume
	player.pitch_scale = randf_range(1.0 - pitch, 1.0 + pitch)
	player.process_mode = PROCESS_MODE_ALWAYS

	if bus != &"":
		player.bus = bus

	if position:
		player.global_position = position
		player.max_distance = MAX_DISTANCE
		player.attenuation = ATTENUATION

	add_child(player)
	player.play()

	if not fade:
		player.finished.connect(player.queue_free)
		return player.finished
	else:
		var tween := create_tween()
		tween.tween_interval(keep_time)
		tween.tween_property(player, "volume_db", -60.0, fade_time) \
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.finished.connect(player.queue_free)
		return tween.finished


func _load_folder(path: String) -> void:
	for dir in DirAccess.get_directories_at(path):
		_load_folder(path + dir + "/")

	for file in DirAccess.get_files_at(path):
		file = file.trim_suffix(".import")
		sounds[file.get_basename()] = load(path + file)
