INCLUDE = -I/usr/include/
LIBDIR  = -L/usr/X11R6/lib 

COMPILERFLAGS = -Wall
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

# for all, set the targets to be every lesson1.c-lesson13.c 
# file, removing the .c extension.  That is, at this point,
# it would produce lesson1, lesson2, lesson3,...,lesson13 targets.
#
all: $(basename $(wildcard lesson[1-9].c lesson1[0-3].c))

# same as for all, except set the targets to be 
# lessonX.tar.gz from lessonX.c.  This is really
# only used to build smaller tutorial .tar.gz files
# to send to nehe.
#
dist: $(foreach file,$(basename $(wildcard lesson[1-9].c lesson1[0-3].c)),$(file).tar.gz)

# to produce, say, lesson1.tar.gz:
#
# 1. remove lesson1.tar.gz
# 2. build lesson1.tar containing README, makefile, lesson1.c, Data/lesson1/*.
# 3. gzip lesson1.tar.
#
lesson%.tar.gz : 
	tar cvf $(subst .tar.gz,.tar,$@) README makefile $(subst .tar.gz,.c,$@) $(wildcard Data/$(subst .tar.gz,,$@)/*); \
	gzip $(subst .tar.gz,.tar,$@);

# to produce, say, lesson1:
#
# 1. compile the thing.  uses the variables defined above.
# 
lesson% : lesson%.o
	$(CC) $(CFLAGS) -o $@ $(LIBDIR) $< $(LIBRARIES)  

# to clean up:
# delete all of the lessonX files.
clean:
	rm $(wildcard lesson[1-9] lesson1[0-3])

# to clean up the distributions:
# delete all of the lessonX.tar.gz files.
distclean:
	rm $(wildcard lesson[1-9].tar.gz lesson1[0-3].tar.gz)

