CC = gcc -Wall -pedantic -ansi

all: lesson13

lesson13: lesson13.c
	$(CC) $<  -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11 -lm

clean:
	@echo Cleaning up...
	@rm lesson13
	@echo Done.
