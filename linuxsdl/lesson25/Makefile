all: Lesson25

Lesson25 : Lesson25.cpp
	g++ -o Lesson25 Lesson25.cpp -lGL -lGLU `sdl-config --cflags --libs` 

clean:
	rm -f *.o
	rm -f Lesson25

run: all
	./Lesson25
