OBJECTS= main.o nehe.o

CC= gcc

all: lesson37

%.o: %.c
	$(CC) -O2 -Wall -ansi -pedantic -ffloat-store -c -g -o $@ $<

clean:
	rm -f *.o;rm lesson37;

lesson37: $(OBJECTS)
	$(CC) -O2 -g -o lesson37 $(OBJECTS) -L/usr/X11R6/lib -lm -lGL -lXxf86vm -lX11
