all: Lesson25.o
	g++ -o Lesson25 Lesson25.o -lGL -lGLU -lglut

Lesson25.o : Lesson25.cpp
	g++ -c Lesson25.cpp

clean:
	rm -f *.o
	rm -f Lesson25

run: all
	./Lesson25
