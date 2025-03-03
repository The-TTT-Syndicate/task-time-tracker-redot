shader_type canvas_item;

uniform vec4 grid_color : source_color = vec4(1.0, 0.2, 0.8, 1.0);
uniform vec4 background_color : source_color = vec4(0.05, 0.0, 0.1, 1.0);
uniform float glow_intensity : hint_range(0.0, 1.0) = 1.0;
uniform float ease_strength : hint_range(32.0, 34.0) = 10.0;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

    float perspective = 6.0;
    uv.y += 1.0;
    uv.y *= perspective;

    float grid_spacing_x = 0.3;
    float line_thickness = 0.05;
    float line_x = abs(fract(uv.x / (grid_spacing_x * (0.1 + uv.y))) - 0.5) / line_thickness;
    float grid = 1.0 - smoothstep(0.0, 1.0, line_x);
    float glow = exp(-line_x * glow_intensity);

    float base_time = TIME ;

    float cycle_position = fract(base_time*0.5);

    float eased_cycle_position = pow(cycle_position, ease_strength*4.0);

    float scan_line = 1.0 - fract(UV.y - eased_cycle_position);

    float intensity_multiplier = UV.y;
    float scan_width = line_thickness * (2.0 + intensity_multiplier * 3.0);

    float scan_line_intensity = (1.0 - smoothstep(0.0, scan_width, scan_line)) * glow_intensity * (1.0 + intensity_multiplier);

    vec4 final_color = mix(background_color, grid_color, grid + glow * glow_intensity);
    final_color = mix(final_color, grid_color, scan_line_intensity);

    COLOR = final_color;
}
