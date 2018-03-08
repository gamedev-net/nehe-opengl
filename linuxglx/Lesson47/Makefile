#Makefile for GLX_BASE

LIBS= -L/usr/X11R6/lib -lm -lGL -lGLU -lCg -lCgGL -lXxf86vm -lX11
PROJECT= Lesson47
SOURCES= glx_base.c main.c
OBJECTS= glx_base.o main.o
CC= gcc
CXXFLAGS= -O3 -Wall -ansi -pedantic -g

	
$(PROJECT): $(OBJECTS)
	@echo Linking
	$(CC) $(CXXFLAGS) $(OBJECTS) $(LIBS) -o $(PROJECT)
	@echo Compilation Complete

$(OBJECTS): $(SOURCES)
	@echo Compiling Sources
	$(CC) $(CXXFLAGS) -c $(SOURCES)

clean:
	@echo Deleting up $(OBJECTS) $(PROJECT)
	rm -f *.o;rm $(PROJECT)
