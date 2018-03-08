CC = gcc -Wall -pedantic -ansi

all: lesson07

lesson07: lesson07.c
	$(CC) $< -o $@ -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

clean:
	@echo Cleaning up...
	@rm lesson07
	@echo Done.
