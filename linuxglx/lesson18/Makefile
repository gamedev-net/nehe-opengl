CC = gcc -Wall -pedantic -ansi

all: lesson18

lesson18: lesson18.c
	$(CC) $<  -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson18
	@echo Done.
