CC = gcc -Wall -pedantic -ansi

all: lesson03

lesson03: lesson03.c
	$(CC) $< -o $@  -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson03
	@echo Done.
