CC = gcc -Wall -pedantic -ansi

all: lesson01

lesson01: lesson01.c
	$(CC) $< -o $@  -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson01
	@echo Done.
