#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform vec3 shadowLightPosition;
uniform vec3 moonPosition;
uniform int worldTime;
uniform float far;

uniform mat4 gbufferProjectionInverse;

in vec2 texcoord;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
	vec4 homPos = projectionMatrix * vec4(position, 1.0);
	return homPos.xyz / homPos.w;
}

bool sizeCheck(vec3 color) {
	float avg = (color.r + color.g + color.b) / 3;
	return avg <= 0.05;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	if (sizeCheck(color.rgb)) return;

	float depth = texture(depthtex0, texcoord).r;

	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);

	bool isNight = shadowLightPosition == moonPosition;
	float len = length(viewPos);
	float base = 0;
	float wt = worldTime;
//	if (isNight) {
//		base = 1f-smoothstep(0, 200, wt-12785);
//	} else {
//		if (worldTime <= 23215) {
//			base = 1f-smoothstep(0, 200, wt-23215);
//		} else {
//			base = 1;
//		}
//	}

	float modifier = mix(smoothstep(0, 15, len-5), 0, base);

	if (modifier == 0 || base == 1) return;

	// Calculate the size of one pixel in texture coordinates (UV space)
	vec2 texelSize = 1.0 / textureSize(colortex0, 0); // Gets size of mipmap level 0

	// --- Simple 3x3 Box Blur ---
	vec4 blurredColor = vec4(0.0);
	float kernelWeight = 0.0; // Keep track if using varying weights, for box blur it's just 1/N

	// Sample a 11x11 grid around the current pixel
	for (int x = -10; x <= 10; x++) {
		for (int y = -10; y <= 10; y++) {
			vec2 offset = vec2(float(x), float(y)) * texelSize;
			blurredColor += texture(colortex0, texcoord + offset);
			kernelWeight++;// For box blur, each sample has equal weight
		}
	}

	// --- Interpolate based on blurIntensity ---
	// mix(x, y, a) = x * (1.0 - a) + y * a
	// When blurIntensity = 0.0, result is originalColor
	// When blurIntensity = 1.0, result is blurredColor
	vec4 finalColor = mix(color, blurredColor/kernelWeight, modifier);

	color = mix(color, finalColor, clamp(0, 1, length(viewPos)/5));
}