OBJECTS= main.o nehe.o

CC= gcc

all: lesson34

%.o: %.c
	$(CC) -Os -Wall -ansi -pedantic -ffloat-store -c -g -o $@ $<

clean:
	rm -f *.o;rm lesson34

lesson34: $(OBJECTS)
	$(CC) -g -o lesson34 $(OBJECTS) -L/usr/X11R6/lib -lm -lGL -lXxf86vm -lX11
