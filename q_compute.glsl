
///Vertex shader begin
@vertex

//// Attributes ////
layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texcoord;

//// Uniforms ////
uniform mat4 mvp;

//// Outputs ////
out vec2 texture_coords;
out vec4 pos;

void main() {
	texture_coords = texcoord;
	
	pos = vec4(position, 1);
	
	//pos.x = -pos.x;
	//pos = pos + vec4(0, 0, sin(time*1),0);

	//TODOs test again
	//float t = (sin(time) + 1) / 2;
	//t = 0.3;
	//vec4 pos2 = mvp * pos;
	//pos = pos2 * t + (1 - t) * pos;

	gl_Position = mvp * pos;
}


///Fragment shader begin
@fragment

#define PI 3.1415926538
#define e 2.71828

//Inputs
in vec2 texture_coords;
in vec4 pos;

//// Uniforms ////
uniform sampler2D texture_1;
uniform sampler2D texture_2;

//uniform float sample_dist; //between 0-1 for unit sized textures.
uniform uint tex_size;

//// Outputs ////
out vec4 FragColor;

void main() {

	float sample_dist = 1.0 / float(tex_size);
	
	int pixels_out = 1; //int(sample_dist * tex_size);
	float pixels_dist = 1.0 / float(tex_size);
	
	vec4 c = vec4(0,0,0,0);
	
	for (int x = -pixels_out; x <= pixels_out; x++) {
		for (int y = -pixels_out; y <= pixels_out; y++) {

			if (x == 0 && y == 0) {
				continue;;
			}
			
			//s is between 0 and sample_dist
			vec2 s = vec2(float(x), float(y));
			vec4 tex_1 = texture(texture_1, texture_coords + s * pixels_dist);
			
			c.x += tex_1.x / length(s);
			c.y += tex_1.y / length(s);
			c.z += tex_1.z / length(s);
			//c.w += tex_1.w;
		}
	}

	//c = c / (3.14 * float(pixels_out * pixels_out));
	c = 1.0005 * c / (4 + 4 * 1/sqrt(2));

	vec4 res;

	res.x = c.x + c.y * c.z;
	res.y = c.y + c.z * c.x;
	res.z = c.z + c.x * c.y;
	

    FragColor = res;
}

