all: Lesson24.o
	g++ -o Lesson24 Lesson24.o -lGL -lGLU -lglut

Lesson24.o : Lesson24.cpp
	g++ -c Lesson24.cpp

clean:
	rm -f *.o
	rm -f Lesson24

run: all
	./Lesson24
