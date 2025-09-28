#version 330

out vec4 fragColor;

uniform vec4 SMAA_RT_METRICS;
uniform sampler2D texture0;
uniform sampler2D colorTex;
uniform sampler2D weightTex;

vec4 fma(vec4 a, vec4 b, vec4 c) {
    return a * b + c;
}

vec3 fma(vec3 a, vec3 b, vec3 c) {
    return a * b + c;
}

vec2 fma(vec2 a, vec2 b, vec2 c) {
    return a * b + c;
}

float fma(float a, float b, float c) {
    return a * b + c;
}

/**
 * Conditional move:
 */
void SMAAMovc(bvec2 cond, inout vec2 variable, vec2 value) {
    if (cond.x) variable.x = value.x;
    if (cond.y) variable.y = value.y;
}

void SMAAMovc(bvec4 cond, inout vec4 variable, vec4 value) {
    SMAAMovc(cond.xy, variable.xy, value.xy);
    SMAAMovc(cond.zw, variable.zw, value.zw);
}

void main() {
    vec2 vTexCoord0 = (gl_FragCoord.xy - vec2(0.5)) * SMAA_RT_METRICS.xy;
    vec4 vOffset = fma(SMAA_RT_METRICS.xyxy, vec4(1.0, 0.0, 0.0, 1.0), vTexCoord0.xyxy);

    vec4 color;

    // Fetch the blending weights for current pixel:
    vec4 a;
    a.x = texture(weightTex, vOffset.xy).a; // Right
    a.y = texture(weightTex, vOffset.zw).g; // Top
    a.zw = texture(weightTex, vTexCoord0).xz; // Bottom / Left

    // Is there any blending weight with a value greater than 0.0?
    if (dot(a, vec4(1.0, 1.0, 1.0, 1.0)) <= 1e-5) {
        color = texture(colorTex, vTexCoord0); // LinearSampler
    } else {
        bool h = max(a.x, a.z) > max(a.y, a.w); // max(horizontal) > max(vertical)

        // Calculate the blending offsets:
        vec4 blendingOffset = vec4(0.0, a.y, 0.0, a.w);
        vec2 blendingWeight = a.yw;
        SMAAMovc(bvec4(h, h, h, h), blendingOffset, vec4(a.x, 0.0, a.z, 0.0));
        SMAAMovc(bvec2(h, h), blendingWeight, a.xz);
        blendingWeight /= dot(blendingWeight, vec2(1.0, 1.0));

        // Calculate the texture coordinates:
        vec4 blendingCoord = fma(blendingOffset, vec4(SMAA_RT_METRICS.xy, -SMAA_RT_METRICS.xy), vTexCoord0.xyxy);

        // We exploit bilinear filtering to mix current pixel with the chosen
        // neighbor:
        color = blendingWeight.x * texture(colorTex, blendingCoord.xy); // LinearSampler
        color += blendingWeight.y * texture(colorTex, blendingCoord.zw); // LinearSampler
    }

    fragColor = color;
}
