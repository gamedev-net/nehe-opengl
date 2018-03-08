CC = gcc -Wall -pedantic -ansi

all: lesson16

lesson16: lesson16.c
	$(CC) $< -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson16
	@echo Done.
