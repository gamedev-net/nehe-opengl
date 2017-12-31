CC=cc
all: Lesson26.o image.o
	 $(CC) -o Lesson26 -L/usr/X11R6/lib -lGL -lGLU -lglut image.o  Lesson26.o 

Lesson26.o : Lesson26.cpp
	$(CC) -c Lesson26.cpp

image.o : image.c
	$(CC) -c image.c

clean:
	rm -f *.o
	rm -f Lesson26

run: all
	./Lesson26
