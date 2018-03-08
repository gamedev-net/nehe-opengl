CC = gcc -Wall -pedantic -ansi

all: lesson19

lesson19: lesson19.c
	$(CC) $< -o $@  -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson19
	@echo Done.
