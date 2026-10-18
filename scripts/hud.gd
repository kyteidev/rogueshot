extends CanvasLayer


const HEALTH_BAR_DELAY = 0.5

@export var enemy: CharacterBody2D

var sm := StateManager

var displayed_health_loss: float = 100.0

var health_tween: Tween

@onready var ammo_mag_label := $AmmoMagLabel

@onready var health_bar := $HealthBarOutline/HealthBar
@onready var health_loss_bar := $HealthBarOutline/HealthLossBar
@onready var health_bar_text := $HealthBarOutline/HealthBar/HealthBarText
@onready var health_timer := $HealthBarOutline/HealthBarTimer

@onready var debug_enemy_state_label := $DebugEnemyStateLabel


func _ready() -> void:
	visible = true


func _process(delta: float) -> void:
	# update ammo info
	var ammo_text: String = "%s/%s | %s %s"
	ammo_mag_label.text = ammo_text % [sm.ammo, sm.max_ammo, sm.mags, "Mag" if sm.mags == 1 else "Mags"]
	
	# update health info
	health_bar.value = sm.health
	health_bar_text.text = "%s/%s" % [sm.health, sm.max_health]
	
	# delay the health loss bar
	if sm.lost_health:
		sm.lost_health = false
		health_timer.start(HEALTH_BAR_DELAY)
	
	if sm.health >= displayed_health_loss:
		displayed_health_loss = sm.health
	elif health_timer.is_stopped():
		displayed_health_loss = lerpf(displayed_health_loss, sm.health, 1.0 - exp(-10.0 * delta))
		
		# snap to value if close enough
		if absf(displayed_health_loss - sm.health) < 0.1:
			displayed_health_loss = sm.health
	
	health_loss_bar.value = displayed_health_loss
	
	# DEBUG SECTION
	if enemy:
		debug_enemy_state_label.text = "ENEMY: %s" % enemy.State.keys()[enemy.state]
