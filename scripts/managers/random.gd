extends Node

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
