CC = gcc -Wall -ansi

all:
	$(CC) main.cpp error.cpp lesson45.cpp -o lesson45 -L/usr/X11R6/lib/ -lGL -lGLU `sdl-config --cflags --libs`

clean:
	@echo Cleaning up...
	@rm lesson45
	@echo Done.
