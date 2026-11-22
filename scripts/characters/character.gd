class_name Character
extends CharacterBody2D

const GRAVITY = 750
const FALL_GRAVITY = GRAVITY * 1.5

const GROUND_ACCEL = 900.0
const GROUND_FRICTION = 1100.0
const AIR_ACCEL = 600.0
const AIR_FRICTION = 300.0
const TURN_MULTIPLIER = 1.5

# walk particle stuff
const PARTICLE_MIN_VEL = 20.0 # minimum x velocity for walk particles to appear

const PARTICLE_AMOUNT_SLOW = 4.0 / PARTICLE_AMOUNT_FAST
const PARTICLE_AMOUNT_NORMAL = 8.0 / PARTICLE_AMOUNT_FAST
const PARTICLE_AMOUNT_FAST = 14

var sfx_last_step_id := ""


func get_custom_gravity(vel: Vector2) -> float:
	if vel.y < 0:
		return GRAVITY
	return FALL_GRAVITY


func manage_walk_particles(
	particles: GPUParticles2D,
	tilemap_ground: TileMapLayer,
	particle_max_vel: float,
) -> void:
	if not OptionsManager.get_option("particles"):
		return

	# using speed variable might cause racing problems maybe
	# just get speed from velocity instead
	var move_speed: float = abs(velocity.x)
	if not is_on_floor() or move_speed <= PARTICLE_MIN_VEL:
		particles.emitting = false
		return

	# retrieve color from custom data layer in ground tiles
	var local_pos: Vector2 = tilemap_ground.to_local(global_position)
	var tile_pos: Vector2i = tilemap_ground.local_to_map(local_pos)
	tile_pos.y += 1 # offset by 1 to get tile data BELOW the player

	var tile_data: TileData = tilemap_ground.get_cell_tile_data(tile_pos)
	var ground_color: Color
	if tile_data:
		ground_color = tile_data.get_custom_data("particle_color")
		var gradient: Gradient = particles.process_material.color_ramp.gradient

		gradient.set_color(0, ground_color)
		gradient.set_color(1, ground_color)
		gradient.set_color(
			2,
			Color(ground_color.r * 0.7, ground_color.g * 0.7, ground_color.b * 0.7, 0.0),
		)

	var percent: float = move_speed / particle_max_vel
	var target_amount: float
	if percent <= 0.4:
		target_amount = PARTICLE_AMOUNT_SLOW
	elif percent <= 0.8:
		target_amount = PARTICLE_AMOUNT_NORMAL
	else:
		target_amount = 1.0

	if particles.amount_ratio != target_amount:
		particles.amount_ratio = 1.0

	particles.emitting = true
	particles.process_material.direction = Vector3(-sign(velocity.x), -0.4, 0.0)


func on_anim_sprite_frame_changed(
	anim_sprite: AnimatedSprite2D,
	sound_ids: Array,
	volume_offset := 0.0,
) -> void:
	if not is_on_floor() or abs(velocity.x) == 0.0:
		return

	var walk_frames := [0, 3]
	if anim_sprite.frame in walk_frames:
		var volume: float = randf_range(6.0, 8.0) + volume_offset
		var new_id := ""
		while new_id == "" or new_id == sfx_last_step_id:
			new_id = sound_ids.pick_random()
		if new_id.length() == 1:
			new_id = "0" + new_id

		AudioManager.play("character_walk_rock_" + new_id, global_position, volume)
