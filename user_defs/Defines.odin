package user_defs;

Attribute_location :: enum {
	//Default, used by the library, don't remove or rename.
	position, // Shader location: vertex attribute: position
    texcoord, // Shader location: vertex attribute: texcoord01
    normal, // Shader location: vertex attribute: normal

	//for instancing
	instance_position,
	instance_scale,
	instance_rotation,
	instance_tex_pos_scale,
	
	///////// user attributes below /////////
	tangent,
	color,
}

Uniform_location :: enum {

	//Per Frame
	time,
	delta_time,	

	//Per camera
	prj_mat,
	inv_prj_mat,
	
	view_mat,
	inv_view_mat,

	view_prj_mat,
	inv_view_prj_mat,

	//Per model
	mvp,
	inv_mvp,		//will it ever be used?

	model_mat,
	inv_model_mat,	//will it ever be used?
	
	color_diffuse,

	///////// user uniforms below /////////
	
	sun,
}

Texture_location :: enum {
	//Textures
	texture_diffuse,
}