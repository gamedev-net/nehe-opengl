all: Lesson24

Lesson24: Lesson24.cpp
	g++ -o Lesson24 Lesson24.cpp -lGL -lGLU `sdl-config --cflags --libs`

clean:
	rm -f *.o
	rm -f Lesson24

run: all
	./Lesson24
