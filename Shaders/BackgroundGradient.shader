shader_type canvas_item;

uniform vec3 grad_bottom = vec3(0.2, 0.2, 1.0);
uniform vec3 grad_top = vec3(0.0, 1.0, 1.0);

void fragment() {
	float t = UV.y;
	
	COLOR = vec4(grad_bottom * t + grad_top * (1.0 - t), 1.0);
}