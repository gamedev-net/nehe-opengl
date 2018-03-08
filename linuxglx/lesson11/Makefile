CC = gcc -Wall -pedantic -ansi

all: lesson11

lesson11: lesson11.c
	$(CC) $< -o $@  -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11 -lm

clean:
	@echo Cleaning up...
	@rm lesson11
	@echo Done.
