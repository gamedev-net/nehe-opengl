#
# Project: Quaternion_Camera_Class
#
# Makefile for Linux
#

CPP  = g++
CC   = gcc
OBJ  = glCamera.o glHeightMap.o glPoint.o glQuaternion.o glVector.o Quaternion_Camera_Class.o
LIBS =  -L/usr/X11R6/lib -lglut -lGL -lGLU -lXext -lXmu -lX11 -lm
INCS =  -I/usr/X11R6/include
CXXINCS =  
BIN  = quarternion
CXXFLAGS = $(CXXINCS) $(INCS) -O2


.PHONY: all
all: $(BIN)

.SUFFIXES:	.cc

.cc.o:
	$(CPP) -c $< $(CXXFLAGS)

clean:
	rm -f $(OBJ) $(BIN) *~

$(BIN): $(OBJ)
	$(CPP) $(OBJ) -o $(BIN) $(LIBS)

glCamera.o: glCamera.cc

glHeightMap.o: glHeightMap.cc

glPoint.o: glPoint.cc

glQuaternion.o: glQuaternion.cc

glVector.o: glVector.cc

Quaternion_Camera_Class.o: Quaternion_Camera_Class.cc
