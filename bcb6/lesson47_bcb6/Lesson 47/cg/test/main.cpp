//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "main.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TFormMain *FormMain;
//---------------------------------------------------------------------------
__fastcall TFormMain::TFormMain(TComponent* Owner)
: TForm(Owner)
{
}
//---------------------------------------------------------------------------

int main0( int argc, char *argv[] );

void __fastcall TFormMain::ButtonTestClick(TObject *Sender)
{
   //
   char *args[1]={{"TestCG"}};
   main0(1/*argc*/, args );

}
//---------------------------------------------------------------------------
