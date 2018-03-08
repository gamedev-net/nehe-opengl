CC = gcc -Wall -pedantic -ansi

all: lesson02

lesson02: lesson02.c
	$(CC) $<  -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson02
	@echo Done.
