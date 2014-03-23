gtkhah.so: module.c
	gcc -shared -o gtkhah.so module.c  -fPIC -ggdb -O0 -fno-inline  `pkg-config gtk+-3.0 --cflags --libs` 

module.c: module.vala
	valac --pkg gtk+-3.0 --pkg atk -C module.vala
