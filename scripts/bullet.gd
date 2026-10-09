extends CharacterBody2D


const SPEED = 2500


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position += transform.x * SPEED * delta
	
	var collided = move_and_collide(transform.x * SPEED * delta)
	
	if collided:
		var hit = collided.get_collider()
		if not hit.is_in_group("player"):
			queue_free()
