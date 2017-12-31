OBJS=Lesson31.o MilkshapeModel.o Model.o

CFLAGS=-g
LD=g++ -g

all: $(OBJS)
	$(LD) $(OBJS) -o lesson31 -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lm

clean:
	@echo Cleaning up...
	@rm $(OBJS) lesson31
	@echo Done.
