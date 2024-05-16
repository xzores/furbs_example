package main;

import "core:time"
import "core:math"
import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import "core:log"
import "core:mem"
import "core:runtime"
import "core:slice"

import "core:image/png"

import fs "vendor:fontstash"

import render "furbs/render"
import "furbs/utils"

import gl "furbs/render/gl"

/*
Value :: f32;

factor : Value = 1;

F_point :: struct {
	value : Value,
	deriv : Value,
	vel : [2]Value,
}

Buffer_source :: enum {
	buffer1,
	buffer2,
}

F_field_2D :: struct {
	x_size : i64,
	y_size : i64,
	buffer1 : [][]F_point,
	buffer2 : [][]F_point,
	buffer_source : Buffer_source,
}

f_field_2D_make :: proc(x, y : i64) -> F_field_2D {

	buffer1, _ := utils.make_2d_slice(x, y, F_point);
	buffer2, _ := utils.make_2d_slice(x, y, F_point);

	f : F_field_2D = {
		x_size = x,
		y_size = y,
		buffer1 = buffer1,
		buffer2 = buffer2,
		buffer_source = .buffer1, 
	}

	return f;
}

f_field_2D_destroy :: proc(f : F_field_2D) {
	utils.delete_2d_slice(f.buffer1);
	utils.delete_2d_slice(f.buffer2);
}

f_field_2D_step :: proc (f : ^F_field_2D) {

	buffer_read 	: [][]F_point;
	buffer_write 	: [][]F_point;

	if f.buffer_source == .buffer1 {
		buffer_read = f.buffer1;
		buffer_write = f.buffer2;
	}
	else {
		buffer_read = f.buffer2;
		buffer_write = f.buffer1;
	}
	
	d_d := math.sqrt(cast(Value)2);
	t_dist : Value = 4 + 4 * d_d;
	
	//dist_table : [3][3]Value = {d_d, 1, 0, 1, d_d};

	for y in 1..<f.y_size-1 {
		for x in 1..<f.x_size-1 {

			value : Value = 0;
			deriv : Value = 0;
			for yy in y-1..=y+1 {
				for xx in x-1..=x+1 {
					dist : Value = 1;
					vel.x = vel.x;
					value += (buffer_read[xx][yy].value) / t_dist * dist;
					deriv = value - buffer_read[x][y].value;
					value -= deriv / t_dist * dist;
				}
			}
			
			buffer_write[x][y].value = value;
			buffer_write[x][y].deriv = deriv;
		}
	}

	if f.buffer_source == .buffer1 {
		f.buffer_source = .buffer2;
	}
	else {
		f.buffer_source = .buffer1;
	}

}

f_field_get_draw_source_2D :: proc (f : F_field_2D) -> [][]F_point {
	if f.buffer_source == .buffer1 {
		return f.buffer1;
	}
	else {
		return f.buffer2;
	}
}

f_field_make 			:: f_field_2D_make;
f_field_destroy 		:: f_field_2D_destroy;
f_field_step 			:: f_field_2D_step;
f_field_get_draw_source :: f_field_get_draw_source_2D;
*/

main :: proc () {

	tex_size : i32 = 500;

	context.logger = utils.create_console_logger(.Info);
	utils.init_tracking_allocators();

	{
		//Just for memory stuff
		context.allocator = utils.make_tracking_allocator();
		//Begin of code
		using render;

		uniform_spec 	: [Uniform_location]Uniform_info = {};		//TODO make these required	
		attribute_spec 	: [Attribute_location]Attribute_info = {}; 	//TODO make these required

		window_desc : Window_desc = {
			width = 600,
			height = 600,
			title = "Furbian simulator",
			resize_behavior = .resize_backbuffer,
			antialiasing = .msaa2,
		}

		shader_defs : map[string]string = {
			//"err_factor" = "8",
			//"sigma" = "1",
		}

		window := init(uniform_spec, attribute_spec, shader_defs, required_gl_verion = .opengl_4_5, window_desc = window_desc, pref_warn = true);
		defer destroy();
		
		window_set_vsync(false);

		my_pipeline := make_pipeline(get_default_shader(), .no_blend);
		defer destroy_pipeline(my_pipeline);

		compute_shader, err := load_shader_from_path("q_compute.glsl");
		assert(err == nil);
		defer destroy_shader(compute_shader);
		compute_pipeline := make_pipeline(compute_shader, .no_blend);
		defer destroy_pipeline(compute_pipeline);

		cam : Camera2D = {
			position		= {0,0},            	// Camera position
			target_relative	= {0,0},				// 
			rotation		= 0,				// in degrees
			zoom 			= 2,            	//
			
			near 			= -1,
			far 			= 1,
		}
		
		data_type : Color_format = .RGBA16_float;

		//TODO, maybe not repeat.
		buffer1 := frame_buffer_make_textures(1, tex_size, tex_size, data_type, .depth_component32, false, .nearest, true, .repeat);
		buffer2 := frame_buffer_make_textures(1, tex_size, tex_size, data_type, .depth_component32, false, .nearest, true, .repeat);
		defer frame_buffer_destroy(buffer1);
		defer frame_buffer_destroy(buffer2);

		buffer_use : bool = false;

		read_buffer := &buffer1;
		write_buffer := &buffer2;

		texture_kernel := load_texture_2D_from_file("kernel.png");
		
		brush_size : i32 = 10;
		color := [4]u8{255,0,0,0};
		image_data := make([][4]u8, brush_size * brush_size);
		for d in &image_data {
			d = color;
		}
		
		m : f32 = 1;

		for !window_should_close(window) {
			
			if buffer_use {
				read_buffer = &buffer1;
				write_buffer = &buffer2;
			}
			else {
				read_buffer = &buffer2;
				write_buffer = &buffer1;
			}
			buffer_use = !buffer_use;
			
			read_texture := read_buffer.color_attachments[0].(render.Texture2D); //just a reference
			write_texture := write_buffer.color_attachments[0].(render.Texture2D); //just a reference

			//drawing the frame
			begin_frame();

				if is_key_pressed(.kp_add) {
					m *= 2;
					fmt.printf("m is now %v\n", m);
				}
				if is_key_pressed(.kp_subtract) {
					m /= 2;
					fmt.printf("m is now %v\n", m);
				}

				if is_button_down(.mouse_button_1) {
					window_x_size, window_y_size := window_get_size(window);
					mp := mouse_pos();
					w_x, w_y :=  cast(f32)window_x_size,  cast(f32)window_y_size;
					pos := [2]f32{mp.x / w_x, (w_y - mp.y) / w_y}; // between 0 and 1
					
					//pos.x = pos.xw_x / w_y;

					t_pos : [2]i32 = {cast(i32)(pos.x * cast(f32)tex_size), cast(i32)(pos.y * cast(f32)tex_size)};
					t_pos.x = math.clamp(t_pos.x, 0, tex_size - brush_size);
					t_pos.y = math.clamp(t_pos.y, 0, tex_size - brush_size);

					upload_texture_2D_data(&read_texture, .RGBA8, t_pos, {brush_size,brush_size}, slice.reinterpret([]u8, image_data[:]));
				}

				//Compute time step
				begin_target(write_buffer, [4]f32{0,0,0,0});
					begin_pipeline(compute_pipeline, cam);

						set_uniform(compute_shader, .tex_size, cast(u32)tex_size);
						set_uniform(compute_shader, .sample_dist, cast(f32)0.2);
						set_uniform(compute_shader, .rate, cast(f32)1);

						//draw texture to quad
						set_texture(.texture_1, read_texture);
						draw_quad(1);
					end_pipeline();
				end_target();
		
				begin_target(window, [4]f32{0.1,0.1,0.1,1});
					begin_pipeline(my_pipeline, cam);
						//draw texture to quad
						set_texture(.texture_diffuse, write_texture);
						draw_quad(1, {m,m,m,m});
					end_pipeline();
				end_target();

				draw_fps_overlay(window);
			
			end_frame();
		}
		
	}

	utils.print_tracking_memory_results();
	utils.destroy_tracking_allocators();
	fmt.printf("Successfully closed\n");

}