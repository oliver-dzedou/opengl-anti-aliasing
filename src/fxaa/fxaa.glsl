#version 330

#define FXAA_REDUCE_MIN (1.0/128.0)
#define FXAA_REDUCE_MUL (1.0/8.0)
#define FXAA_SPAN_MAX 8.0

#define LUMA vec3(0.299, 0.587, 0.114)

out vec4 fragColor;

layout(location = 0) uniform vec2 resolution;
layout(location = 1) uniform sampler2D texture0;
layout(location = 2) uniform sampler2D scene;

void texcoords(
    vec2 fragCoord,
    vec2 resolution,
    out vec2 v_rgbNW,
    out vec2 v_rgbNE,
    out vec2 v_rgbSW,
    out vec2 v_rgbSE,
    out vec2 v_rgbM
) {
    vec2 inverse_resolution = 1.0 / resolution;
    v_rgbNW = (fragCoord + vec2(-1.0, -1.0)) * inverse_resolution;
    v_rgbNE = (fragCoord + vec2(1.0, -1.0)) * inverse_resolution;
    v_rgbSW = (fragCoord + vec2(-1.0, 1.0)) * inverse_resolution;
    v_rgbSE = (fragCoord + vec2(1.0, 1.0)) * inverse_resolution;
    v_rgbM = vec2(fragCoord * inverse_resolution);
}

vec4 fxaa(
    sampler2D scene,
    vec2 fragCoord,
    vec2 resolution,
    vec2 v_rgbNW,
    vec2 v_rgbNE,
    vec2 v_rgbSW,
    vec2 v_rgbSE,
    vec2 v_rgbM
) {
    vec4 color;
    vec2 inverse_resolution = 1.0 / resolution;

    vec3 rgbNW = texture(scene, v_rgbNW).xyz;
    vec3 rgbNE = texture(scene, v_rgbNE).xyz;
    vec3 rgbSW = texture(scene, v_rgbSW).xyz;
    vec3 rgbSE = texture(scene, v_rgbSE).xyz;
    vec4 texColor = texture(scene, v_rgbM);
    vec3 rgbM = texColor.xyz;

    float lumaNW = dot(rgbNW, LUMA);
    float lumaNE = dot(rgbNE, LUMA);
    float lumaSW = dot(rgbSW, LUMA);
    float lumaSE = dot(rgbSE, LUMA);
    float lumaM = dot(rgbM, LUMA);
    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y = ((lumaNW + lumaSW) - (lumaNE + lumaSE));
    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = min(vec2(FXAA_SPAN_MAX), max(vec2(-FXAA_SPAN_MAX), dir * rcpDirMin)) * inverse_resolution;
    vec3 rgbA = 0.5 * (
            texture(scene, fragCoord * inverse_resolution + dir * (1.0 / 3.0 - 0.5)).rgb +
                texture(scene, fragCoord * inverse_resolution + dir * (2.0 / 3.0 - 0.5)).rgb);
    vec3 rgbB = rgbA * 0.5 + 0.25 * (
                texture(scene, fragCoord * inverse_resolution + dir * -0.5).rgb +
                    texture(scene, fragCoord * inverse_resolution + dir * 0.5).rgb);
    float lumaB = dot(rgbB, LUMA);
    if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
        color = vec4(rgbA, texColor.a);
    }
    else {
        color = vec4(rgbB, texColor.a);
    }
    return color;
}

void main() {
    vec2 v_rgbNW;
    vec2 v_rgbNE;
    vec2 v_rgbSW;
    vec2 v_rgbSE;
    vec2 v_rgbM;

    texcoords(gl_FragCoord.xy, resolution, v_rgbNW, v_rgbNE, v_rgbSW, v_rgbSE, v_rgbM);

    fragColor = fxaa(scene, gl_FragCoord.xy, resolution, v_rgbNW, v_rgbNE, v_rgbSW, v_rgbSE, v_rgbM);
}
