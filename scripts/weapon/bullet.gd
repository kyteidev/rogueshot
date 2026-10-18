extends CharacterBody2D


enum Types { FRIENDLY, ENEMY }

const SPEED = 1000
const TRAIL_MAX_POINTS = 7

var sm := StateManager
var type: Types = Types.FRIENDLY

var origin_pos: Vector2

@onready var trail: Line2D = $Trail


func _ready() -> void:
	trail.top_level = true
	trail.clear_points() # clear any points i might have left in editor
	trail.add_point(global_position)


func _physics_process(delta: float) -> void:	
	var collided := move_and_collide(transform.x.normalized() * SPEED * delta)
	
	# check collisions and ignore sender
	# maybe use classes instead for dealing damage?
	if collided:
		var hit: Object = collided.get_collider()
		trail.add_point(collided.get_position())
		if type == Types.FRIENDLY:
			if not hit.is_in_group("player"):
				if hit.has_method("take_damage"):
					hit.take_damage(sm.damage)
				
				if hit.has_method("set_target_pos"):
					hit.set_target_pos(origin_pos)
					
				_unload_bullet()
		elif type == Types.ENEMY:
			if not hit.is_in_group("enemy"):
				if hit.has_method("take_damage"):
					hit.take_damage(sm.enemy_damage)
				_unload_bullet()
	else:
		trail.add_point(global_position)
		
	if trail.get_point_count() > TRAIL_MAX_POINTS:
		trail.remove_point(0)


func _unload_bullet() -> void:
	# bullet gets unloaded before tween finishes, so reparent trail
	trail.reparent(get_tree().root)
	
	# make trail fade out nicely
	var tween := trail.create_tween()
	tween.tween_property(trail, "modulate", Color("ffffff00"), 0.12)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(trail.queue_free)
	
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
