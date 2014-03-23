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

Hitting keys may seem a little unresponsive due to listening to key release events rather than key press events.

![Gedit with HaH enabled](images/gedit-shot.png?raw=true "Gedit with HaH enabled")
