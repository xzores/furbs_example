package main;

import "core:time"
import "core:math"
import "core:mem"
import "core:fmt"
import "core:slice"
import "core:math/linalg"
import "core:math/rand"

import "base:runtime"

import render "furbs/render"
import gui "furbs/regui"
import fs "furbs/fontstash"
import "furbs/utils"


main :: proc () {
	
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
			width = 1000,
			height = 1000,
			title = "my main window",
			resize_behavior = .allow_resize,
			antialiasing = .msaa4,
		}
		
		window := init(uniform_spec, attribute_spec, shader_defs, required_gl_verion = .opengl_4_5, window_desc = window_desc, pref_warn = false);
		defer destroy();
		
		gui_state := gui.init();
		defer gui.destroy(&gui_state);
		
		////////////////////
		
		vsync : bool = true;
		fullscreen : render.Fullscreen_mode = .windowed;
		window_set_vsync(vsync);
		
		field_apperance : gui.Colored_appearance = gui.default_appearance;
		
		field_apperance.text_anchor = .center_left;
		
		////////////////////
		
		panel := gui.make_panel(&gui_state, gui.Destination{.bottom_left, .bottom_left, {0.01, 0.01, 0.68, 0.98}});
		
		button := gui.make_button(			panel, 	gui.Destination{.bottom_left, .bottom_left, {0.01, 0.01, 0.3, 0.1}}, "My button", nil);
		small_button := gui.make_button(	panel, 	gui.Destination{.bottom_left, .bottom_left, {0.32, 0.01, 0.1, 0.1}}, "My button", nil);
		rect := gui.make_rect(				panel, 	gui.Destination{.bottom_left, .bottom_left, {0.43, 0.01, 0.1, 0.1}});
		checkbox := gui.make_checkbox(		panel, 	gui.Destination{.bottom_left, .bottom_left, {0.54, 0.01, 0.1, 0.1}}, true, nil);
		
		label := gui.make_label(			panel, 	gui.Destination{.bottom_left, .bottom_left, {0.01, 0.2, 0.2, 0.05}}, "This is a label");
		slider := gui.make_slider(			panel, 	gui.Destination{.bottom_left, .bottom_left, {0.22, 0.2, 0.2, 0.05}}, 15, 15, 30, nil);
		int_slider := gui.make_int_slider(	panel, 	gui.Destination{.bottom_left, .bottom_left, {0.43, 0.2, 0.2, 0.05}}, 5, 5, 10, nil);
		
		text_field := gui.make_text_field(	panel, 	gui.Destination{.bottom_left, .bottom_left, {0.01, 0.3, 0.3, 0.05}}, "", "username", 1000, nil, appearance = field_apperance);
		
		////////////////////
		
		for !window_should_close(window) {

			if fullscreen != window.current_fullscreen {
				window_set_fullscreen(state.window_in_focus, fullscreen);
			}
			
			begin_frame();
				
				target_begin(window, [4]f32{0.6, 0.6, 0.6, 1});
					gui.begin(&gui_state, window); //TODO: The window is simply passed to get the mouse position, this will likely change.
						//Get the gui state of elements, like is button down and stuff.
					gui.end(&gui_state);
				target_end();
				
				draw_fps_overlay(window);
			end_frame();
			mem.free_all(context.temp_allocator);
		}
	}
	
	utils.print_tracking_memory_results();
	utils.destroy_tracking_allocators();
	
	fmt.printf("Successfully closed\n");

}