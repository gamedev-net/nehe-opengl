CC = gcc -Wall -ansi

all:
	$(CC) lesson01.c -o lesson01 -lGL -lGLU `sdl-config --cflags --libs`

clean:
	@echo Cleaning up...
	@rm lesson01
	@echo Done.
