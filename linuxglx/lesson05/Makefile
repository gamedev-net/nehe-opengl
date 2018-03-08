CC = gcc -Wall -pedantic -ansi

all: lesson05

lesson05: lesson05.c
	$(CC) $<  -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson05
	@echo Done.
