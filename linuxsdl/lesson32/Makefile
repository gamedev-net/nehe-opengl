CC = g++ -Wall -ansi

all:
	$(CC) lesson32.cpp -o lesson32 -lGL -lGLU `sdl-config --cflags --libs` -lSDL_mixer -L/usr/X11R6/lib

clean:
	@echo Cleaning up...
	@rm lesson32
	@echo Done.
