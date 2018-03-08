CC = gcc -Wall -pedantic -ansi

all: lesson28

lesson28: lesson28.c
	$(CC) $<  -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11 -lm

clean:
	@echo Cleaning up...
	@rm lesson28
	@echo Done.
