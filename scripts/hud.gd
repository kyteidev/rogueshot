extends CanvasLayer


var sm = StateManager
@onready var ammo_mag_label = $AmmoMagLabel

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var ammo_text = "%s/%s | %s %s"
	ammo_mag_label.text = ammo_text % [sm.ammo, sm.max_ammo, sm.mags, "Mag" if sm.mags == 1 else "Mags"]
