// Adapted from Color vignette by randomDam - https://godotshaders.com/shader/color-vignetting/
shader_type canvas_item;

instance uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform float vignette_intensity = 0.4;
uniform vec4 vignette_rgb : source_color = vec4(0.0, 0.0, 0.0, 1.0);

float vignette(vec2 uv){
	uv *= 1.0 - uv.xy;
	float vignette = uv.x * uv.y * 15.0;
	vignette = clamp(vignette, 0.0, 0.8);
	return 1.0 - pow(vignette, vignette_intensity);
}

void fragment(){
	float edge = vignette(UV);
	COLOR = vec4(vignette_rgb.rgb, edge * vignette_opacity);
}