shader_type canvas_item;

uniform vec3 grad_bottom = vec3(0.2, 0.2, 1.0);
uniform vec3 grad_top = vec3(0.0, 1.0, 1.0);

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
	float t = UV.y;
	
	COLOR = vec4(grad_bottom * t + grad_top * (1.0 - t), 1.0);
	
//	if(rand(vec2(UV.x + TIME, UV.y + TIME)) < 0.0001) {
//		COLOR = COLOR + vec4(0.3, 0.3, 0.3, 0.0)
//	}
}