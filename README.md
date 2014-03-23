Gtk+ 3.0 Hit-a-Hint
======

Mouseless keyboard navigation.

```
# apt-get install gcc make valac libgtk-3-dev libatk1.0-dev libatspi2.0-dev
$ git clone https://github.com/lethalman/gtkhah.git
$ cd gtkhah
$ make
$ GTK_MODULES=$(pwd)/gtkhah.so gedit
```

Now press `Ctrl+Alt+E` to start hinting. Press `ESC` to stop hinting.
