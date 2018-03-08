OBJECTS= main.o nehe.o

CC= gcc

all: lesson36

%.o: %.c
	$(CC) -Os -Wall -ansi -pedantic -ffloat-store -c -g -o $@ $<

clean:
	rm -f *.o;rm lesson36

lesson36: $(OBJECTS)
	$(CC) -g -o lesson36 $(OBJECTS) -L/usr/X11R6/lib -lm -lGL -lXxf86vm -lX11
