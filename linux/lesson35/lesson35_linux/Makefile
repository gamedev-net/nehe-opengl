CC = g++
CC_OPT = -g -O2 -Wall #-march=i686 -DCPU=686

LIB_PATH  = -L./ -L/usr/X11R6/lib/
#LIBS = $(LIB_PATH) -lglut -lGL -lGLU -laviplay 
LIBS = -lglut -lGL -lGLU -laviplay 

INCLUDES = -I./ -I/usr/local/include


all:
	$(CC) $(CC_OPT) $(INCLUDES) $(LIBS) lesson35.cpp -o lesson35


clean:
	rm lesson35
