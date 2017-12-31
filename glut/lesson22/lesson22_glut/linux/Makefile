all: nehegl_glut.o
	g++ -o ../exe/nehegl_glut nehegl_glut.o tga.o -lGL -lGLU -lglut

nehegl_glut.o : ../src/nehegl_glut.cpp ../src/frames.h ../src/tga.cpp ../src/tga.h
	g++ -c ../src/nehegl_glut.cpp
	g++ -c ../src/tga.cpp

clean:
	rm -f *.o
	rm -f ../exe/nehegl_glut
