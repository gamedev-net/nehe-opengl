TEMPLATE	= app
CONFIG		+= qt warn_on release thread
HEADERS		= glbox.h \
		  glwindow.h
SOURCES		= glbox.cpp \
		  glwindow.cpp \
		  main.cpp

unix {
  UI_DIR = .ui
  MOC_DIR = .moc
  OBJECTS_DIR = .obj
}

