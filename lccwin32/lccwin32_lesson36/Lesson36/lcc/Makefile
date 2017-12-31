# Wedit Makefile for project nehe_radial
SRCDIR=c:\lcc\projects\nehe_radial\lesson36
CFLAGS=-Ic:\lcc\include  -g2 
CC=$(LCCROOT)\bin\lcc.exe
LINKER=$(LCCROOT)\bin\lcclnk.exe
OBJS=\
	lesson36.obj \

LIBS=glu32.lib opengl32.lib
EXE=nehe_radial.exe

$(EXE):	$(OBJS) Makefile
	$(LINKER)  -subsystem windows -o $(SRCDIR)\lcc\nehe_radial.exe $(OBJS) $(LIBS)

# Build lesson36.c
LESSON36_C=\

lesson36.obj: $(LESSON36_C) $(SRCDIR)\lesson36.c
	$(CC) -c $(CFLAGS) $(SRCDIR)\lesson36.c

link:
	$(LINKER)  -subsystem windows -o $(SRCDIR)\lcc\nehe_radial.exe $(OBJS) $(LIBS)

clean:
	del $(OBJS) c:\lcc\projects\nehe_radial\lesson36\lcc\nehe_radial.exe
