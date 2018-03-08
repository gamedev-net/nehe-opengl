CC = gcc -Wall -pedantic -ansi

all: lesson09

lesson09: lesson09.c
	$(CC) $< -o $@  -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson09
	@echo Done.
