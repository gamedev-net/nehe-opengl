CC = gcc -Wall -pedantic -ansi

all: lesson08

lesson08: lesson08.c
	$(CC) $< -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson08
	@echo Done.
