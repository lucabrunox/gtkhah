GtkHah gtk_hah = null;

public void gtk_module_init (ref unowned string[] args) {
	gtk_hah = new GtkHah ();
}

class Trie {
	char c;
	HashTable<char, Trie> children = new HashTable<char, Trie> (direct_hash, direct_equal);
}

delegate bool WidgetFunc (Gtk.Widget w);
delegate bool WindowFunc (Gtk.Window w);

class GtkHah {
	bool hinting = false;
	string chars = null;
	int nchars = 0;
	Trie hint_tree = null;
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
	
	bool recurse (Gtk.Widget w, owned WidgetFunc func) {
		if (!func (w)) {
			return false;
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
		var text = key_to_string (key);

		var fc = Pango.FontDescription.from_string ("Sans 8");
		var l = Pango.cairo_create_layout (cr);
        l.set_font_description (fc);
        l.set_width (w.get_allocated_width () * Pango.SCALE);
		l.set_height (w.get_allocated_height () * Pango.SCALE);
        l.set_text (text, -1);

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
		var action = get_atk_action (w);
		if (action != null) {
			int key = w.get_data ("gtkhah_key");
			if (key == 0) {
				w.draw.connect_after (on_draw);
			}
			num_widgets++;
			w.set_data ("gtkhah_key", num_widgets);
		}
		return true;
	}

	void handle_hint () {
		each_window ((win) => {
				return recurse (win, (w) => {
						int key = w.get_data ("gtkhah_key");
						if (key > 0 && key_to_string (key) == user_hits) {
							var action = get_atk_action (w);
							if (action != null) {
								action.do_action (0);
							}
							user_hits = "";
							return false;
						}
						return true;
				});
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
