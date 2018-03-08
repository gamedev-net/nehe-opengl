CC = gcc -Wall -pedantic -ansi

all: lesson12

lesson12: lesson12.c
	$(CC) $<  -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson12
	@echo Done.
