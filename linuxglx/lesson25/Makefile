OBJECTS= main.o nehe.o

CC= gcc

all: lesson25

%.o: %.c
	$(CC) -Os -Wall -ansi -pedantic -ffloat-store -c -g -o $@ $<

clean:
	rm -f *.o;rm lesson25

lesson25: $(OBJECTS)
	$(CC) -g -o lesson25 $(OBJECTS) -L/usr/X11R6/lib -lm -lGL -lXxf86vm -lX11
