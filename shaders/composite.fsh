#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform vec3 shadowLightPosition;
uniform vec3 moonPosition;
uniform int worldTime;

uniform mat4 gbufferProjectionInverse;

in vec2 texcoord;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
    vec4 homPos = projectionMatrix * vec4(position, 1.0);
    return homPos.xyz / homPos.w;
}

vec3 linear_fog(vec3 inColor, float vertexDistance, float fogEnd, vec3 fogColor) {
    float brightness = 0.2989 * inColor.r + 0.5870 * inColor.g + 0.1140 * inColor.b;
    float targetAttenuation = brightness/10; // 1% visibility at fog ending
    float cfogEnd = max(fogEnd, 0.0001);
    float density = -log(targetAttenuation) / cfogEnd;
    float factor = exp(-density * max(vertexDistance, 0.0));

    fogColor = mix(fogColor, inColor, brightness/10);

    factor = clamp(factor, 0.0, 1.0);

    vec3 finalColor = mix(fogColor, inColor, factor);

    return finalColor;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    color = texture(colortex0, texcoord);

    bool isNight = shadowLightPosition == moonPosition;
    float depth = texture(depthtex0, texcoord).r;

    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);

//    float brightness = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
    float len = length(viewPos);
    float base = 15;
    float factor = 0;
    float wt = worldTime;
    if (isNight) {
        float s = smoothstep(0, 200, wt-12785);
        factor = s;
    } else {
        if (worldTime >= 23215) {
            float s = 1f-smoothstep(0, 200, wt-23215);
            factor = s;
        } else {
            factor = 0;
        }
    }
    color.rgb = mix(color.rgb, linear_fog(color.rgb, len, base, vec3(0.0)), factor);
//    float density = -log(brightness/10) / max(25, 0.0001);
//    float att = exp(-density * max(len, 0.0));
//    att = clamp(att, 0.0, 1.0);
//
//    color = vec4(mix(vec3(0.0).rgb, color.rgb, brightness/10), color.a);
}