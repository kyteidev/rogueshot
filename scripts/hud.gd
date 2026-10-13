extends CanvasLayer


const STAMINA_BAR_DELAY = 0.5

const STAMINA_COLOR = Color("3cffae")
const STAMINA_FLASH_COLOR = Color("32757c")
const STAMINA_FLASH_DELAY = 0.5

var sm = StateManager

var displayed_stamina_loss = 100.0
var delayed_stamina_loss = true

var stamina_tween: Tween
var stamina_was_depleted = false

@onready var ammo_mag_label = $AmmoMagLabel

@onready var stamina_bar = $StaminaBarOutline/StaminaBar
@onready var stamina_loss_bar = $StaminaBarOutline/StaminaLossBar
@onready var stamina_timer = $StaminaBarOutline/StaminaBarTimer


func _ready() -> void:
	visible = true


func _process(delta: float) -> void:
	# update ammo info
	var ammo_text = "%s/%s | %s %s"
	ammo_mag_label.text = ammo_text % [sm.ammo, sm.max_ammo, sm.mags, "Mag" if sm.mags == 1 else "Mags"]
	
	# update stamina info
	stamina_bar.value = sm.stamina
	
	# flash stamina bar if completely depleted
	if sm.stamina_depleted and not stamina_was_depleted:
		start_stamina_flash()
	elif not sm.stamina_depleted and stamina_was_depleted:
		stop_stamina_flash()
	stamina_was_depleted = sm.stamina_depleted
	
	# delay the stamina loss bar
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


func start_stamina_flash() -> void:
	if stamina_tween:
		stamina_tween.kill()
	
	stamina_tween = create_tween().set_loops()
	stamina_tween.tween_property(stamina_bar, "tint_progress", STAMINA_FLASH_COLOR, STAMINA_FLASH_DELAY)
	stamina_tween.tween_property(stamina_bar, "tint_progress", STAMINA_COLOR, STAMINA_FLASH_DELAY)
	

func stop_stamina_flash() -> void:
	if stamina_tween:
		stamina_tween.kill()
	
	create_tween().tween_property(stamina_bar, "tint_progress", STAMINA_COLOR, STAMINA_FLASH_DELAY)


func _on_stamina_bar_timer_timeout() -> void:
	delayed_stamina_loss = true
