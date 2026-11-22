extends CharacterBody2D

enum Types {
	FRIENDLY,
	ENEMY,
}

const IMPACT_PARTICLES = preload("res://scenes/particles/bullet_impact.tscn")

const SPEED = 1000
const TRAIL_MAX_POINTS = 7

@export var bullet_calibers: Dictionary[AmmoData.Caliber, PackedScene]

var sm := StateManager
var om := OptionsManager
var type := Types.FRIENDLY

var origin_pos: Vector2

var prev_pos: Vector2
var distance: float

var effective_range: float
var max_range: float

var caliber: AmmoData.Caliber

@onready var trail: Line2D = $Trail


func _ready() -> void:
	trail.top_level = true
	trail.clear_points() # clear any points i might have left in editor
	trail.add_point(global_position)

	var bullet_scene: Sprite2D = bullet_calibers[caliber].instantiate()
	add_child(bullet_scene)
	var collision: CollisionShape2D = bullet_scene.get_child(0) # gets the collisionshape2d
	collision.reparent(self)


func _physics_process(delta: float) -> void:
	var collided: KinematicCollision2D = move_and_collide(transform.x.normalized() * SPEED * delta)

	# calculate distance travelled
	if prev_pos:
		distance += (global_position - prev_pos).length()
	prev_pos = global_position

	# check collisions and ignore sender
	# maybe use classes instead for dealing damage?
	if collided:
		var hit: Object = collided.get_collider()
		trail.add_point(collided.get_position())

		var friendly_fire := true
		var damage: float
		match type:
			Types.FRIENDLY:
				if not hit.is_in_group("player"):
					friendly_fire = false

				damage = sm.damage
			Types.ENEMY:
				if not hit.is_in_group("enemy"):
					friendly_fire = false

				damage = sm.enemy_damage

		# damage calculations
		damage = damage - (
			clamp(1.0 - (distance - effective_range) / (max_range - effective_range), 0.0, 1.0)
		)
		damage = snapped(damage, 0.1)

		if not friendly_fire:
			if hit.has_method("take_damage"):
				hit.take_damage(damage, global_position)

			if hit.has_method("set_target_pos"):
				hit.set_target_pos(origin_pos)

			if hit.is_in_group("living"):
				_draw_impact_particles(1)
			else:
				_draw_impact_particles(0)
			_unload_bullet()
	else:
		trail.add_point(global_position)

	if trail.get_point_count() > TRAIL_MAX_POINTS:
		trail.remove_point(0)


func _draw_impact_particles(impact_type: int) -> void:
	if not om.get_option("particles"):
		return

	var impact_particles: CPUParticles2D = IMPACT_PARTICLES.instantiate()
	impact_particles.global_position = global_position
	impact_particles.global_rotation = global_rotation + PI
	impact_particles.set_impact_color(impact_type)

	get_tree().current_scene.add_child(impact_particles)


func _unload_bullet() -> void:
	# bullet gets unloaded before tween finishes, so reparent trail
	trail.reparent(get_tree().root)

	# make trail fade out nicely
	var tween := trail.create_tween()
	tween.tween_property(trail, "modulate", Color("ffffff00"), 0.12) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(trail.queue_free)

	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
