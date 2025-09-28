#version 330

out vec4 fragColor;

uniform vec2 resolution;
uniform sampler2D texture0;
uniform sampler2D scene;
uniform int ssaa_factor;

void main() {
    ivec2 src = ivec2(gl_FragCoord.xy) * ssaa_factor;
    vec3 color =
        texelFetch(scene, src + ivec2(0, 0), 0).rgb +
            texelFetch(scene, src + ivec2(1, 0), 0).rgb +
            texelFetch(scene, src + ivec2(0, 1), 0).rgb +
            texelFetch(scene, src + ivec2(1, 1), 0).rgb;
    fragColor = vec4(color * 0.25, 1.0);
}
