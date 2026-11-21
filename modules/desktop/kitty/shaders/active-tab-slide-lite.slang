#language slang 2026

import kitty_custom_shader_types;

// Adapted from patricorgi/kitty-sliding-tabs. Python supplies real cell metrics
// and the current palette, so font/DPI changes and Noctalia reloads need no
// hand-edited shader constants. Coordinates use pixels; colors are linear RGB.
static const float CORNER_RADIUS = 24.8; // At the reference 53 px tab height.
static const int RECORD_CELLS = 9;

int read_marker(KittyTexture texture, float2 uv, int signature) {
    float3 color = texture.Sample(uv).rgb;
    if (any(color < 0.10)) return -1;
    float3 srgb = 1.055 * pow(color, float3(1.0 / 2.4)) - 0.055;
    int3 levels = int3(round((srgb * 255.0 - 96.0) / 5.0));
    if (any(levels < 0) || any(levels > 31)) return -1;
    int packed = (levels.x << 10) | (levels.y << 5) | levels.z;
    return (packed >> 13) == signature ? packed & 8191 : -1;
}

float coverage_of(float3 color, float3 background, float3 ink) {
    float3 delta = ink - background;
    return saturate(dot(color - background, delta) / max(dot(delta, delta), 0.00001));
}

struct Palette {
    float3 highlight;
    float3 active_title;
    float3 active_index;
    float3 inactive_title;
    float3 inactive_index;
};

struct CornerSamples {
    float4 insets;
    float4 coverage;
};

CornerSamples sample_corners(float row_y, float row_height) {
    float y_inset = min(0.5, (row_height - 1.0) * 0.5);
    float radius = clamp(CORNER_RADIUS * (row_height / 53.0), 0.0, row_height * 0.75);
    float vertical_radius = max(0.001, min(radius * (23.1 / 24.8), row_height * 0.5 - y_inset));
    float4 y = row_y + float4(-0.375, -0.125, 0.125, 0.375);
    float4 distance_from_edge = min(y, row_height - y) - y_inset;
    float4 u = 1.0 - sqrt(saturate(distance_from_edge / vertical_radius));
    return { radius * pow(u, float4(2.14)), step(float4(0.0), distance_from_edge) };
}

float4 paint_slide(float4 color, float x, CornerSamples corners, float3 background,
                   Palette palette, float2 visible, float2 target) {
    bool under_target = x >= target.x && x < target.y;
    float distance_to_side = min(x - visible.x, visible.y - x);
    if (!under_target && distance_to_side < 0.0) return color;

    float4 coverage = corners.coverage * saturate(distance_to_side - corners.insets + 0.5);
    float fill = dot(coverage, float4(0.25));
    float3 new_background = lerp(background, palette.highlight, fill);
    float3 original_background = under_target ? palette.highlight : background;
    float3 old_title = under_target ? palette.active_title : palette.inactive_title;
    float3 old_number = under_target ? palette.active_index : palette.inactive_index;
    float title_alpha = coverage_of(color.rgb, original_background, old_title);
    float number_alpha = coverage_of(color.rgb, original_background, old_number);
    bool number = distance(color.rgb, lerp(original_background, old_number, number_alpha))
                < distance(color.rgb, lerp(original_background, old_title, title_alpha));
    float3 title = lerp(palette.inactive_title, palette.active_title, fill);
    float3 index = lerp(palette.inactive_index, palette.active_index, fill);
    return float4(lerp(new_background, number ? index : title,
                       number ? number_alpha : title_alpha), color.a);
}

public float4 fragment_main(float4 color, KittyTextures t, uniform KittyCustomShaderData d) {
    float2 pixel = 1.0 / float2(d.viewport_size_pixels);
    float bottom = d.central_area.y + d.central_area.w;
    if (t.pos.y < bottom) return color; // Never touch the terminal content.

    // With a top tab bar and zero inner margin, this is the bottom scanline
    // of its text cells, regardless of DPI or the size of its outer margin.
    float sample_y = bottom + 0.5 * pixel.y;
    int geometry = read_marker(t.backbuffer, float2(0.5 * pixel.x, sample_y), 3);
    if (geometry < 0) return color;
    int cell_width = geometry & 63;
    int row_height = geometry >> 6;
    if (cell_width < 1 || row_height < 1) return color;
    float top = bottom + float(row_height) * pixel.y;
    if (top > 1.00001 || t.pos.y >= top) return color;

    int columns = int(d.viewport_size_pixels.x) / cell_width;
    int column = columns - RECORD_CELLS;
    if (column < 1) return color;
    float start = float(column * cell_width);
    float2 record = float2((start + 0.5 * float(cell_width)) * pixel.x, sample_y);
    float step_x = float(cell_width) * pixel.x;
    int left = read_marker(t.backbuffer, record, 1);
    int right = read_marker(t.backbuffer, record + float2(step_x, 0.0), 2);
    int target_left = read_marker(t.backbuffer, record + float2(2.0 * step_x, 0.0), 3);
    int target_right = read_marker(t.backbuffer, record + float2(3.0 * step_x, 0.0), 2);
    if (left < cell_width || right <= left || target_left < cell_width
        || target_right <= target_left || float(right) >= start || float(target_right) >= start)
        return color;

    float x = t.pos.x / pixel.x;
    float3 background = d.background.rgb;
    // Remove both the geometry beacon and the entire payload/right remainder.
    if (x < float(cell_width) || x >= start) return float4(background, color.a);
    Palette palette = {
        t.backbuffer.Sample(record + float2(4.0 * step_x, 0.0)).rgb,
        t.backbuffer.Sample(record + float2(5.0 * step_x, 0.0)).rgb,
        t.backbuffer.Sample(record + float2(6.0 * step_x, 0.0)).rgb,
        t.backbuffer.Sample(record + float2(7.0 * step_x, 0.0)).rgb,
        t.backbuffer.Sample(record + float2(8.0 * step_x, 0.0)).rgb,
    };
    CornerSamples corners = sample_corners((top - t.pos.y) / pixel.y, float(row_height));
    return paint_slide(color, x, corners, background, palette,
                       float2(float(left), float(right)),
                       float2(float(target_left), float(target_right)));
}
