
///Vertex shader begin
@vertex

//// Attributes ////
layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texcoord;
layout (location = 2) in vec3 normal;

layout (location = 3) in vec3 instance_position_offset;
layout (location = 4) in vec3 instance_scale_offset;
layout (location = 5) in vec4 instance_texcoord_offset;

//// Uniforms ////
uniform float time;
uniform mat4 delta_time;

uniform mat4 prj_mat;
uniform mat4 inv_prj_mat;

uniform mat4 view_mat;
uniform mat4 inv_view_mat;

uniform mat4 view_prj_mat;
uniform mat4 inv_view_prj_mat;

uniform mat4 model_mat;
uniform mat4 inv_model_mat;

uniform mat4 mvp;
uniform mat4 inv_mvp;

//// Outputs ////
out vec2 texture_coords;
out vec4 pos;

void main() {
	texture_coords = (texcoord * (instance_texcoord_offset.zw)) + instance_texcoord_offset.xy;
	
	pos = vec4((position * instance_scale_offset) + instance_position_offset, 1);
	
	//TODOs test again
	//float t = (sin(time) + 0.999) / 2;
	//vec4 pos2 = mvp * pos;
	//pos = pos2 * t + (1 - t) * pos;

	gl_Position = mvp * pos;
}



///Fragment shader begin
@fragment

//Inputs
in vec2 texture_coords;
in vec4 pos;

//// Uniforms ////
uniform sampler2D texture_diffuse;
uniform vec4 color_diffuse = vec4(1,1,1,1);

//// Outputs ////
out vec4 FragColor;

void main() {
	vec4 tex_color = texture(texture_diffuse, texture_coords);
	
    FragColor = color_diffuse * vec4(1, 1, 1, tex_color.r);
}

