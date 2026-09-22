#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec3 u_CamPos;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_Col;
in vec4 fs_posW;

out vec4 out_Col; // This is the final output color that you will see on your
// screen for the pixel that is currently being processed.

struct ColorStep {
    vec3 color;
    float t;
};

ColorStep colorRamp[4];

float fresnelSchlick(float cosTheta, float ior)
{
    float x = (1.0 - ior) / (1.0 + ior);
    float f0 = x * x;
    return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0);
}

vec3 getColorRamp(float t) {
    for (int i = 0; i < 3; ++i) {
        if (t <= colorRamp[i + 1].t) {
            return colorRamp[i].color;
        }
    }
    return colorRamp[3].color;
}

void main()
{
    colorRamp[0] = ColorStep(vec3(0.97, 0.22, 0), 0.0);
    colorRamp[1] = ColorStep(vec3(1.0, 0.5, .15), 0.04);
    colorRamp[2] = ColorStep(vec3(0.97, 0.87, .365), 0.175);
    colorRamp[3] = ColorStep(vec3(1.0, 0.97, .58), 0.54);

    const float ior = 1.5;
    vec3 v = normalize(u_CamPos - fs_posW.xyz);
    vec3 n = normalize(fs_Nor.xyz);
    float cosTheta = max(dot(n, v), 0.0);
    float fresnel = fresnelSchlick(cosTheta, ior);

    vec3 color = getColorRamp(fresnel);

    // Compute final shaded color
    out_Col = vec4(color, 1.0);
}
