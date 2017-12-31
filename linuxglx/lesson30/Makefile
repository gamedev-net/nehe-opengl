OBJS= image.o lesson30.o tmatrix.o tray.o tvector.o

CFLAGS=-g
LD=g++ -g

all: $(OBJS)
	$(LD) $(OBJS) -o lesson30 -L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lm

clean:
	@echo Cleaning up...
	@rm $(OBJS) lesson30
	@echo Done.
