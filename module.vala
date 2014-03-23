GtkHah gtk_hah = null;

public void gtk_module_init (ref unowned string[] args) {
	gtk_hah = new GtkHah ();
}

delegate bool WidgetFunc (Gtk.Widget w);
delegate bool WindowFunc (Gtk.Window w);

class GtkHah {
	bool hinting = false;
	string chars = null;
	int nchars = 0;
	int num_widgets = 0;
	string user_hits = "";
	
	public GtkHah () {
		Atk.Util.add_key_event_listener (on_key);
		chars = "ASDFQWEJKL";
		nchars = chars.length;
	}

	bool each_window (owned WindowFunc func) {
		var wins = Gtk.Window.list_toplevels ();
		foreach (var win in wins) {
			if (!func (win)) {
				return false;
			}
		}
		return true;
	}
	
	void start_hinting () {
		hinting = true;
		user_hits = "";
		num_widgets = 0;
		
		each_window ((win) => {
				bool ret = recurse (win, connect_draw);
				win.queue_draw ();
				return ret;
		});
	}

	void stop_hinting () {
		hinting = false;
		each_window ((win) => { win.queue_draw (); return true; });
	}
	
	bool recurse (Gtk.Widget w, WidgetFunc func) {
		var action = get_atk_action (w);
		if (action != null) {
			if (!func (w)) {
				return false;
			}
		}

		var notebook = w as Gtk.Notebook;
		if (notebook != null) {
			for (var i=0; i < notebook.get_n_pages (); i++) {
				if (!func (notebook.get_tab_label (notebook.get_nth_page (i)))) {
					return false;
				}
			}
		}
		
		if (w is Gtk.Container) {
			var children = ((Gtk.Container) w).get_children ();
			foreach (var c in children) {
				if (!recurse (c, func)) {
					return false;
				}
			}
		}
		return true;
	}

	string key_to_string (int key) {
		key--;
		var res = "";
		var letters = Math.log (num_widgets) / Math.log (nchars);
		for (int i=0; i < letters; i++) {
			res += chars[key%nchars].to_string ();
			key /= nchars;
		}
		return res;
	}
	
	bool on_draw (Gtk.Widget w, Cairo.Context cr) {
		if (!hinting) {
			return false;
		}
		
		int key = w.get_data ("gtkhah_key");
		if (key == 0) {
			return false;
		}
		var keystr = key_to_string (key);
		var keystr_length = keystr.length;
		var user_hits_length = user_hits.length;
		var text = "<span bgcolor='#fce94f'>";
		var i=0;
		if (keystr.has_prefix (user_hits)) {
			text += "<span bgcolor='#729fcf'>";
			for (; i < keystr_length; i++) {
				if (i >= user_hits_length || keystr[i] != user_hits[i]) {
					break;
				}
				text += keystr[i].to_string ();
			}
			text += "</span>";
		}
		
		for (; i < keystr_length; i++) {
			text += keystr[i].to_string ();
		}
		text += "</span>";

		var fc = Pango.FontDescription.from_string ("Sans 8");
		var l = Pango.cairo_create_layout (cr);
        l.set_font_description (fc);
        l.set_width (w.get_allocated_width () * Pango.SCALE);
		l.set_height (w.get_allocated_height () * Pango.SCALE);
        l.set_markup (text, -1);

		Pango.Rectangle r;
		l.get_extents (null, out r);
		// center vertically
		cr.move_to (0, (r.y / Pango.SCALE) + w.get_allocated_height()/2 - (r.height / Pango.SCALE)/2);
		Pango.cairo_show_layout (cr, l);
		
		return false;
	}

	[CCode (cname = "atk_implementor_ref_accessible")]
	public extern static Atk.Object ref_accessible (Atk.Implementor impl);
	
	static Atk.Action get_atk_action (Gtk.Widget w) {
		var obj = ref_accessible (w);
		return obj as Atk.Action;
	}

	bool connect_draw (Gtk.Widget w) {
		int key = w.get_data ("gtkhah_key");
		if (key == 0) {
			w.draw.connect_after (on_draw);
		}
		num_widgets++;
		w.set_data ("gtkhah_key", num_widgets);
		return true;
	}		

	[CCode (cname = "atspi_generate_mouse_event")]
	public extern static bool generate_mouse_event (long x, long y, string name) throws Error;
	
	void handle_hint () {
		each_window ((win) => {
				recurse (win, (w) => {
						int key = w.get_data ("gtkhah_key");
						if (key > 0 && key_to_string (key) == user_hits) {
							int root_x, root_y;
							int x, y;
							int mx, my;
							w.get_window().get_display().get_device_manager().get_client_pointer().get_position (null, out mx, out my);
							var toplevel = (Gtk.Window) w.get_toplevel ();
							toplevel.get_window().get_origin (out root_x, out root_y);
							if (w.translate_coordinates (toplevel, 0, 0, out x, out y)) {
								try {
									generate_mouse_event (root_x + x, root_y + y, "b1c");
									// move mouse back
									generate_mouse_event (mx, my, "abs");
								} catch (Error e) {
									warning (e.message);
								}
							} else {
								if (!w.activate ()) {
									w.grab_focus ();
									var action = get_atk_action (w);
									if (action != null) {
										action.do_action (0);
									}
								}
							}
							user_hits = "";
							return false;
						}
						return true;
				});
				win.queue_draw ();
				return true;
		});
	}
	
	int on_key (Atk.KeyEventStruct e) {
		var modmask = Gdk.ModifierType.MOD1_MASK | Gdk.ModifierType.CONTROL_MASK;
		var mod = e.state & modmask;
		if (mod == modmask && e.keyval == Gdk.Key.e) {
			start_hinting ();
			return 1;
		}

		if (mod != 0) {
			return 0;
		}
		
		if (hinting) {
			if (e.keyval < 255 && ((char) e.keyval).isalnum() && chars.index_of_char (((char) e.keyval).toupper()) >= 0) {
				if (e.type == Atk.KeyEventType.RELEASE) {
					user_hits += ((char) e.keyval).toupper().to_string();
					handle_hint ();
				}
				return 1;
			} else if (e.keyval == Gdk.Key.Escape) {
				stop_hinting ();
				return 1;
			}
		}
		
		return 0;
	}
}
