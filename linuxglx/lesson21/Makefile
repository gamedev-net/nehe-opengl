CC = gcc -Wall -pedantic -ansi -O2

all: lesson21

lesson21: lesson21.c
	$(CC) $< -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson21
	@echo Done.
