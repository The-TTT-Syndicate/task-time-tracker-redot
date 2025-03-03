shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.0, 0.8, 0.76, 1.0); // #00ccc2
uniform vec4 bottom_glow_color : source_color = vec4(1.0, 0.27, 1.0, 1.0); // #FF46FF
uniform float line_thickness : hint_range(0.001, 0.1) = 0.005;
uniform float line_position : hint_range(0.0, 1.0) = 0.5;
uniform float glow_strength : hint_range(0.1, 2.0) = 0.5;

void fragment() {
    vec2 uv = UV;

    float distance_from_line = uv.y - line_position;
    float abs_distance = abs(distance_from_line);
    float line_intensity = smoothstep(line_thickness, 0.0, abs_distance);

    float top_glow = exp(-abs_distance * 8.0 * glow_strength) * float(distance_from_line <= 0.0);
    float bottom_glow = exp(-abs_distance * 8.0 * glow_strength) * float(distance_from_line > 0.0);

    vec4 final_color = line_color * line_intensity +
                      line_color * top_glow +
                      bottom_glow_color * bottom_glow;
    final_color.a *= line_intensity + top_glow + bottom_glow;

    COLOR = final_color;
}
