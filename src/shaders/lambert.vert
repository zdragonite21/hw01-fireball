#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model; // The matrix that defines the transformation of the
// object we're rendering. In this assignment,
// this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr; // The inverse transpose of the model matrix.
// This allows us to transform the object's normals properly
// if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj; // The matrix that defines the camera's transformation.
// We've written a static matrix for you to use for HW2,
// but in HW3 you'll have to generate one yourself

uniform uint u_Frame;

in vec4 vs_Pos; // The array of vertex positions passed to the shader

in vec4 vs_Nor; // The array of vertex normals passed to the shader

in vec4 vs_Col; // The array of vertex colors passed to the shader.

out vec4 fs_Nor; // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_Col; // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_posW;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
//the geometry in the fragment shader.

// Matrix for breaking grid alignment in 3D noise
const mat3 m3 = mat3(0.00, 0.80, 0.60,
        -0.80, 0.36, -0.48,
        -0.60, -0.48, 0.64);

float hash3Scalar(vec3 p3) {
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// from IQ's blog
float noised1(in vec3 x)
{
    vec3 p = floor(x);
    vec3 w = fract(x);

    vec3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    // vec3 du = 30.0*w*w*(w*(w-1.0)+2.0);
    vec3 du = 30.0 * w * w * (w * (w - 2.0) + 1.0);

    float a = hash3Scalar(p + vec3(0, 0, 0));
    float b = hash3Scalar(p + vec3(1, 0, 0));
    float c = hash3Scalar(p + vec3(0, 1, 0));
    float d = hash3Scalar(p + vec3(1, 1, 0));
    float e = hash3Scalar(p + vec3(0, 0, 1));
    float f = hash3Scalar(p + vec3(1, 0, 1));
    float g = hash3Scalar(p + vec3(0, 1, 1));
    float h = hash3Scalar(p + vec3(1, 1, 1));

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = e - a;
    float k4 = a - b - c + d;
    float k5 = a - c - e + g;
    float k6 = a - b - e + f;
    float k7 = -a + b + c - d + e - f - g + h;

    return -1.0 + 2.0 * (k0 + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x + k7 * u.x * u.y * u.z);
}

float fbm(vec3 x, int octaves) {
    float h = 0.0;
    float f = 2.0;
    float a = 0.5;

    for (int i = 1; i <= octaves; i++) {
        h += noised1(x) * a;
        a *= 0.5;
        x *= m3 * f;
    }

    return h;
}

vec3 displace(vec3 pos) {
    float strength = pos.y * 0.5 + 0.5;
    float x = (1.0 - length(pos.xz));
    pos += strength * vec3(0, 1, 0) * x;

    return pos;
}

vec3 editNormal(vec3 p2, vec3 n) {
    return n;
}

vec3 perturb(vec3 pos, vec3 n) {
    const int step = 20;
    const float scale = 3.0;
    const int octaves = 3;

    float frame = floor(float(u_Frame) / float(step)) * float(step);
    float time = frame * 0.005;
    float strength = pos.y * 0.5 + 0.5;
    vec3 s = pos + vec3(time);
    s *= scale;

    float offset = fbm(s, octaves);
    offset = offset * 0.5 + 0.5;
    return pos + vec3(0, 1, 0) * offset * strength;
}

void main()
{
    fs_Col = vs_Col; // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    // Transform the geometry's normals by the inverse transpose of the
    // model matrix. This is necessary to ensure the normals remain
    // perpendicular to the surface after the surface is transformed by
    // the model matrix.

    vec3 p = vs_Pos.xyz;
    vec3 p2 = displace(p);
    vec3 n = invTranspose * vec3(vs_Nor);
    n = editNormal(p2, n);
    vec3 p3 = perturb(p2, n);

    // compute new normal
    float eps = 0.1;
    
    vec3 tan = cross(n, vec3(0, 0, 1));
    if (length(tan) < 0.001)
    {
        tan = cross(n, vec3(0, 1, 0));
    }
    tan = normalize(tan);
    vec3 bit = normalize(cross(n, tan));

    vec3 dtan = displace(p + eps * tan) - p3;
    vec3 dbit = displace(p + eps * bit) - p3;
    fs_Nor = vec4(normalize(cross(dtan, dbit)), 0.0);

    vec4 modelposition = u_Model * vec4(p3, 1.0); // Temporarily store the transformed vertex positions for use below
    fs_posW = modelposition;
    gl_Position = u_ViewProj * modelposition; // gl_Position is a built-in variable of OpenGL which is
    // used to render the final positions of the geometry's vertices
}
