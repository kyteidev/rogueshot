extends Node


var camera_shake: bool = true


func get_options() -> Array:
	# layer 0: tab type as index
	# 		0: gameplay, 1: video, 2: audio, 3: controls
	# layer 1: options
	return [
		{
			"camera_shake": camera_shake
		},
		{
			"lorem ipsum": false
		},
		{
			"lorem ipsum": false
		},
		{
			"lorem ipsum": false
		}
	]
