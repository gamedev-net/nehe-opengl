#############################################################################
#
#  NeHe OpenGL Tutorial Lesson 27 for KDE
#
#############################################################################

INCLUDE =-I. -I.. -I/usr/X11R6/include
KDEINCLUDE =$(INCLUDE) -I$(QTDIR)/include
LIBDIR = -L/usr/X11R6/lib -L/usr/lib
KDELIBDIR = $(LIBDIR) -L$(QTDIR)/lib
LIBRARIES = -lGL -lGLU
KDELIBRARIES = $(LIBRARIES) -lkdecore -lkdeui -lkio -lkdesu -lkdefx -lqt-mt -lDCOP -lfam -lstdc++
CC = g++
COMPILERFLAGS = 
KDE_FLAGS =
CFLAGS = $(COMPILERFLAGS) $(LIBDIR)
KDE_CFLAGS = $(KDE_FLAGS) $(KDELIBDIR)
MOC = $(QTDIR)/bin/moc

all: Lesson27

#################################
Wnd.o: Wnd.cpp Wnd.h
	$(CC) -c Wnd.cpp $(KDE_CFLAGS) $(KDEINCLUDE) -o Wnd.o

Widget.o: Widget.cpp Widget.h 
	$(CC) -c Widget.cpp $(KDE_CFLAGS) $(KDEINCLUDE) -o Widget.o

Wnd.moc.cpp: Wnd.h
	$(MOC) ./Wnd.h -o Wnd.moc.cpp

Wnd.moc.o: Wnd.moc.cpp
	$(CC) -c Wnd.moc.cpp $(KDE_CFLAGS) $(KDEINCLUDE) -o Wnd.moc.o

Widget.moc.cpp: Widget.h
	$(MOC) ./Widget.h -o Widget.moc.cpp

Widget.moc.o: Widget.moc.cpp
	$(CC) -c Widget.moc.cpp $(KDE_CFLAGS) $(KDEINCLUDE) -o Widget.moc.o

Lesson27:  main.cpp Wnd.o Wnd.moc.o Widget.o Widget.moc.o
	$(CC) main.cpp Wnd.o Widget.o Widget.moc.o Wnd.moc.o $(KDE_CFLAGS) $(KDEINCLUDE) $(KDELIBRARIES) -o Lesson27

## To clean up vim backup files
bclean:
	rm -f *~

clean:
	rm -f *.o
	rm -f *.moc.cpp
	rm -f Lesson27

tar.gz:
	tar -cf Lesson27.tar main.cpp Widget.cpp Widget.h Wnd.cpp Wnd.h Makefile Data
	gzip Lesson27.tar
