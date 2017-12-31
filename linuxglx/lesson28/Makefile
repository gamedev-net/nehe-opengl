CC = gcc -Wall -pedantic -ansi

all: lesson28.c
	$(CC) lesson28.c -o lesson28 -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lm

clean:
	@echo Cleaning up...
	@rm lesson28
	@echo Done.
