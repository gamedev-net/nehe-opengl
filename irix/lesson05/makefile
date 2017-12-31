INCLUDE = -I/usr/include -I/usr/local/glut/include
LIBDIR  = -L/usr/lib -L/usr/local/glut/glut/lib

COMPILERFLAGS = -xansi -fullwarn -O 
CC = cc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson5 

lesson5 : lesson5.o
	$(CC) $(CFLAGS) -o lesson5 $(LIBDIR) lesson5.o $(LIBRARIES)  
clean:
	rm lesson5 *.o
