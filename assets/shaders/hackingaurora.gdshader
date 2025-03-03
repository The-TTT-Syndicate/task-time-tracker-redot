shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.0, 0.1, 0.5, 1.0);
uniform vec4 middle_color : source_color = vec4(0.0, 0.1, 0.5, 1.0);

uniform float aurora_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float aurora_speed = 0.5;

void fragment() {
    vec2 uv = UV;

    float gradient = uv.y;
    vec4 gradient_color = mix(middle_color, top_color, smoothstep(3, 0.0, gradient));

    float aurora = sin(uv.x * 5.0 + TIME * aurora_speed * 2.0) * 2.5 + 0.5;
    aurora *= exp(-uv.y * 4.0) * aurora_intensity;
    aurora *= sin(uv.x * 10.0 + TIME * aurora_speed * 1.0) * 0.8 + 0.5;

    vec4 final_color = gradient_color;
    final_color += vec4(0.1, 0.0, 0.5, 1.0) * aurora;

    COLOR = final_color;
}