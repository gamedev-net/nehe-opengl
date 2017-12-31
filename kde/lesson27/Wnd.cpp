
#include <qgl.h>
#include <kfiledialog.h>
#include <kapp.h>
#include <kmenubar.h>
#include <klocale.h>
#include <kmessagebox.h>
#include <kpopupmenu.h>
#include <qtextview.h>
#include <iostream>

#include "Widget.h"
#include "Wnd.h"

using namespace NeHe;
using namespace std;


MainWindow::MainWindow ( const char * name ) : KMainWindow ( 0L, name )
{
	setCaption("Banu Octavian & NeHe's Shadow Casting Tutorial");

	QPopupMenu *filemenu = new QPopupMenu;
	filemenu->insertItem( i18n( "&Next Object" ), this, SLOT(fileNext()) );
	filemenu->insertItem( i18n( "&Quit" ), kapp, SLOT(quit()) );
	QString about = i18n("NeHe OpenGL Tutorial 27\n\n"
	"To demonstrate Shadows\n"
	"KDE port for Linux by Zsolt Hajdu\n\n"
	"Oct - 2003\n");

	QPopupMenu *helpmenu = helpMenu( about );
	KMenuBar *menu = menuBar();
	menu->insertItem( i18n( "&File" ), filemenu);
	menu->insertSeparator();
	menu->insertItem( i18n( "&Help" ), helpmenu);

	widget_ = new Lesson27Widget( QGLFormat( QGLFormat::StencilBuffer |
									QGLFormat::DepthBuffer), this, "NeheLesson27" );
	if ( widget_ )
	{
		if ( widget_->format().stencil() && widget_->format().depth() )
			setCentralWidget( widget_ );
		else 
		{
			cout << "No proper Buffer !!!" << endl;
		}
	}
}

void MainWindow::fileNext()
{
	if ( widget_ )
		widget_->Rotate();
}

