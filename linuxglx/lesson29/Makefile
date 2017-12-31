CC = gcc -Wall -pedantic -ansi

all: lesson29.c
	$(CC) lesson29.c -o lesson29 -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lm

clean:
	@echo Cleaning up...
	@rm lesson29
	@echo Done.
