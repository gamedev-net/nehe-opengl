CC = gcc -Wall -ansi
SOURCE = lesson43.cpp FreeType.cpp
FREETYPE_INCLUDE = /usr/include/freetype2
FLAGS = -lGL -lGLU -lfreetype `sdl-config --cflags --libs`
BINARY = freetype

all:
	$(CC) $(SOURCE) -o $(BINARY) $(FLAGS) -I$(FREETYPE_INCLUDE)

clean:
	@echo Cleaning up...
	@rm $(BINARY)
	@echo Done.
