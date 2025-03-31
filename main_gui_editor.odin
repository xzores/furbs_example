package main;

import "core:time"
import "core:math"
import "core:mem"
import "core:fmt"
import "core:slice"
import "core:math/linalg"
import "core:math/rand"

import "base:runtime"
import "core:strings"

import render "furbs/render"
import gui "furbs/regui"
import plot "furbs/plot"
import fs "furbs/fontstash"
import "furbs/utils"

entry :: proc () {
	
	gui.set_debug_draw(true);
	
	{
		//Begin of code
		using render;
		
		window_desc : Window_desc = {
			width = 1000,
			height = 1000,
			title = "my main window",
			resize_behavior = .allow_resize,
			antialiasing = .msaa4,
		}
		
		window := init(shader_defs, required_gl_verion = .opengl_4_5, window_desc = window_desc, pref_warn = true);
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
		text_field2 := gui.make_text_field(	panel, 	gui.Destination{.bottom_left, .bottom_left, {0.01, 0.36, 0.1, 0.05}}, "", "something", 1000, nil, appearance = field_apperance);
		text_field3 := gui.make_text_field(	panel, 	gui.Destination{.bottom_left, .bottom_left, {0.15, 0.36, 0.15, 0.1}}, "", "", 1000, nil, appearance = field_apperance);
		
		//text_field3 := gui.make_text_field(	panel, 	gui.Destination{.bottom_left, .bottom_left, {0.15, 0.36, 0.15, 0.1}}, "", "", 1000, nil, appearance = field_apperance);		
		
		sin_norm :: proc (t : f64) -> f64 {
			return math.sin(t * 2 * math.PI);
		}
		
		r : plot.Signal;
		defer plot.destroy_signal(r);
		plot.fill_signal(&r, plot.Span(f64){0.001, 10, 0.1}, sin_norm, 1);
		
		my_xy_plot := plot.make_xy_plot({r}, "My x label", "My y Label", x_log = .no_log); // 
		my_sin_plot := plot.make_regui_plot(panel, gui.Destination{.top_left, .top_left, {0.01, -0.01, 0.60, 0.30}}, my_xy_plot, appearance = field_apperance);
		
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
					
					draw_fps_overlay();
				target_end();
				
			end_frame();
			mem.free_all(context.temp_allocator);
		}
	}
	
	fmt.printf("Successfully closed\n");
}