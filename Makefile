all: gtk3hah.so gtk2hah.so

gtk3hah.so: gtk3hah.c
	gcc -shared -o gtk3hah.so gtk3hah.c  -fPIC -ggdb -O0 -fno-inline  `pkg-config gtk+-3.0 atspi-2 atk --cflags --libs`

gtk3hah.c: module.vala
	valac --pkg gtk+-3.0 --pkg atk -C module.vala
	mv module.c gtk3hah.c

gtk2hah.so: gtk2hah.c
	gcc -shared -o gtk2hah.so gtk2hah.c  -fPIC -ggdb -O0 -fno-inline  `pkg-config gtk+-2.0 atspi-2 atk --cflags --libs`

gtk2hah.c: module.vala
	valac --pkg gtk+-2.0 --pkg atk -D GTK2 -C module.vala
	mv module.c gtk2hah.c

clean:
	rm -f gtk3hah.so gtk3hah.c

.PHONY: all clean