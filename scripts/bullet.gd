extends CharacterBody2D


enum Types { FRIENDLY, ENEMY }

const SPEED = 2000
const TRAIL_MAX_POINTS = 4

var sm := StateManager
var type: Types = Types.FRIENDLY

var origin_pos: Vector2

@onready var trail: Line2D = $Trail


func _ready() -> void:
	trail.top_level = true
	trail.clear_points()


func _physics_process(delta: float) -> void:
	var collided: KinematicCollision2D = move_and_collide(transform.x * SPEED * delta)
	
	 # maybe use classes instead for dealing damage?
	if collided:
		var hit: Object = collided.get_collider()
		if type == Types.FRIENDLY:
			if not hit.is_in_group("player"):
				if hit.has_method("take_damage"):
					hit.take_damage(sm.damage)
				
				if hit.has_method("set_target_pos"):
					hit.set_target_pos(origin_pos)
					
				queue_free()
		elif type == Types.ENEMY:
			if not hit.is_in_group("enemy"):
				if hit.has_method("take_damage"):
					hit.take_damage(sm.enemy_damage)
				queue_free()
	
	# add bullet trail
	trail.add_point(global_position)
	if trail.get_point_count() > TRAIL_MAX_POINTS:
		trail.remove_point(0)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
