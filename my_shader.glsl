#include "other_shader.glsl" //includes are relative to the file
//#require blend_mode one_minus_src_alpha //TODO this could be another feature

///Vertex shader begin
@vertex
layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texcoord;
layout (location = 2) in vec3 normal;

layout (location = 3) in vec3 instance_position;

uniform mat4 prj_mat;
uniform mat4 inv_prj_mat;

uniform mat4 view_mat;
uniform mat4 inv_view_mat;

uniform mat4 mvp;
uniform mat4 inv_mvp;

uniform mat4 model_mat;
uniform mat4 inv_model_mat;

out vec2 texture_coords;

void main() {
	texture_coords = texcoord;
    gl_Position = mvp * vec4(position + instance_position, 1.0);
}


///Fragment shader begin
@fragment

uniform sampler2D texture_diffuse;

in vec2 texture_coords;

out vec4 FragColor;

void main() {
	vec4 texColor = texture(texture_diffuse, texture_coords);

    FragColor = texColor + vec4(0, 0, 0, 0);
}

