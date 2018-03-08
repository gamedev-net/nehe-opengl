CC = gcc -Wall -pedantic -ansi

all: lesson17

lesson17: lesson17.c
	$(CC) $<  -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11 -lm

clean:
	@echo Cleaning up...
	@rm lesson17
	@echo Done.
