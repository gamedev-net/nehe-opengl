CC = gcc -Wall -pedantic -ansi

all: lesson04

lesson04: lesson04.c
	$(CC) $< -o $@  -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson04
	@echo Done.
