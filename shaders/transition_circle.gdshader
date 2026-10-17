shader_type canvas_item;
render_mode unshaded;

uniform float circle_size : hint_range(0.0, 1.05);
uniform vec2 circle_center = vec2(0.5, 0.5);
uniform float screen_width;
uniform float screen_height;

void fragment() {
	float ratio = screen_width / screen_height;
	vec2 offset = UV - circle_center;
	float dist = distance(UV * vec2(ratio, 1.0), circle_center * vec2(ratio, 1.0));
	COLOR.a = step(circle_size, dist);
}