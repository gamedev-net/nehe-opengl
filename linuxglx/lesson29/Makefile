CC = gcc -Wall -pedantic -ansi

all: lesson29

lesson29: lesson29.c
	$(CC) $< -o $@  -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11 -lm

clean:
	@echo Cleaning up...
	@rm lesson29
	@echo Done.
