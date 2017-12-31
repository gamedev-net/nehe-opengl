//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USEFORM("main.cpp", FormMain);
//---------------------------------------------------------------------------
WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR para, int paraanz)
{
try
{
   
   Application->Initialize();
   Application->CreateForm(__classid(TFormMain), &FormMain);
   Application->Run();
}
catch (Exception &exception)
{
   Application->ShowException(&exception);
}
return 0;
}
//---------------------------------------------------------------------------
