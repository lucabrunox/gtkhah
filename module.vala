public void gtk_module_init (ref unowned string[] args) {
	new GtkHah ();
}

class Trie {
	char c;
	HashTable<char, Trie> children = new HashTable<char, Trie> (direct_hash, direct_equal);
}

delegate void WidgetFunc (Gtk.Widget w);

class GtkHah {
	bool hinting = false;
	string chars = "ASDFQWE";
	Trie hint_tree = null;
	
	public GtkHah () {
		Atk.Util.add_key_event_listener (on_key);
	}

	void show_hints () {
		hint_tree = new Trie ();
		var wins = Gtk.Window.list_toplevels ();
		foreach (var win in wins) {
			recurse (win, connect_draw);
		}
	}

	void recurse (Gtk.Widget w, owned WidgetFunc func) {
		func (w);
		if (w is Gtk.Container) {
			var children = ((Gtk.Container) w).get_children ();
			foreach (var c in children) {
				recurse (c, func);
			}
		}
	}
	
	bool on_draw (Gtk.Widget w, Cairo.Context cr) {
		unowned string key = w.get_data ("gtkhah_key");
		if (key == null) {
			return false;
		}

		var fc = Pango.FontDescription.from_string ("Sans 8");
		var l = Pango.cairo_create_layout (cr);
        l.set_font_description (fc);
        l.set_width (w.get_allocated_width () * Pango.SCALE);
		l.set_height (w.get_allocated_height () * Pango.SCALE);
        l.set_text (key, -1);

		Pango.Rectangle r;
		l.get_extents (null, out r);
		// center vertically
		cr.move_to (0, (r.y / Pango.SCALE) + w.get_allocated_height()/2 - (r.height / Pango.SCALE)/2);
		Pango.cairo_show_layout (cr, l);
		
		return false;
	}

	void on_dispose (Object obj) {
		string* key = obj.get_data ("gtkhah_key");
		if (key != null) {
			delete key;
		}
		obj.set_data ("gtkhah_key", null);
	}
	
	void connect_draw (Gtk.Widget w) {
		if (w is Gtk.Activatable) {
			unowned string key = w.get_data ("gtkhah_key");
			if (key == null) {
				w.draw.connect_after (on_draw);
			}
			w.set_data ("gtkhah_key", "key".dup());
			w.queue_draw ();
		}
	}
	
	int on_key (Atk.KeyEventStruct e) {
		uint mod = e.state & (Gdk.ModifierType.MOD1_MASK | Gdk.ModifierType.CONTROL_MASK);
		if (mod != 0 && e.keyval == Gdk.Key.e) {
			show_hints ();
		}
		return 0;
	}
}
