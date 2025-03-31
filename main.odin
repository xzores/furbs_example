#+feature dynamic-literals
package main;

import "core:time"
import "core:math"
import "core:fmt"
import "core:slice"
import "core:math/linalg"
import "core:math/rand"
import "core:log"
import "core:mem"
import "core:strings"
import "core:thread"

import "base:runtime"

import "core:image"
import "core:image/png"


import render "furbs/render"
import gui "furbs/regui"
import fs "furbs/fontstash"
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
TODO:

Write to gingerbill about the preformence of libs in debug mode (image lib example)
Write to gingerbill about struct->union->struct and union->struct->union->struct duality (like how there is nothing to help)

TODO optimize texture atlas by not storing pixels client side. This requires a function that can copy from one texture to another.

Fontstash seems so broken I cannot use it, so it must be rewritten...
See more in window, a lot of not done functions
Disabling v-syn when not using a main window does not work, this is a bug.
Make VAO's like active texture (client side) in the opengl wrapper (because it works by having a default VAO and then swapping it), currently there is a bug.
TODO upload consistent instance data and mesh data. (currently there is a bug)

Make re-gui (retained gui)
TODO refactor the client side texture atlas into utils and make an option to do GPU side texture atlas, requires gpu to gpu texture copy (should also be done).
TODO make a better font-stash.

Finish the opengl wrapper to use odin arrays and enums and bitsets, see https://github.com/mtarik34b/opengl46-enum-wrapper.
when using double buffering uploading all data every frame, there should be a keep_consistent variable.
When that is done you can do more complicated meshing stuff and get ready for particals.

When that is done do 3D textures.
When that is done do a tool that can generate 3D textures from 2D textures.
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

main :: proc () {
	
	context.assertion_failure_proc = utils.init_stack_trace();
	defer utils.destroy_stack_trace();
	
	context.logger = utils.create_console_logger(.Info);
	defer utils.destroy_console_logger(context.logger);
	
	utils.init_tracking_allocators();
	
	{
		tracker : ^mem.Tracking_Allocator;
		context.allocator = utils.make_tracking_allocator(tracker_res = &tracker); //This will use the backing allocator,
		
		entry();
	}
	
	utils.print_tracking_memory_results();
	utils.destroy_tracking_allocators();
}


/*
entry :: proc () {
	using render;
	
	window_desc : Window_desc = {
		width = 600,
		height = 600,
		title = "my main window",
		resize_behavior = .allow_resize,
		antialiasing = .msaa8,
	}
	
	window := init(shader_defs, required_gl_verion = .opengl_4_5, window_desc = window_desc, pref_warn = true);
	defer destroy();

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

	speed : f32 = 3;
	
	my_pipeline := pipeline_make(get_default_shader(), culling = .back_cull);
	my_tex, ok := texture2D_load_from_file("test_image.png");
	assert(ok, "failed to load image");
	defer texture2D_destroy(my_tex);
	
	for !window_should_close(window) {
			begin_frame();
			
			if is_key_down(Key_code.d) {
				camera_move(&camera, speed * camera_right(camera) * delta_time());
			}
			if is_key_down(Key_code.a) {
				camera_move(&camera, -speed * camera_right(camera) * delta_time());
			}
			if is_key_down(Key_code.w) {
				camera_move(&camera, speed * camera_forward_horizontal(camera) * delta_time());
			}
			if is_key_down(Key_code.s) {
				camera_move(&camera, -speed * camera_forward_horizontal(camera) * delta_time());
			}
			if is_key_down(Key_code.space) {
				camera_move(&camera, speed * camera.up * delta_time());
			}
			if is_key_down(Key_code.control_left) {
				camera_move(&camera, -speed * camera.up * delta_time());
			}
			if is_key_down(.kp_add) {
				speed *= 1.1;
			}
			if is_key_down(.kp_subtract) {
				speed /= 1.1;
			}
			
			target_begin(window, [4]f32{0.5,0.5,0.5,1});
				pipeline_begin(my_pipeline, camera);
					set_texture(.texture_diffuse, my_tex);
					draw_cube_rts({0,0, 2}, {0,0,0}, {1,1,1}, {1,0.7,0.7,1});
				pipeline_end();
			target_end();
			
			draw_coordinate_overlay(window, camera);
			draw_fps_overlay(window);

			end_frame();
			mem.free_all(context.temp_allocator);
		}
	
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
		
		window_desc : Window_desc = {
			width = 600,
			height = 600,
			title = "my main window",
			resize_behavior = .allow_resize,
			antialiasing = .msaa8,
		}
		
		window := init(shader_defs, required_gl_verion = .opengl_4_5, window_desc = window_desc, pref_warn = true);
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

main_something :: proc () {
	
	context.logger = utils.create_console_logger(.Info);
	
	utils.init_tracking_allocators();
	{
		//Just for memory stuff
		context.allocator = utils.make_tracking_allocator();

		//Begin of code
		using render;
		
		start_time := time.now();
		
		window_desc : Window_desc = {
			width = 800,
			height = 800,
			title = "my main window",
			resize_behavior = .allow_resize,
			antialiasing = .msaa8,
		}
		
		//this window is optional and will be destroyed by render.destroy(). It must live for the entirety of the program.
		window_nan := init(shader_defs, required_gl_verion = .opengl_4_5, window_desc = nil, pref_warn = false);
		defer destroy();
		
		//window := make_window_desc(window_desc);
		//defer destroy_window(window);
		window := window_make(800, 800, "my_window_2", .allow_resize, .msaa8);
		defer window_destroy(window);
		
		gui_state := gui.init();
		defer gui.destroy(&gui_state);
		
		my_frame_buffer := render.frame_buffer_make_textures(1, 800, 800, .RGBA8, .depth_component32, false, .nearest);
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
		defer texture2D_destroy(tex);

		tex2 := texture2D_load_from_file("examples/res/textures/test.png", {.repeat, .nearest, true, .RGBA8});
		defer texture2D_destroy(tex2);

		tex3 := my_frame_buffer.color_attachments[0].(render.Texture2D);
		
		tex_up := texture2D_load_from_file("examples/res/textures/up.png", {.repeat, .nearest, true, .RGBA8});
		defer texture2D_destroy(tex_up);
		
		tex_eye := texture2D_load_from_file("examples/res/textures/eye.png", {.repeat, .nearest, true, .RGBA8});
		defer texture2D_destroy(tex_eye);
		
		cam_rot : [2]f32;
		speed : f32 = 10;
		last_frame := time.now();
		vsync : bool = true;
		fullscreen : render.Fullscreen_mode = .windowed;
		window_set_vsync(vsync);
		
		///// GUI stuff /////

		my_button := gui.make_button(&gui_state, gui.Destination{.bottom_right, .bottom_right, {0, 0, 0.3, 0.1}}, "My button", nil);
		
		////////////////////
		
		for !window_should_close(window) {
			
			if fullscreen != window.current_fullscreen {
				window_set_fullscreen(state.window_in_focus, fullscreen);
				fmt.printf("setting screen mode : %v\n", fullscreen);
			}
			
			begin_frame();
			gui.begin(&gui_state, window);
			
			if gui.button_is_pressed(my_button) {
				fmt.printf("Pressed my button");
			}
			
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

			gui.end(&gui_state);
			end_frame();
			mem.free_all(context.temp_allocator);
		}
	}
	
	utils.print_tracking_memory_results();
	utils.destroy_tracking_allocators();
	
	fmt.printf("Successfully closed\n");
}

main_atlas_test :: proc () {
	
	context.logger = utils.create_console_logger(.Info);
	
	utils.init_tracking_allocators();
	{
		//Just for memory stuff
		context.allocator = utils.make_tracking_allocator();
		
		//Begin of code
		using render;
		
		start_time := time.now();
		
		window_desc : Window_desc = {
			width = 800,
			height = 800,
			title = "my main window",
			resize_behavior = .allow_resize,
			antialiasing = .msaa8,
		}
		
		window := init(shader_defs, required_gl_verion = .opengl_4_5, window_desc = window_desc, pref_warn = false);
		defer destroy();
		
		//A pipeline is a collection of OpenGL states, a render target and a shader.
		//The target can be a window to draw to the screen or an FBO for drawing to a texture.
		my_pipeline := pipeline_make(get_default_shader(), culling = .back_cull);
		
		atlas := texture2D_atlas_make(.RGBA8, {.clamp_to_edge, .nearest, false, .RGBA8}, 1, 128);
		defer texture2D_atlas_destroy(atlas);
		
		////////////////////
		
		handles := make([dynamic]Atlas_handle);
		defer delete(handles);

		////////////////////

		for !window_should_close(window) {
			
			begin_frame();
				
				cnt := 10;
				
				if is_key_pressed(.up) {
					
					el_time : f64 = 0;

					for i in 0..<cnt {
						pixel_size := [2]i32{cast(i32)rand.float32_range(1, 32), cast(i32)rand.float32_range(1, 32)};
						
						pixels := make([][4]u8, pixel_size.x * pixel_size.y);
						defer delete(pixels);

						r,g,b := cast(u8)rand.uint32(), cast(u8)rand.uint32(), cast(u8)rand.uint32();
						for &p in pixels {
							p = [4]u8{r,g,b, 255};
						}

						sw : time.Stopwatch;
						time.stopwatch_start(&sw);
						
						handle, ok := texture2D_atlas_upload(&atlas, pixel_size, slice.reinterpret([]u8, pixels));
						if ok {
							append(&handles, handle);
						}
						
						time.stopwatch_stop(&sw);
						dur := time.stopwatch_duration(sw);
						el_time += time.duration_milliseconds(dur);
					}
					
					fmt.printf("Added %v new sprite(s) to the atlas, time taken %v\n", cnt, el_time);	
				}
				if is_key_pressed(.down) {
					for i in 0..<cnt {
						if len(handles) != 0 {
							i := cast(int)(rand.uint64() %% cast(u64)len(handles));
							handle := handles[i];
							unordered_remove(&handles, i);
							texture2D_atlas_remove(&atlas, handle);
						}
					}
				}
				if is_key_pressed(.left) {
					texture2D_atlas_shirnk(&atlas);
				}
				if is_key_pressed(.right) {
					texture2D_atlas_grow(&atlas);
				}

				target_begin(window, [4]f32{0.2, 0.2, 0.2, 1});
					pipeline_begin(my_pipeline, camera_get_pixel_space(window));
						set_texture(.texture_diffuse, atlas.backing);
						draw_quad_rect({100,100,600,600});
					pipeline_end();
					
					text_draw("Press up to add to the atlas", {10,50}, 30, false, false, {1,1,1,1});
					text_draw("Press down to remove", {10,10}, 30, false, false, {1,1,1,1});

					text_draw("Press left to shrink", {350,50}, 30, false, false, {1,1,1,1});
					text_draw("Press right to grow", {350,10}, 30, false, false, {1,1,1,1});

				target_end();

			end_frame();

			mem.free_all(context.temp_allocator);
		}
	}
	
	utils.print_tracking_memory_results();
	utils.destroy_tracking_allocators();

	fmt.printf("Successfully closed\n");
}


main_text_test :: proc () {
	
	context.logger = utils.create_console_logger(.Error);
	
	utils.init_tracking_allocators();
	{
		//Just for memory stuff
		context.allocator = utils.make_tracking_allocator();
		
		//Begin of code
		using render;
		
		start_time := time.now();
		
		window_desc : Window_desc = {
			width = 1600,
			height = 800,
			title = "my main window",
			resize_behavior = .allow_resize,
			antialiasing = .msaa8,
		}
		
		window := init(shader_defs, required_gl_verion = .opengl_3_3, window_desc = window_desc, pref_warn = false);
		defer destroy();
		
		//A pipeline is a collection of OpenGL states, a render target and a shader.
		//The target can be a window to draw to the screen or an FBO for drawing to a texture.
		my_pipeline := pipeline_make(get_default_shader(), culling = .back_cull);
		
		text_pipeline := pipeline_make(get_default_text_shader(), .blend, false, false, .fill, culling = .back_cull);
		defer pipeline_destroy(text_pipeline);
		
		font_ctx := fs.font_init(10000);
		defer fs.font_destroy(&font_ctx);
		
		my_font := fs.add_font_path_single(&font_ctx, "examples/res/fonts/FreeSans.ttf");
		
		texture : Texture2D = texture2D_make(false, .repeat, .nearest, .R8, 512, 512, .no_upload, nil, clear_color = [4]f32{0.5, 0, 0, 0});
		defer texture2D_destroy(texture);
		
		fs.push_font(&font_ctx, my_font);
		defer fs.pop_font(&font_ctx);		
		
		instance_desc : Instance_data_desc = {
			data_type 	= Default_instance_data,
			data_points = 1,
			usage 		= .dynamic_upload, //TODO maybe dynamic upload is better here?
		};
		
		verts, indices := generate_quad({1,1,1}, {0,0,0}, true);
		defer delete(verts);
		defer indices_delete(indices);
		char_mesh : Mesh_single = mesh_make_single(verts, indices, .static_use, .triangles, instance_desc);
		defer mesh_destroy(&char_mesh);
		
		////////////////////
		
		handles := make([dynamic]fs.Atlas_handle);
		defer delete(handles);
		
		////////////////////
		
		the_string := fmt.aprint("Text : ");
		defer delete(the_string);
		//the_string := "A 橝 橝橝";

		for !window_should_close(window) {
			
			begin_frame();
				
				target_begin(window, [4]f32{0.2, 0.2, 0.2, 1});
					
					for key in recive_next_input() {
						s := fmt.aprintf("%v",key);
						defer delete(s);
						new_string := strings.concatenate({the_string, s});
						delete(the_string);
						the_string = new_string;
					}
					
					if is_key_pressed(.left) {
						fs.client_atlas_shirnk(&font_ctx.atlas);
						fmt.printf("shrink\n");
					}
					if is_key_pressed(.right) {
						fs.client_atlas_grow(&font_ctx.atlas);
						fmt.printf("grow\n");
					}
									
					//For drawing the rect
					pipeline_begin(my_pipeline, camera_get_pixel_space(window));
						set_texture(.texture_diffuse, texture);
						draw_quad_rect({150,150,600,600});
						
						ymin := fs.get_lowest_point(&font_ctx);
						
						set_texture(.texture_diffuse, texture2D_get_white());
						/*
						draw_quad_rect({50, 40,3000,1}, 0, [4]f32{1,0,0,0.5});
						draw_quad_rect({50, 40, 5, fs.get_ascent(&font_ctx)}, 0, [4]f32{0,1,0,0.5});
						draw_quad_rect({50, 40 + fs.get_descent(&font_ctx), 5,-fs.get_descent(&font_ctx)}, 0, [4]f32{0,0,1,0.5});
						draw_quad_rect({900, 40, 100, 100}, 0, [4]f32{0,0,0,1});
						draw_quad_rect({1000, 40 + fs.get_descent(&font_ctx), 100, 100}, 0, [4]f32{1,0,0,0.5});
						draw_quad_rect({1100, 40 + ymin, 20, -ymin}, 0, [4]f32{0,0,1,0.5});
						draw_quad_rect({1120, 40, 5, fs.get_highest_point(&font_ctx)}, 0, [4]f32{0,1,0,0.5});				
						draw_quad_rect({1130, 40 + fs.get_lowest_point(&font_ctx), 5, fs.get_max_height(&font_ctx)}, 0, [4]f32{1,0,0,0.5});
						*/
						draw_quad_rect(fs.get_visible_text_bounds(&font_ctx, the_string) + {50,40,0,0}, 0, [4]f32{1,1,1,0.3});
						draw_quad_rect(fs.get_text_bounds(&font_ctx, the_string) + {50,40,0,0}, 0, [4]f32{0.3,0,0.5,0.3});
					pipeline_end();
					
					//For drawing the text
					pipeline_begin(text_pipeline, camera_get_pixel_space(window));
						
						//fs.set_em_size(&font_ctx, 100);
						fs.set_max_height_size(&font_ctx, 30);
						iter := fs.make_font_iter(&font_ctx, the_string);
						//iter := fs.make_font_iter(&font_ctx, "ffffFFf");
						defer fs.destroy_font_iter(iter);
						
						if new_size, ok := fs.requires_reupload(&font_ctx); ok {
							fmt.printf("reuploading font texture : %v\n", new_size);
							texture2D_destroy(texture);
							texture = texture2D_make(false, .repeat, .nearest, .R8, new_size.x, new_size.y, .R8, fs.get_bitmap(&font_ctx));
						}
						
						rect, done := fs.get_next_quad_upload(&font_ctx);
						for !done {
							//Here the atlas data is extracted from the atlas, alternatively the entire atlas can be uploaded.
							extracted_data := make([]u8, rect.z * rect.w);
							defer delete(extracted_data);
							
							dims := fs.get_bitmap_dimension(&font_ctx);
							fs.copy_pixels(1, dims.x, dims.y, rect.x, rect.y, fs.get_bitmap(&font_ctx), rect.z, rect.w, 0, 0, extracted_data, rect.z, rect.w);
							texture2D_upload_data(&texture, .R8, {rect.x, rect.y}, rect.zw, extracted_data);
							
							rect, done = fs.get_next_quad_upload(&font_ctx);
						}
						
						instance_data := make([dynamic]Default_instance_data);
						defer delete(instance_data);
						
						for q, coords in fs.font_iter_next(&font_ctx, &iter) {
							append(&instance_data, Default_instance_data {
								instance_position 	= {q.x + 50, q.y + 40, 0},
								instance_scale 		= {q.z, q.w, 1},
								instance_rotation 	= {0, 0, 0}, //Euler rotation
								instance_tex_pos_scale 	= coords,
							});
						}
						
						if i_data, ok := char_mesh.instance_data.?; ok {
							if i_data.data_points < len(instance_data) {
								mesh_resize_instance_single(&char_mesh, len(instance_data));
								log.infof("Resized text instance data. New length : %v", len(instance_data));
							}
						}
						else {
							panic("!?!?!");
						}
						
						upload_instance_data_single(&char_mesh, 0, instance_data[:]);
						
						set_uniform(get_default_text_shader(), .color_diffuse, [4]f32{1,1,1,1});
						set_texture(.texture_diffuse, texture);
						mesh_draw_instanced(&char_mesh, len(instance_data));
						
					pipeline_end();

				target_end();

			end_frame();

			mem.free_all(context.temp_allocator);
		}
	}
	
	utils.print_tracking_memory_results();
	utils.destroy_tracking_allocators();

	fmt.printf("Successfully closed\n");
}
*/