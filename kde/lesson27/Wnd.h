
#ifndef _MAIN_H_
#define _MAIN_H_


#include <kmainwindow.h>

class Lesson27Widget;

namespace NeHe {
   
class MainWindow : public KMainWindow
{
  Q_OBJECT

	Lesson27Widget *widget_;

public:

  MainWindow ( const char * name );

public slots:

  void fileNext();
};

};

#endif

