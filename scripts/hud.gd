extends CanvasLayer


var sm = StateManager
const STAMINA_BAR_DELAY = 0.5

@onready var ammo_mag_label = $AmmoMagLabel

@onready var stamina_bar = $StaminaBarOutline/StaminaBar
@onready var stamina_loss_bar = $StaminaBarOutline/StaminaLossBar
@onready var stamina_timer = $StaminaBarOutline/StaminaBarTimer

var displayed_stamina_loss = 100.0
var delayed_stamina_loss = true


func _process(delta: float) -> void:
	# update ammo info
	var ammo_text = "%s/%s | %s %s"
	ammo_mag_label.text = ammo_text % [sm.ammo, sm.max_ammo, sm.mags, "Mag" if sm.mags == 1 else "Mags"]
	
	# update stamina info
	stamina_bar.value = sm.stamina

	if sm.used_stamina:
		sm.used_stamina = false
		delayed_stamina_loss = false
		stamina_timer.start(STAMINA_BAR_DELAY)
	
	if sm.stamina >= displayed_stamina_loss:
		displayed_stamina_loss = sm.stamina
	elif delayed_stamina_loss:
		displayed_stamina_loss = lerpf(displayed_stamina_loss, sm.stamina, 1.0 - exp(-10.0 * delta))
		
		# snap to value if close enough
		if absf(displayed_stamina_loss - sm.stamina) < 0.1:
			displayed_stamina_loss = sm.stamina
	
	stamina_loss_bar.value = displayed_stamina_loss


func _on_stamina_bar_timer_timeout() -> void:
	delayed_stamina_loss = true
