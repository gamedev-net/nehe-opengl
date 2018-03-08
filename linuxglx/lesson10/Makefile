CC = gcc -Wall -pedantic -ansi

all: lesson10

lesson10: lesson10.c
	$(CC) $<  -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11 -lm

clean:
	@echo Cleaning up...
	@rm lesson10
	@echo Done.
