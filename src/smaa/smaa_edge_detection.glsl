#version 330

uniform vec4 SMAA_RT_METRICS;
uniform sampler2D texture0;
uniform sampler2D colorTex;

out vec4 fragColor;

// Configurable defines
#define SMAA_THRESHOLD 0.05
#define SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR 2.0

vec4 fma(vec4 a, vec4 b, vec4 c) {
    return a * b + c;
}

void main() {
    vec2 vTexCoord0 = (gl_FragCoord.xy - vec2(0.5)) * SMAA_RT_METRICS.xy;
    vec4 vOffset[3];
    vOffset[0] = fma(SMAA_RT_METRICS.xyxy, vec4(-1.0, 0.0, 0.0, -1.0), vTexCoord0.xyxy);
    vOffset[1] = fma(SMAA_RT_METRICS.xyxy, vec4(1.0, 0.0, 0.0, 1.0), vTexCoord0.xyxy);
    vOffset[2] = fma(SMAA_RT_METRICS.xyxy, vec4(-2.0, 0.0, 0.0, -2.0), vTexCoord0.xyxy);

    // Calculate the threshold:
    vec2 threshold = vec2(SMAA_THRESHOLD);

    // Calculate lumas:
    vec3 weights = vec3(0.2126, 0.7152, 0.0722);
    float L = dot(texture(colorTex, vTexCoord0).rgb, weights);

    float Lleft = dot(texture(colorTex, vOffset[0].xy).rgb, weights);
    float Ltop = dot(texture(colorTex, vOffset[0].zw).rgb, weights);

    // We do the usual threshold:
    vec4 delta;
    delta.xy = abs(L - vec2(Lleft, Ltop));
    vec2 edges = step(threshold, delta.xy);

    // Then discard if there is no edge:
    if (dot(edges, vec2(1.0, 1.0)) == 0.0)
        discard;

    // Calculate right and bottom deltas:
    float Lright = dot(texture(colorTex, vOffset[1].xy).rgb, weights);
    float Lbottom = dot(texture(colorTex, vOffset[1].zw).rgb, weights);
    delta.zw = abs(L - vec2(Lright, Lbottom));

    // Calculate the maximum delta in the direct neighborhood:
    vec2 maxDelta = max(delta.xy, delta.zw);

    // Calculate left-left and top-top deltas:
    float Lleftleft = dot(texture(colorTex, vOffset[2].xy).rgb, weights);
    float Ltoptop = dot(texture(colorTex, vOffset[2].zw).rgb, weights);
    delta.zw = abs(vec2(Lleft, Ltop) - vec2(Lleftleft, Ltoptop));

    // Calculate the final maximum delta:
    maxDelta = max(maxDelta.xy, delta.zw);
    float finalDelta = max(maxDelta.x, maxDelta.y);

    // Local contrast adaptation:
    edges.xy *= step(finalDelta, SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR * delta.xy);

    fragColor.xy = edges;
    fragColor.z = 0.0;
    fragColor.w = 1.0;
}
