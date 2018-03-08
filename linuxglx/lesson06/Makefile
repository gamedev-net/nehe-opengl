CC = gcc -Wall -pedantic -ansi

all: lesson06

lesson06: lesson06.c
	$(CC) $<  -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson06
	@echo Done.
