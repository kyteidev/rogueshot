extends RigidBody2D

const COLLISION_SIMPLIFICATION = 1.0
const SCALE = 0.75

const OUTLINE_WIDTH = 1.0

var data: ItemData

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionPolygon2D = $CollisionPolygon2D


func setup(item_data: ItemData) -> void:
	data = item_data
	sprite.texture = item_data.icon
	sprite.scale = Vector2.ONE * SCALE

	# update collision polygon
	var image: Image = sprite.texture.get_image()
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image)

	var polygons: Array[PackedVector2Array] = bitmap.opaque_to_polygons(
		Rect2(Vector2(), image.get_size()),
		COLLISION_SIMPLIFICATION,
	)

	# flatten points into one array
	var points := PackedVector2Array()
	for poly in polygons:
		points.append_array(poly)
	var hull: PackedVector2Array = Geometry2D.convex_hull(points)

	# since image is centered, apply offset to collision
	var offset: Vector2 = image.get_size() / 2.0
	for index in hull.size():
		hull[index] = (hull[index] - offset) * SCALE
	collision.polygon = hull


func show_outline() -> void:
	sprite.material.set("shader_parameter/width", OUTLINE_WIDTH)


func hide_outline() -> void:
	sprite.material.set("shader_parameter/width", 0.0)
