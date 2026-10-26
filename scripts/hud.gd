extends CanvasLayer

const HEALTH_BAR_DELAY = 0.5

const EQUIPPED_WEAPON_COLOR = Color("759cea")
const BASE_WEAPON_COLOR = Color("fdf1ff")

const FADE_DURATION = 0.1

@export var player: CharacterBody2D
@export var enemy: CharacterBody2D

var sm := StateManager
var om := OptionsManager

var displayed_health_loss := 100.0

var health_tween: Tween

@onready var ammo_mag_container: HBoxContainer = $AmmoMagContainer
@onready var ammo_label: Label = $AmmoMagContainer/AmmoContainer/AmmoLabel
@onready var mag_label: Label = $AmmoMagContainer/MagContainer/MagLabel

@onready var health_bar_container: CanvasGroup = $HealthBarContainer
@onready var health_bar_bounds: ColorRect = $HealthBarContainer/Bounds
@onready var health_bar: TextureProgressBar = $HealthBarContainer/HealthBar
@onready var health_loss_bar: TextureProgressBar = $HealthBarContainer/HealthLossBar
@onready var health_bar_text: Label = $HealthBarContainer/HealthBar/HealthBarText
@onready var health_timer: Timer = $HealthBarContainer/HealthBarOutline/HealthBarTimer

@onready var equipped_weapons_container: MarginContainer = $EquippedWeaponsContainer
@onready var primary_weapon: TextureRect = $EquippedWeaponsContainer/EquippedContainer/Primary
@onready var secondary_weapon: TextureRect = $EquippedWeaponsContainer/EquippedContainer/Secondary
@onready var primary_weapon_keybind: Label = $EquippedWeaponsContainer/EquippedContainer/Primary/KeybindLabel
@onready var secondary_weapon_keybind: Label = $EquippedWeaponsContainer/EquippedContainer/Secondary/KeybindLabel

@onready var action_hint_label: Label = $ActionHint

@onready var weapon: Node2D = player.get_node("./Weapon")

# DEBUG
@onready var debug_enemy_state_label: Label = $DebugEnemyStateLabel


func _ready() -> void:
	visible = true

	# connect signals for cursor enter and exit
	ammo_mag_container.mouse_entered.connect(
		func() -> void:
			_fade_out(ammo_mag_container),
	)
	ammo_mag_container.mouse_exited.connect(
		func() -> void:
			_fade_in(ammo_mag_container),
	)

	health_bar_bounds.mouse_entered.connect(
		func() -> void:
			_fade_out(health_bar_container, true),
	)
	health_bar_bounds.mouse_exited.connect(
		func() -> void:
			_fade_in(health_bar_container, true),
	)

	equipped_weapons_container.mouse_entered.connect(
		func() -> void:
			_fade_out(equipped_weapons_container),
	)
	equipped_weapons_container.mouse_exited.connect(
		func() -> void:
			_fade_in(equipped_weapons_container),
	)


func _process(delta: float) -> void:
	# update ammo info
	var ammo_text := "%s/%s"
	ammo_label.text = ammo_text % [sm.ammo, sm.max_ammo]

	# update mag info
	mag_label.text = str(sm.mags)

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

	# update equipped weapon display
	primary_weapon.modulate = EQUIPPED_WEAPON_COLOR if weapon.weapon_index == 0 \
			else BASE_WEAPON_COLOR
	secondary_weapon.modulate = EQUIPPED_WEAPON_COLOR if weapon.weapon_index == 1 \
			else BASE_WEAPON_COLOR

	# update keybind
	primary_weapon_keybind.text = om.get_option("weapon_primary")
	secondary_weapon_keybind.text = om.get_option("weapon_secondary")

	# DEBUG SECTION
	if enemy:
		debug_enemy_state_label.text = "ENEMY: %s" % enemy.State.keys()[enemy.state]


func update_hint_label(shown: bool, keybind_name: String = "", hint_text: String = "") -> void:
	action_hint_label.visible = shown
	if not shown:
		return

	var keybind: String = om.get_option(keybind_name)
	action_hint_label.text = "[%s] %s" % [keybind, hint_text]


func _fade_in(node: Variant, self_modulate := false) -> void:
	var tween := create_tween()
	tween.tween_property(
		node,
		"self_modulate" if self_modulate else "modulate",
		Color("ffffff"),
		FADE_DURATION,
	)


func _fade_out(node: Variant, self_modulate := false) -> void:
	var tween := create_tween()
	tween.tween_property(
		node,
		"self_modulate" if self_modulate else "modulate",
		Color("ffffff00"),
		FADE_DURATION,
	)
