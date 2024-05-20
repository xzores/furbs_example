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

shader_defs : map[string]string = {
	"red_amount_or_something" = "1.0",
}

Vertex :: struct {
	position : [3]f32,
	texcoord : [2]f32,
	color : [4]f32,
	//normal : [3]f32,
	//something : [4]f32 	`ignore:"true"`, 		//this will be uploaded to the GPU, but it will not be accessable as an attribute.
	//texcoord : [2]f32 	`normalized:"true"`,	//normalized
}

/*
TODO
WINDOW fullscreen, test for secoundary window and make current one work
See more in window, a lot of no done functions
TODO test that running without a main window works.
Make VAO's like active texture (client side)
TODO upload consistent instance data and mesh data.

Finish the opengl wrapper to use odin arrays and enums and bitsets.
when using double buffering uploading all data every frame, there should be a keep_consistent variable.
When that is done you can do more complicated meshing stuff and get ready for particals.

When that is done do 3D textures.
When that is done do a tool that can generate 3D textures from 2D textures (and sell on steam).
*/

vertex_data : []Vertex = {
	{{-1,-1,0}, {0,0}, {0,0,1,0}},
	{{1,-1,0}, {1,0}, {0,1,0,1}},
	{{1,1,0}, {1,1}, {1,0,0,1}},

	{{1,1,0}, {1,1}, {1,0,0,1}},
	{{-1,1,0}, {0,1}, {0,0,1,0}},
	{{-1,-1,0}, {0,0}, {0,0,1,0}},
}

Ball :: struct {
	position, velocity : [3]f32,
}

Eye :: struct {
	position : [3]f32,
}


main1 :: proc () {

	context.logger = utils.create_console_logger(.Info);
	
	utils.init_tracking_allocators();
	{
		//Just for memory stuff
		context.allocator = utils.make_tracking_allocator();
		
		//Begin of code
		using render;
		
		start_time := time.now();
		
		uniform_spec 	: [Uniform_location]Uniform_info = {};		//TODO make these required	
		attribute_spec 	: [Attribute_location]Attribute_info = {}; 	//TODO make these required
		
		window_desc : Window_desc = {
			width = 600,
			height = 600,
			title = "my main window",
			resize_behavior = .resize_backbuffer,
			antialiasing = .msaa8,
		}
		
		window := init(uniform_spec, attribute_spec, shader_defs, required_gl_verion = .opengl_4_5, window_desc = window_desc, pref_warn = true);
		defer destroy();

		window_set_vsync(false);

		my_balls 			: []Ball = make([]Ball, 10000);
		my_instance_data 	: []Default_instance_data = make([]Default_instance_data, len(my_balls));
		defer delete(my_balls);
		defer delete(my_instance_data);

		sd, si := generate_sphere(use_index_buffer = false);
		instance_desc := Instance_data_desc{data_type = Default_instance_data, data_points = len(my_balls), usage = .dynamic_upload};
		my_sphere_instanced := make_mesh_buffered(2, len(sd), Default_vertex, indices_len(si), .no_index_buffer, .dynamic_use, .triangles, instance_desc);
		upload_vertex_data(&my_sphere_instanced, 0, sd);
		delete(sd);	indices_delete(si);
		defer mesh_destroy(&my_sphere_instanced);

		my_pipeline_instanced := pipeline_make(get_default_instance_shader(), culling = .back_cull);

		camera : Camera3D = {
			position 	= {0,0,-10},
			target 		= {0,0,0},
			up			= {0,1,0},
			fovy     	= 90,
			ortho_height = 10,
			projection	= .perspective,
			near 		= 0.1,
			far 		= 1000,
		};
	
		for !window_should_close(window) {
			begin_frame();

			for &ball, i in my_balls {
				if linalg.length(ball.position) > 10 {
					ball = Ball{position = [3]f32{0, 0, 0}, velocity = [3]f32{2*rand.float32() - 1, 10 * rand.float32(),2*rand.float32() -1}};
				}
				ball.position += ball.velocity * state.delta_time;
				ball.velocity += [3]f32{0,-7,0} * state.delta_time;
				
				my_instance_data[i].instance_position 	= ball.position;
				my_instance_data[i].instance_scale 		= {1,1,1};
				l_mat := look_at({0,0,0}, camera.position - ball.position, {0,1,0});
				my_instance_data[i].instance_rotation = {0,180,0}; //extract_rotation_from_matrix(l_mat);
				my_instance_data[i].instance_tex_pos_scale 	= {0,0,1,1};
			}
			
			upload_instance_data_buffered(&my_sphere_instanced, 0, my_instance_data, false);
			
			target_begin(window, [4]f32{0.5,0.5,0.5,1});	
				pipeline_begin(my_pipeline_instanced, camera);
					set_texture(.texture_diffuse, texture2D_get_white());
					mesh_draw_instanced(&my_sphere_instanced, len(my_balls)); //Draw like this.
				pipeline_end();
			target_end();
			
			draw_coordinate_overlay(window, camera);
			draw_fps_overlay(window);

			end_frame();
			mem.free_all(context.temp_allocator);
		}

	}
	
	utils.print_tracking_memory_results();
	utils.destroy_tracking_allocators();

	fmt.printf("Successfully closed\n");
}

main :: proc () {
	
	context.logger = utils.create_console_logger(.Info);
	
	utils.init_tracking_allocators();
	{
		//Just for memory stuff
		context.allocator = utils.make_tracking_allocator();

		//Begin of code
		using render;
		
		start_time := time.now();
		
		uniform_spec 	: [Uniform_location]Uniform_info = {};		//TODO make these required	
		attribute_spec 	: [Attribute_location]Attribute_info = {}; 	//TODO make these required
		
		window_desc : Window_desc = {
			width = 600,
			height = 600,
			title = "my main window",
			resize_behavior = .resize_backbuffer,
			antialiasing = .msaa8,
		}
		
		//this window is optional and will be destroyed by render.destroy(). It must live for the entirety of the program.
		window := init(uniform_spec, attribute_spec, shader_defs, required_gl_verion = .opengl_4_5, window_desc = window_desc, pref_warn = true);
		//init(uniform_spec, attribute_spec, shader_defs, required_gl_verion = .opengl_3_3);
		defer destroy();
		
		//window := make_window_desc(window_desc);
		//defer destroy_window(window);
		window_2 := window_make(400, 400, "my_window_2", .resize_backbuffer, .none);
		defer window_destroy(window_2);

		my_frame_buffer := frame_buffer_make_textures(1, 400, 400, .RGBA8, .depth_component32, false, .nearest);
		defer frame_buffer_destroy(my_frame_buffer);
		
		//window_set_mouse_mode(window, .bound);
		
		//Sets the cursor for the window
		img, err := png.load("examples/res/cursor/Cursor Default Friends.png", {.alpha_add_if_missing})
		window_set_cursor_icon(window, img.width, img.height, img.pixels.buf[:]);
		png.destroy(img);
		
		my_shader, e := shader_load_from_path("my_shader.glsl");
		assert(e == nil, "failed to load shader");
		defer shader_destroy(my_shader);
		
		//A pipeline is a collection of OpenGL states, a render target and a shader.
		//The target can be a window to draw to the screen or an FBO for drawing to a texture.
		my_pipeline := pipeline_make(get_default_shader(), culling = .back_cull);
		my_pipeline_instanced := pipeline_make(get_default_instance_shader(), culling = .back_cull);
		my_pipeline2 := pipeline_make(my_shader, culling = .back_cull);
		//my_pipeline3 := pipeline_make(window_2, my_shader, culling = .back_cull);
		
		//my_mesh := make_mesh(vertex_data, nil, .sinsgle, .dynamic_use);
		my_quad := make_mesh_quad({1,1,1}, {0,0,0}, false);
		my_cirle := make_mesh_circle(1, {0,0,0}, 20, true);
		my_cube := make_mesh_cube(1, {0,0,0}, true);
		my_cylinder := make_mesh_cylinder({0,0,0}, 1, 1, 20, 20, true);
		my_sphere := make_mesh_sphere({0,0,0}, 1, 20, 20, true);
		my_cone := make_mesh_cone({0,0,0}, 1, 1, 20, true);
		my_arrow := make_mesh_arrow({1,0,0}, 1, 0.6, 0.25, 0.7, 20, true);
		defer mesh_destroy(&my_quad);
		defer mesh_destroy(&my_cirle);
		defer mesh_destroy(&my_cube);
		defer mesh_destroy(&my_cylinder);
		defer mesh_destroy(&my_sphere);
		defer mesh_destroy(&my_cone);
		defer mesh_destroy(&my_arrow);
		
		my_balls 			: []Ball = make([]Ball, 10000);
		my_instance_data 	: []Default_instance_data = make([]Default_instance_data, len(my_balls));
		defer delete(my_balls);
		defer delete(my_instance_data);
		
		my_eyes 				: []Eye = make([]Eye, 100);
		my_eye_instance_data 	: []Default_instance_data = make([]Default_instance_data, len(my_eyes));
		defer delete(my_eyes);
		defer delete(my_eye_instance_data);
		
		sd, si := generate_sphere(use_index_buffer = false);
		instance_desc := Instance_data_desc{data_type = Default_instance_data, data_points = len(my_balls), usage = .dynamic_upload};
		//my_sphere_instanced := mesh_make_single(sd, si, .static_use, .triangles, instance_desc);
		//TODO VSYNC OFF, double buffering bug.
		my_sphere_instanced := make_mesh_buffered(10, len(sd), Default_vertex, indices_len(si), .no_index_buffer, .dynamic_use, .triangles, instance_desc);
		upload_vertex_data(&my_sphere_instanced, 0, sd);
		delete(sd);	indices_delete(si);
		defer mesh_destroy(&my_sphere_instanced);
		
		for &ball, i in my_balls {
			ball = Ball{position = [3]f32{-6, 0, 0}, velocity = [3]f32{2*rand.float32() - 1, 10 * rand.float32(),2*rand.float32() -1}};
		}

		for &eye, i in my_eyes {
			eye = Eye{position = [3]f32{0, 0, 0}};
		}

		//The super mesh changes mesh every frame, try and use single, double, triple and auto buffering. Also try to use dynamic_use and stream_use.
		mesh_datas : [6]struct{verts : []Default_vertex, indicies : Indices};
		cur_mesh_datas : int = 0;
		v_size, i_size : int;
		{
			cubev, cubei := generate_cube(1, {0,0,0}, true);
			mesh_datas[0] = {cubev, cubei};
			cirv, ciri := generate_circle(1, {0,0,0}, 20, true);
			mesh_datas[1] = {cirv, ciri};
			qv, qi := generate_quad({1,1,1}, {0,0,0}, true);
			mesh_datas[2] = {qv, qi};
			cyv, cyi := generate_cylinder({0,0,0}, 1, 1, 20, 20, true);
			mesh_datas[3] = {cyv, cyi};
			sv, si := generate_sphere({0,0,0}, 1, 50, 50, true);
			mesh_datas[4] = {sv, si};
			conv, coni := generate_cone({0,0,0}, 1, 1, 20, true);
			mesh_datas[5] = {conv, coni};
			v_size = math.max(len(qv), len(cirv), len(cubev), len(cyv), len(sv), len(conv));
			i_size = math.max(indices_len(qi), indices_len(ciri), indices_len(cubei), indices_len(cyi), indices_len(si), indices_len(coni));
		}
		
		my_super_mesh := make_mesh_buffered(2, v_size, render.Default_vertex, i_size, .unsigned_short, .dynamic_use);
		//my_super_mesh := mesh_make_single_empty(v_size, render.Default_vertex, i_size, .unsigned_short, .dynamic_use);

		defer {
			for m in mesh_datas {
				delete(m.verts); indices_delete(m.indicies);
			}
			mesh_destroy(&my_super_mesh);
		}
		mesh_resize(&my_super_mesh, my_super_mesh.vertex_count * 2, my_super_mesh.index_count * 2);

		fmt.printf("v_size : %v\n", v_size);
		
		camera : Camera3D = {
			position 	= {0,0,-10},
			target 		= {0,0,0},
			up			= {0,1,0},
			fovy     	= 90,
			ortho_height = 10,
			projection	= .perspective,
			near 		= 0.1,
			far 		= 1000,
		};
		
		//tex := texture2D_make(512, 512, false, .repeat, .linear, .RGBA8, .no_upload, nil);
		tex := texture2D_load_from_file("examples/res/textures/dirt.png", {.clamp_to_edge, .nearest, false, .RGBA8});
		defer texture2D_destroy(&tex);

		tex2 := texture2D_load_from_file("examples/res/textures/test.png", {.repeat, .nearest, true, .RGBA8});
		defer texture2D_destroy(&tex2);

		tex3 := my_frame_buffer.color_attachments[0].(render.Texture2D);
		
		tex_up := texture2D_load_from_file("examples/res/textures/up.png", {.repeat, .nearest, true, .RGBA8});
		defer texture2D_destroy(&tex_up);
		
		tex_eye := texture2D_load_from_file("examples/res/textures/eye.png", {.repeat, .nearest, true, .RGBA8});
		defer texture2D_destroy(&tex_eye);
		
		cam_rot : [2]f32;
		speed : f32 = 10;
		last_frame := time.now();
		vsync : bool = true;
		fullscreen : render.Fullscreen_mode = .windowed;
		window_set_vsync(vsync);
		
		for !window_should_close(window) {

			if fullscreen != window.current_fullscreen {
				window_set_fullscreen(state.window_in_focus, fullscreen);
				fmt.printf("setting screen mode : %v\n", fullscreen);
			}

			begin_frame();

			if is_key_pressed(.f5) {
				shader_reload_all(); //return a list of the shaders failing to reload, and keep using the old ones...
			}
			if is_key_pressed(.f7) {
				vsync = !vsync;
				window_set_vsync(vsync);
				fmt.printf("VSYNC : %v\n", vsync);
			}
			if is_key_pressed(.f11) {
				if fullscreen != .windowed {
					fullscreen = .windowed
				}
				else {
					fullscreen = .fullscreen;
				}
			}
			
			now :=  time.now();
			t : f32 = cast(f32)time.duration_seconds(time.diff(start_time, now));
			dt : f32 = cast(f32)time.duration_seconds(time.diff(last_frame, now));
			last_frame = now;
			
			for &ball, i in my_balls {
				if linalg.length(ball.position) > 10 {
					ball = Ball{position = [3]f32{-6, 0, 0}, velocity = [3]f32{2*rand.float32() - 1, 10 * rand.float32(),2*rand.float32() -1}};
				}
				ball.position += ball.velocity * dt;
				ball.velocity += [3]f32{0,-7,0} * dt;
				
				my_instance_data[i].instance_position 	= ball.position;
				my_instance_data[i].instance_scale 		= {1,1,1};
				l_mat := look_at({0,0,0}, camera.position - ball.position, {0,1,0});
				my_instance_data[i].instance_rotation = {0,180,0}; //extract_rotation_from_matrix(l_mat);
				my_instance_data[i].instance_tex_pos_scale 	= {0,0,1,1};
			}
			
			upload_instance_data_buffered(&my_sphere_instanced, 0, my_instance_data, false);
			//upload_instance_data(&my_sphere_instanced, 0, my_instance_data);
			
			if is_key_down(Key_code.d) {
				camera_move(&camera, speed * camera_right(camera) * dt);
			}
			if is_key_down(Key_code.a) {
				camera_move(&camera, -speed * camera_right(camera) * dt);
			}
			if is_key_down(Key_code.w) {
				camera_move(&camera, speed * camera_forward_horizontal(camera) * dt);
			}
			if is_key_down(Key_code.s) {
				camera_move(&camera, -speed * camera_forward_horizontal(camera) * dt);
			}
			if is_key_down(Key_code.space) {
				camera_move(&camera, speed * camera.up * dt);
			}
			if is_key_down(Key_code.control_left) {
				camera_move(&camera, -speed * camera.up * dt);
			}
			if is_key_down(.kp_add) {
				speed *= 1.1;
			}
			if is_key_down(.kp_subtract) {
				speed /= 1.1;
			}
			
			cam_rot += 0.1 * {state.mouse_delta.x, state.mouse_delta.y}; //mouse_delta.y
			cam_rot.y = math.clamp(cam_rot.y, -89, 89);
			camera_rotation(&camera, cam_rot.x, cam_rot.y);
			
			//upload a new mesh to the super mesh
			upload_vertex_data_buffered(&my_super_mesh, 0, mesh_datas[cur_mesh_datas].verts, true);
			upload_index_data_buffered(&my_super_mesh, 0, mesh_datas[cur_mesh_datas].indicies, true);
			cur_mesh_datas = (int(t*3)) %% len(mesh_datas);	
			
			target_begin(&my_frame_buffer, [4]f32{1,0,0,0.5});
				pipeline_begin(my_pipeline2, camera);
					set_texture(.texture_diffuse, tex2);
					mesh_draw(&my_arrow, linalg.matrix4_translate_f32({-2,0,0}));
					mesh_draw(&my_cube, 1);
					mesh_draw(&my_cirle, linalg.matrix4_translate_f32({1.5,0,0}));
					mesh_draw(&my_quad, linalg.matrix4_translate_f32({3,0,0}));
					mesh_draw(&my_cylinder, linalg.matrix4_translate_f32({4.5,0,0}));
					mesh_draw(&my_sphere, linalg.matrix4_translate_f32({6,0,0}));
					mesh_draw(&my_cone, linalg.matrix4_translate_f32({7.5,0,0}));
					mesh_draw(&my_super_mesh, linalg.matrix4_translate_f32({9,0,0}));
				pipeline_end();
			target_end();

			/*
			pipeline_begin(my_pipeline3, camera, [4]f32{0.3,0.2,0.1,1});
			set_texture(.texture_diffuse, tex2);
			mesh_draw(&my_arrow, linalg.matrix4_translate_f32({-3,0,0}));
			mesh_draw(&my_cube, 1);
			mesh_draw(&my_cirle, linalg.matrix4_translate_f32({1.5,0,0}));
			mesh_draw(&my_quad, linalg.matrix4_translate_f32({3,0,0}));
			mesh_draw(&my_cylinder, linalg.matrix4_translate_f32({4.5,0,0}));
			mesh_draw(&my_sphere, linalg.matrix4_translate_f32({6,0,0}));
			mesh_draw(&my_cone, linalg.matrix4_translate_f32({7.5,0,0}));
			mesh_draw(&my_super_mesh, linalg.matrix4_translate_f32({9,0,0}));
			pipeline_end(my_pipeline2);
			*/

			target_begin(window, [4]f32{0.05,0.03,0.1,1});
				
				pipeline_begin(my_pipeline, camera);
					set_texture(.texture_diffuse, tex);
					mesh_draw(&my_arrow, linalg.matrix4_translate_f32({-2,0,0}));
					mesh_draw(&my_cube, 1);
					mesh_draw(&my_cirle, linalg.matrix4_translate_f32({1.5,0,0}));
					mesh_draw(&my_quad, linalg.matrix4_translate_f32({3,0,0}));
					mesh_draw(&my_cylinder, linalg.matrix4_translate_f32({4.5,0,0}));
					mesh_draw(&my_sphere, linalg.matrix4_translate_f32({6,0,0}));
					mesh_draw(&my_cone, linalg.matrix4_translate_f32({7.5,0,0}));
					mesh_draw(&my_super_mesh, linalg.matrix4_translate_f32({9,0,0}));

					set_texture(.texture_diffuse, tex2); //Draw below
					draw_cube(linalg.matrix4_translate_f32({0,-2,0}));
					draw_circle(linalg.matrix4_translate_f32({1.5,-2,0}));
					draw_quad(linalg.matrix4_translate_f32({3,-2,0}));
					draw_cylinder(linalg.matrix4_translate_f32({4.5,-2,0}));
					draw_sphere(linalg.matrix4_translate_f32({6,-2,0}));
					draw_cone(linalg.matrix4_translate_f32({7.5,-2,0}));
					set_texture(.texture_diffuse, texture2D_get_white());
					draw_arrow({9,-2,0}, {1,0,0}, {1,0,0,1});
					draw_arrow({9,-4,0}, {-1,0,0}, {0.5,0,0,1});
					draw_arrow({9,-6,0}, {0,1,0}, {0,1,0,1});
					draw_arrow({9,-8,0}, {0,-1,0}, {0,0.5,0,1});
					draw_arrow({9,-10,0}, {0,0,1}, {0,0,1,1});
					draw_arrow({9,-12,0}, {0,0,-1}, {0,0,0.5,1});
					draw_arrow({9,2,0}, {1,1,1}, {1,1,1,1});

					set_texture(.texture_diffuse, tex3);
					mesh_draw(&my_quad, linalg.matrix4_translate_f32({0,2.1,0})); //place 1 is model_matrix for identity matrix
					
					set_texture(.texture_diffuse, tex_eye);
					draw_cube(look_at({0,10,0}, camera.position, {0,1,0}));
					draw_sphere(look_at({5,5,-5}, camera.position, {0,1,0}));
					
				pipeline_end();
				
				cam2d : Camera2D = {
					position 		= {0,0},		// Camera position
					target_relative = {0,0},		// 
					rotation 		= 0,			// in degrees
					zoom 			= 1,            //
					near 			= -2,
					far 			= 2,
				};

				pipeline_begin(my_pipeline_instanced, camera);
					//Dont draw with this mesh_draw(&my_sphere_instanced, 1);
					mesh_draw_instanced(&my_sphere_instanced, len(my_balls)); //Draw like this.
				pipeline_end();

				//Draw a small quad in the center of the screen.
				pipeline_begin(my_pipeline2, cam2d);
					set_texture(.texture_diffuse, texture2D_get_white());
					draw_quad(linalg.matrix4_scale_f32({0.01,0.01,1})); //place 1 is model_matrix for identity matrix
				pipeline_end();
				
				text_draw_simple("Hello World", {0,0}, 100);

			target_end();
			
			draw_coordinate_overlay(window, camera);
			draw_fps_overlay(window);

			end_frame();
			mem.free_all(context.temp_allocator);
		}
	}
	
	utils.print_tracking_memory_results();
	utils.destroy_tracking_allocators();

	fmt.printf("Successfully closed\n");
}

