package user_defs;

//DO NOT CHANGE THIS
Texture_slot :: distinct i32;

Attribute_location :: enum {
	//Default, used by the library, don't remove or rename.
	position, // Shader location: vertex attribute: position
    texcoord, // Shader location: vertex attribute: texcoord01
    normal, // Shader location: vertex attribute: normal

	///////// user attributes below /////////
	tangent
}

Uniform_location :: enum {

	//Per Frame
	game_time,
	real_time,

	//Per camera
	prj_mat,
	inv_prj_mat,
	
	view_mat,
	inv_view_mat,

	//Per model
	mvp,
	inv_mvp,		//will it ever be used?

	model_mat,
	inv_model_mat,	//will it ever be used?
	
	color_diffuse,
	
	//Textures
	texture_diffuse,

	//For text
	texcoords,

	///////// user uniforms below /////////
	
}

texture_locations : map[Uniform_location]Texture_slot = {
	.texture_diffuse = 0, ///= gl.TEXTURE0
	
	///////// user textures below /////////

}