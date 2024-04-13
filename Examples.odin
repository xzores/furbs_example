package main;

import "core:time"
import "core:math"
import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import "core:log"
import "core:mem"
import "core:runtime"

import "core:image/png"

import fs "vendor:fontstash"

import render "furbs/render"
//import gui "furbs/gui"
import "furbs/utils"

import gl "furbs/render/gl"

look_at_example :: proc () {
	using render;

	context.logger = utils.create_console_logger(.Info);

	utils.init_tracking_allocators();
	{
		uniform_spec 	: [Uniform_location]Uniform_info = {};		//TODO make these required	
		attribute_spec 	: [Attribute_location]Attribute_info = {}; 	//TODO make these required
		
		window_desc : Window_desc = {
			width = 600,
			height = 600,
			title = "my main window",
			resize_behavior = .resize_backbuffer,
			antialiasing = .msaa8,
		}
		
		window := init(uniform_spec, attribute_spec, shader_defs, required_gl_verion = .opengl_4_5, window_desc = window_desc, pref_warn = false);
		defer destroy();
		
		enable_vsync(true);

		tex_up 		: Texture2D = load_texture_2D_from_file("examples/res/textures/up.png");
		defer destroy_texture_2D(&tex_up);
		
		pipeline := make_pipeline(get_default_shader());
		
		cam : Camera2D = {
			position		= {0,0},            	// Camera position
			target_relative	= {0,0},				// 
			rotation		= 0,				// in degrees
			zoom 			= 0.1,            	//
			
			near 			= -10,
			far 			= 10,
		}

		pos : [3]f32 = {1,0,0};

		for !should_close(window) {
			begin_frame();

				if is_key_down(Key_code.d) {
					pos.x += 2 * delta_time();
				}
				if is_key_down(Key_code.a) {
					pos.x -= 2 * delta_time();
				}
				if is_key_down(Key_code.w) {
					pos.y += 2 * delta_time();
				}
				if is_key_down(Key_code.s) {
					pos.y -= 2 * delta_time();
				}
				if is_key_down(Key_code.up) {
					pos.z += 2 * delta_time();
				}
				if is_key_down(Key_code.down) {
					pos.z -= 2 * delta_time();
				}

				begin_target(window, [4]f32{0.3,0.3,0.3,0});
					
					look_mat := look_at({2,2,0}, pos, {0,0,-1});

					begin_pipeline(pipeline, cam);
						set_texture(.texture_diffuse, tex_up);
						draw_cube(look_mat);
						draw_cube(linalg.matrix4_translate_f32(pos));
					end_pipeline();
					
					draw_text_simple("This is text", {0,200}, 100, 0, {0,1,0,1});
					
				end_target();

			end_frame();
		}
	}
	
	utils.print_tracking_memory_results();
	utils.destroy_tracking_allocators();

	fmt.printf("Successfully closed\n");
}


main2 :: proc () {
	using render;

	context.logger = utils.create_console_logger(.Info);

	utils.init_tracking_allocators();
	{
		uniform_spec 	: [Uniform_location]Uniform_info = {};		//TODO make these required	
		attribute_spec 	: [Attribute_location]Attribute_info = {}; 	//TODO make these required
		
		window_desc : Window_desc = {
			width = 600,
			height = 600,
			title = "my main window",
			resize_behavior = .resize_backbuffer,
			antialiasing = .msaa8,
		}
		
		window := init(uniform_spec, attribute_spec, shader_defs, required_gl_verion = .opengl_4_5, window_desc = window_desc, pref_warn = false);
		defer destroy();
		
		enable_vsync(true);
		
		my_fbo : Frame_buffer;
		init_frame_buffer_textures(&my_fbo, 1, 512, 512, .RGBA8, .depth_component32, false, .nearest);
		defer destroy_frame_buffer(my_fbo);

		tex_color 	: Texture2D = my_fbo.color_attachments[0].(render.Texture2D);
		tex_depth 	: Texture2D = my_fbo.depth_attachment.(render.Texture2D);
		tex_up 		: Texture2D = load_texture_2D_from_file("examples/res/textures/up.png");
		defer destroy_texture_2D(&tex_up);
		
		pipeline := make_pipeline(get_default_shader(), depth_test = false);
		pipeline2 := make_pipeline(get_default_instance_shader(), .no_blend);
		
		my_balls : []Ball = make([]Ball, 1000);
		my_instance_data : []Default_instance_data = make([]Default_instance_data, len(my_balls));
		defer delete(my_balls);
		defer delete(my_instance_data);
		
		sd, si := generate_sphere(use_index_buffer = false);
		instance_desc := Instance_data_desc{data_type = Default_instance_data, data_points = len(my_balls), usage = .dynamic_upload};
		
		//my_sphere_instanced := make_mesh_single(sd, nil, .static_use, .triangles, instance_desc);
		my_sphere_instanced := make_mesh_buffered(2, len(sd), Default_vertex, 0, nil, .dynamic_use, .triangles, instance_desc);
		my_sphere := make_mesh_single(sd, nil, .static_use, .triangles);
		delete(sd);	delete_indices(si);
		defer destroy_mesh(&my_sphere_instanced);
		defer destroy_mesh(&my_sphere);
		
		for &ball, i in my_balls {
			ball = Ball{position = [3]f32{2*rand.float32() - 1, 2*rand.float32() - 1, 2*rand.float32() -1}, velocity = [3]f32{2*rand.float32() - 1, 10 * rand.float32(),2*rand.float32() -1}};
		}
		
		for &ball, i in my_balls {
			my_instance_data[i].instance_position 	= ball.position;
			my_instance_data[i].instance_scale 		= {1,1,1};
			my_instance_data[i].instance_rotation 	= {0,0,0};
			my_instance_data[i].instance_tex_pos_scale 	= {0,0,1,1};
		}

		//my_shader, err := load_shader_from_path("my_shader.glsl");
		//assert(err == nil);
		//defer unload_shader(my_shader); //TODO should it not be destroy_shader?
		
		/*cam : Camera2D = {
			position 		= [2]f32{0,0},      // Camera position
			target_relative = [2]f32{0,0},		// 
			rotation		= 0,				// in degrees
			zoom	 		= 1,            	//
			
			far 			= 1000,
			near			= 0.01,
		};*/
		
		cam : Camera3D = {
			position 		= {0,0,0},
			target 			= {0,0,1},
			up				= {0,1,0},
			fovy     		= 0, //unused for orthographic
			ortho_height 	= 1,
			projection		= .orthographic,
			near 			= -1000,
			far 			= 1000,
		};
		
		cam_3D : Camera3D = {
			position 		= {0,0,10},
			target 			= {0,0,0},
			up				= {0,1,0},
			fovy     		= 90,
			ortho_height 	= 0, //unused for perspective
			projection		= .perspective,
			near 			= 0.1,
			far 			= 1000,
		};

		for !should_close(window) {
			begin_frame();
				
				upload_instance_data_buffered(&my_sphere_instanced, 0, my_instance_data, false);

				begin_target(&my_fbo, [4]f32{0,0,0,0});
					draw_text_simple("Hello World", {0,0}, 100, 0, {0,0,0,1});
				end_target();
				
				begin_target(window, [4]f32{0.3,0.3,0.3,0});
					
					begin_pipeline(pipeline2, cam);
						draw_mesh_instanced(&my_sphere_instanced, len(my_balls)); //Draw like this.
					end_pipeline();

					begin_pipeline(pipeline, cam);
						//draw_mesh(&my_sphere, 1); //Draw like this.
					end_pipeline();

					/*
					begin_pipeline(pipeline, cam);
					set_texture(.texture_diffuse, tex_up);
					draw_quad(1);
					set_texture(.texture_diffuse, tex_color);
					draw_quad(1);
					end_pipeline();
					*/
					
					draw_text_simple("This is text", {0,200}, 100, 0, {0,1,0,1});
					
				end_target();

			end_frame();
		}
	}
	
	utils.print_tracking_memory_results();
	utils.destroy_tracking_allocators();

	fmt.printf("Successfully closed\n");
}

