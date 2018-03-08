CXX=g++
CXXFLAGS=-pedantic -g
OBJS=Lesson48.o NeHeGL.o ArcBall.o
LIBS=-L/usr/X11R6/lib -lGL -lGLU -lXxf86vm -lX11

all: lesson48

lesson48: $(OBJS)
	$(CXX) $(OBJS) -o $@ $(LIBS)

clean:
	rm -f $(OBJS)
