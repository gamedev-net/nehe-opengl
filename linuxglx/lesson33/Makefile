OBJECTS= main.o nehe.o TGALoader.o

CC= gcc

all: lesson33

%.o: %.c
	$(CC) -Os -Wall -ansi -pedantic -ffloat-store -c -g -o $@ $<

clean:
	rm -f *.o;rm lesson33;

lesson33: $(OBJECTS)
	$(CC) -g -o lesson33 $(OBJECTS) -L/usr/X11R6/lib -lm -lGL -lXxf86vm -lX11
