include /usr/include/make/commondefs

CC = CC
CFLAGS = -mips3 -n32 -O 
LFLAGS = -s
LIBRARIES = -lglut -lGLU -lGL -lXmu -lXext -lX11 -lm 
LIBDIR= -L/usr/people/christop/programs/glut-3.7/lib/glut.n32/
INCLUDE= -I/usr/people/christop/programs/glut-3.7/include
all:  Lesson21

Lesson21: Lesson21.o NeHeGL.o
	$(CC) -o Lesson21 $(LFLAGS) $(LIBDIR) Lesson21.o NeHeGL.o $(LIBRARIES)  

clean:
	/bin/rm -f Lesson21 *.o

.c++.o:
	$(CC) -c $(CFLAGS) $(INCLUDE) $*.c++ -o $*.o

