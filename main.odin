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
	"red_amount" = "1.0",
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
Finish the opengl wrapper to use odin arrays and enums and bitsets.
when using double bufferingda uploading all data every frame, there should be a keep_consistent variable.
Draw FPS counter
Then when that is done fix some mesh generation functions.
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

main :: proc () {
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
		
		window := init(uniform_spec, attribute_spec, shader_defs, required_gl_verion = .opengl_3_3, window_desc = window_desc, pref_warn = false);
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

		for !should_close(window) {
			begin_frame();
				
				begin_target(&my_fbo, [4]f32{0,0,0,0});
					draw_text_simple("Hello World", {0,0}, 100, 0, {0,0,0,1});
				end_target();
				
				begin_target(window, [4]f32{0.3,0.3,0.3,0});
					
					begin_pipeline(pipeline, cam);
					set_texture(.texture_diffuse, tex_up);
					draw_quad(1);
					set_texture(.texture_diffuse, tex_color);
					draw_quad(1);
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

/*
main2 :: proc () {

	/*
		font_context_test : fs.FontContext;
		fs.Init(&font_context_test, 1, 1, .BOTTOMLEFT);
		fd := #load("furbs/render/font/LinLibertine_R.ttf", []u8);
		fs.AddFontMem(&font_context_test, "test", fd, false);
		fs.TextIterInit(&font_context_test, 0, 0, "Hello world");
		my_any : any = &font_context_test;
		fmt.printf("font_context_test : %v\n", my_any);
	*/

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
		window := init(uniform_spec, attribute_spec, shader_defs, required_gl_verion = .opengl_4_5, window_desc = window_desc, pref_warn = false);
		//init(uniform_spec, attribute_spec, shader_defs, required_gl_verion = .opengl_3_3);
		defer destroy();
		
		//window := make_window_desc(window_desc);
		//defer destroy_window(window);
		//window_2 := make_window(400, 400, "my_window_2", .resize_backbuffer, .none);
		//defer destroy_window(window_2);
		
		my_frame_buffer : Frame_buffer;
		init_frame_buffer_textures(&my_frame_buffer, 1, 400, 400, .RGBA8, .depth_component32, false, .nearest);
		defer destroy_frame_buffer(my_frame_buffer);
		
		mouse_mode(window, .locked);
		
		//Sets the cursor for the window
		img, err := png.load("examples/res/cursor/Cursor Default Friends.png", {.alpha_add_if_missing})
		defer png.destroy(img);
		set_cursor(window, img.width, img.height ,img.pixels.buf[:]);

		my_shader, e := load_shader_from_path("my_shader.glsl");
		assert(e == nil, "failed to load shader");
		defer unload_shader(my_shader);
		
		//A pipeline is a collection of OpenGL states, a render target and a shader.
		//The target can be a window to draw to the screen or an FBO for drawing to a texture.
		my_pipeline := make_pipeline(window, my_shader, culling = .back_cull);
		my_pipeline2 := make_pipeline(&my_frame_buffer, my_shader, culling = .back_cull);
		//my_pipeline3 := make_pipeline(window_2, my_shader, culling = .back_cull);
		
		//my_mesh := make_mesh(vertex_data, nil, .single, .dynamic_use);
		my_quad := make_mesh_quad({1,1,1}, {0,0,0}, false);
		my_cirle := make_mesh_circle(1, {0,0,0}, 20, true);
		my_cube := make_mesh_cube(1, {0,0,0}, true);
		my_cylinder := make_mesh_cylinder({0,0,0}, 1, 1, 20, 20, true);
		my_sphere := make_mesh_sphere({0,0,0}, 1, 20, 20, true);
		my_cone := make_mesh_cone({0,0,0}, 1, 1, 20, true);
		my_arrow := make_mesh_arrow({1,0,0}, 1, 0.6, 0.25, 0.7, 20, true);
		defer destroy_mesh(&my_quad);
		defer destroy_mesh(&my_cirle);
		defer destroy_mesh(&my_cube);
		defer destroy_mesh(&my_cylinder);
		defer destroy_mesh(&my_sphere);
		defer destroy_mesh(&my_cone);
		defer destroy_mesh(&my_arrow);
		
		my_balls : []Ball = make([]Ball, 10000);
		my_instance_data : []Default_instance_data = make([]Default_instance_data, len(my_balls));
		defer delete(my_balls);
		defer delete(my_instance_data);
		
		sd, si := generate_sphere(use_index_buffer = false);
		instance_desc := Instance_data_desc{data_type = Default_instance_data, data_points = len(my_balls), usage = .dynamic_upload};
		my_sphere_instanced := make_mesh_single(sd, nil, .static_use, .triangles, instance_desc);
		//my_sphere_instanced := make_mesh_buffered(4, len(sd), Default_vertex, len(si), .no_index_buffer, .dynamic_use, .triangles, instance_desc);
		//upload_vertex_data(&my_sphere_instanced, 0, sd);
		delete(sd);	delete_indices(si);
		defer destroy_mesh(&my_sphere_instanced);
		
		for &ball, i in my_balls {
			ball = Ball{position = [3]f32{-6, 0, 0}, velocity = [3]f32{2*rand.float32() - 1, 10 * rand.float32(),2*rand.float32() -1}};
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
			i_size = math.max(len_indices(qi), len_indices(ciri), len_indices(cubei), len_indices(cyi), len_indices(si), len_indices(coni));
		}

		my_super_mesh := make_mesh_buffered(1, v_size, render.Default_vertex, i_size, .unsigned_short, .dynamic_use);
		defer {
			for m in mesh_datas {
				delete(m.verts); delete_indices(m.indicies);
			}
			destroy_mesh(&my_super_mesh);
		}

		camera : Camera3D = {
			position 	= {0,0,-15},
			target 		= {0,0,0},
			up			= {0,1,0},
			fovy     	= 45,
			projection	= .perspective,
			near = 0.1,
			far = 1000,
		};
		
		//tex := make_texture_2D(512, 512, false, .repeat, .linear, .uncompressed_RGBA8, .no_upload, nil);
		tex := load_texture_2D_from_file("examples/res/textures/dirt.png", {.clamp_to_edge, .nearest, false, .uncompressed_RGBA8});
		defer destroy_texture_2D(&tex);

		tex2 := load_texture_2D_from_file("examples/res/textures/test.png", {.repeat, .nearest, true, .uncompressed_RGBA8});
		defer destroy_texture_2D(&tex2);

		tex3 := my_frame_buffer.color_attachments[0].(render.Texture2D);
		
		cam_rot : [2]f32;
		speed : f32 = 10;
		last_frame := time.now();
		vsync : bool = true;
		enable_vsync(vsync);

		for !should_close(window) {
			begin_frame();

			if is_key_pressed(.f5) {
				reload_shaders(); //return a list of the shaders failing to reload, and keep using the old ones...
			}
			if is_key_pressed(.f7) {
				vsync = !vsync;
				enable_vsync(vsync);
				fmt.printf("VSYNC : %v\n", vsync);
			}
			if is_key_pressed(.f11) {
				enable_fullscreen(state.window_in_focus, !state.window_in_focus.is_fullscreen);
			}
			
			now :=  time.now();
			t : f32 = cast(f32)time.duration_seconds(time.diff(start_time, now));
			dt : f32 = cast(f32)time.duration_seconds(time.diff(last_frame, now));
			last_frame = now;
			//fmt.printf("fps : %v\n", 1/dt);

			for &ball, i in my_balls {
				if linalg.length(ball.position) > 10 {
					ball = Ball{position = [3]f32{-6, 0, 0}, velocity = [3]f32{2*rand.float32() - 1, 10 * rand.float32(),2*rand.float32() -1}};
				}
				ball.position += ball.velocity * dt;
				ball.velocity += [3]f32{0,-7,0} * dt;
				
				my_instance_data[i].instance_position = ball.position;
			}
			
			upload_instance_data(&my_sphere_instanced, 0, my_instance_data);
			
			if is_key_down(Key_code.a) {
				camera_move(&camera, -speed * camera_right(camera) * dt);
			}
			if is_key_down(Key_code.d) {
				camera_move(&camera, speed * camera_right(camera) * dt);
			}
			if is_key_down(Key_code.w) {
				camera_move(&camera, speed * camera_forward(camera) * dt);
			}
			if is_key_down(Key_code.s) {
				camera_move(&camera, -speed * camera_forward(camera) * dt);
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
			
			cam_rot += 0.1 * {-state.mouse_delta.x, state.mouse_delta.y}; //mouse_delta.y
			cam_rot.y = math.clamp(cam_rot.y, -89, 89);
			camera_rotation(&camera, cam_rot.x, cam_rot.y);
			
			//upload a new mesh to the super mesh
			upload_vertex_data(&my_super_mesh, 0, mesh_datas[cur_mesh_datas].verts);
			upload_index_data(&my_super_mesh, 0, mesh_datas[cur_mesh_datas].indicies);
			cur_mesh_datas = (int(t*3)) %% len(mesh_datas);
						
			
			begin_pipeline(my_pipeline2, camera, [4]f32{1,0,0,0.5});
			set_texture(.texture_diffuse, tex2);
			draw_mesh(&my_arrow, linalg.matrix4_translate_f32({-3,0,0}));
			draw_mesh(&my_cube, 1);
			draw_mesh(&my_cirle, linalg.matrix4_translate_f32({1.5,0,0}));
			draw_mesh(&my_quad, linalg.matrix4_translate_f32({3,0,0}));
			draw_mesh(&my_cylinder, linalg.matrix4_translate_f32({4.5,0,0}));
			draw_mesh(&my_sphere, linalg.matrix4_translate_f32({6,0,0}));
			draw_mesh(&my_cone, linalg.matrix4_translate_f32({7.5,0,0}));
			draw_mesh(&my_super_mesh, linalg.matrix4_translate_f32({9,0,0}));
			end_pipeline(my_pipeline2);
			
			/*
			begin_pipeline(my_pipeline3, camera, [4]f32{0.3,0.2,0.1,1});
			set_texture(.texture_diffuse, tex2);
			draw_mesh(&my_arrow, linalg.matrix4_translate_f32({-3,0,0}));
			draw_mesh(&my_cube, 1);
			draw_mesh(&my_cirle, linalg.matrix4_translate_f32({1.5,0,0}));
			draw_mesh(&my_quad, linalg.matrix4_translate_f32({3,0,0}));
			draw_mesh(&my_cylinder, linalg.matrix4_translate_f32({4.5,0,0}));
			draw_mesh(&my_sphere, linalg.matrix4_translate_f32({6,0,0}));
			draw_mesh(&my_cone, linalg.matrix4_translate_f32({7.5,0,0}));
			draw_mesh(&my_super_mesh, linalg.matrix4_translate_f32({9,0,0}));
			end_pipeline(my_pipeline2);
			*/

			begin_pipeline(my_pipeline, camera, [4]f32{0.05,0.4,0.44,1});
			set_texture(.texture_diffuse, tex);
			draw_mesh(&my_arrow, linalg.matrix4_translate_f32({-3,0,0}));
			draw_mesh(&my_cube, 1);
			draw_mesh(&my_cirle, linalg.matrix4_translate_f32({1.5,0,0}));
			draw_mesh(&my_quad, linalg.matrix4_translate_f32({3,0,0}));
			draw_mesh(&my_cylinder, linalg.matrix4_translate_f32({4.5,0,0}));
			draw_mesh(&my_sphere, linalg.matrix4_translate_f32({6,0,0}));
			draw_mesh(&my_cone, linalg.matrix4_translate_f32({7.5,0,0}));
			draw_mesh(&my_super_mesh, linalg.matrix4_translate_f32({9,0,0}));
			//Dont draw with this draw_mesh(&my_sphere_instanced, 1);
			draw_mesh_instanced(&my_sphere_instanced, len(my_balls)); //Draw like this.
			set_texture(.texture_diffuse, tex2); //Draw below
			draw_cube(linalg.matrix4_translate_f32({0,-2,0}));
			draw_circle(linalg.matrix4_translate_f32({1.5,-2,0}));
			draw_quad(linalg.matrix4_translate_f32({3,-2,0}));
			draw_cylinder(linalg.matrix4_translate_f32({4.5,-2,0}));
			draw_sphere(linalg.matrix4_translate_f32({6,-2,0}));
			draw_cone(linalg.matrix4_translate_f32({7.5,-2,0}));
			draw_arrow(linalg.matrix4_translate_f32({9,-2,0}));
			set_texture(.texture_diffuse, tex3);
			draw_mesh(&my_quad, linalg.matrix4_translate_f32({0,2.1,0})); //place 1 is model_matrix for identity matrix
			end_pipeline(my_pipeline);

			draw_text_simple(window, "Hello World", {0,0}, 100);
			//draw_coordinate_overlay(window, camera);
			
			//fmt.printf("Cam : %v, %v\n", camera.position, camera_forward(camera));

			end_frame();
			mem.free_all(context.temp_allocator);
		}
	}
	
	utils.print_tracking_memory_results();
	utils.destroy_tracking_allocators();

	fmt.printf("Successfully closed\n");
}


/*
main :: proc () {
	using render;

	uniform_spec 	: [Uniform_location]Uniform_info = {};
	attribute_spec 	: [Attribute_location]Attribute_info = {};

	init(uniform_spec, attribute_spec, nil, "res/shaders");

	window := make_window(800, 800, "my_window", loc := #caller_location);
	
	my_pipeline := make_pipeline(window, get_default_shader());
	
	my_cube := gen_cube();
	upload_mesh_single(&my_cube);

	for !should_close(window) {
		begin_frame(window);

		begin_pipeline(my_pipeline, my_cam);

		draw_mesh(&my_cube);

		end_pipeline();

		end_frame();
	}

	delete_window(&window);

	destroy();
}	
*/
*/