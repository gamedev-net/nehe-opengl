CC = gcc -Wall -ansi

all:
	$(CC) lesson21.c -o lesson21 -lGL -lGLU `sdl-config --cflags --libs` -lSDL_mixer

clean:
	@echo Cleaning up...
	@rm lesson21
	@echo Done.
