extends CharacterBody2D


const SPEED = 2000


enum Types { FRIENDLY, ENEMY }

var sm = StateManager
var type = Types.FRIENDLY


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var collided = move_and_collide(transform.x * SPEED * delta)
	
	 # maybe use classes instead for dealing damage?
	if collided:
		var hit = collided.get_collider()
		if type == Types.FRIENDLY:
			if not hit.is_in_group("player"):
				if hit.has_method("take_damage"):
					hit.take_damage(sm.damage)
				queue_free()
		elif type == Types.ENEMY:
			if not hit.is_in_group("enemy"):
				if hit.has_method("take_damage"):
					hit.take_damage(sm.damage)
				queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
