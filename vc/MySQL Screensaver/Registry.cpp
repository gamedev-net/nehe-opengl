//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: Registry.cpp
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#include "main.h"

//takes a 4-byte string and converts it into a 32-bit decimal number using
//WinAPI macros
#define MAKEDEC(a) MAKELONG(MAKEWORD(a[0], a[1]), MAKEWORD(a[2], a[3]));

//see the tutorial text for an explanation on the Windows Registry and what the following code does
void UpdateRegistry()
{
	HKEY RootKey = NULL;
   HKEY ScreensaverKey = NULL;
   
	if(RegOpenKeyEx(HKEY_CURRENT_USER, "Control Panel", 0, KEY_ALL_ACCESS, &RootKey) != ERROR_SUCCESS)
   	ShowError("UpdateRegistry() -> RegOpenKeyEx(RootKey)");

   RegCreateKey(RootKey, "Screen Saver.OpenGL Poem", &ScreensaverKey);

	if(RegSetValueEx(ScreensaverKey, "Text speed", NULL, REG_DWORD, (const BYTE*)&T, sizeof(DWORD)) != ERROR_SUCCESS)
   	ShowError("UpdateRegistry() -> RegSetValueEx(Text speed)");

   DWORD Scat = Scatter * 10;
   
	if(RegSetValueEx(ScreensaverKey, "Scatter speed", NULL, REG_DWORD, (const BYTE*)&Scat, sizeof(DWORD)) != ERROR_SUCCESS)
   	ShowError("UpdateRegistry() -> RegSetValueEx(Text speed)");

	char StringValue[256];

   ZeroMemory(StringValue, 256);
   SendMessage(ServerIPHandle, WM_GETTEXT, SendMessage(ServerIPHandle, WM_GETTEXTLENGTH, 0, 0) + 1, (DWORD)StringValue);
	if(RegSetValueEx(ScreensaverKey, "Server IP", NULL, REG_SZ, (const BYTE*)StringValue, strlen(StringValue)) != ERROR_SUCCESS)
   	ShowError("UpdateRegistry() -> RegSetValueEx(Server IP)");

   ZeroMemory(StringValue, 256);
   SendMessage(ServerPortHandle, WM_GETTEXT, SendMessage(ServerPortHandle, WM_GETTEXTLENGTH, 0, 0) + 1, (DWORD)StringValue);
   DWORD LongValue = atoi(StringValue);
	if(RegSetValueEx(ScreensaverKey, "Server port", NULL, REG_DWORD, (const BYTE*)&LongValue, sizeof(DWORD)) != ERROR_SUCCESS)
   	ShowError("UpdateRegistry() -> RegSetValueEx(Server port)");

   ZeroMemory(StringValue, 256);
   SendMessage(DatabaseNameHandle, WM_GETTEXT, SendMessage(DatabaseNameHandle, WM_GETTEXTLENGTH, 0, 0) + 1, (DWORD)StringValue);
	if(RegSetValueEx(ScreensaverKey, "Database name", NULL, REG_SZ, (const BYTE*)StringValue, strlen(StringValue)) != ERROR_SUCCESS)
   	ShowError("UpdateRegistry() -> RegSetValueEx(Database name)");

   ZeroMemory(StringValue, 256);
   SendMessage(UsernameHandle, WM_GETTEXT, SendMessage(UsernameHandle, WM_GETTEXTLENGTH, 0, 0) + 1, (DWORD)StringValue);
	if(RegSetValueEx(ScreensaverKey, "Username", NULL, REG_SZ, (const BYTE*)StringValue, strlen(StringValue)) != ERROR_SUCCESS)
   	ShowError("UpdateRegistry() -> RegSetValueEx(Username)");

   ZeroMemory(StringValue, 256);
   SendMessage(PasswordHandle, WM_GETTEXT, SendMessage(PasswordHandle, WM_GETTEXTLENGTH, 0, 0) + 1, (DWORD)StringValue);
	if(RegSetValueEx(ScreensaverKey, "Password", NULL, REG_SZ, (const BYTE*)StringValue, strlen(StringValue)) != ERROR_SUCCESS)
   	ShowError("UpdateRegistry() -> RegSetValueEx(Password)");

   ZeroMemory(StringValue, 256);
   SendMessage(SQLStatementHandle, WM_GETTEXT, SendMessage(SQLStatementHandle, WM_GETTEXTLENGTH, 0, 0) + 1, (DWORD)StringValue);
	if(RegSetValueEx(ScreensaverKey, "SQL statement", NULL, REG_SZ, (const BYTE*)StringValue, strlen(StringValue) + 1) != ERROR_SUCCESS)
   	ShowError("UpdateRegistry() -> RegSetValueEx(SQL statement)");

	RegCloseKey(RootKey);

   RegFlushKey(ScreensaverKey);
}

int ReadRegistry()
{
   BYTE DataValue[1024];
   DWORD DataType;
   DWORD DataSize = 1024;
	HKEY RootKey = NULL;

   char* SubKeyName = "Control Panel\\Screen Saver.OpenGL Poem";

	if(RegOpenKeyEx(HKEY_CURRENT_USER, SubKeyName, 0, KEY_ALL_ACCESS, &RootKey) != ERROR_SUCCESS)
   	{
		//if we can't open the key, it most likely doesn't exist - notify the user
		WinError("this is the first time you're running this screensaver and a registry entry for its settings does not exist yet. Run the saver in configuration mode and press \"Save and exit\" after entering the appropriate values. For now, default values will be used.");

      //set the default values

	   //the speed of the text - setting it to 75 means each character
   	//waits 75 milliseconds after the previous one was displayed -
	   //this results in 1000/75 = ~13 new charcaters to be displayed
   	//each second
		T = 75;
      Scatter = 5.f;
      ServerPort = 2000;
      Username = "Username";
      Password = "Password";
      Databasename = "Database";
      QueryText = "SELECT * FROM Table";
      ServerIP = "machine.domain.net";

		return -0x1;
      }

   DataSize = 1024;      
   //read the text speed
	if(RegQueryValueEx(RootKey, "Text speed", NULL, &DataType, DataValue, &DataSize) != ERROR_SUCCESS)
   	ShowError("ReadRegistry() -> RegQueryValueEx(Text speed)");
  	T = MAKEDEC(DataValue);

   DataSize = 1024;
   //read the scatter speed
	if(RegQueryValueEx(RootKey, "Scatter speed", NULL, &DataType, DataValue, &DataSize) != ERROR_SUCCESS)
   	ShowError("ReadRegistry() -> RegQueryValueEx(Scatter speed)");
	Scatter = (float)(int)MAKEDEC(DataValue);
   Scatter /= 10;

   DataSize = 1024;
   //read the server port
	if(RegQueryValueEx(RootKey, "Server port", NULL, &DataType, DataValue, &DataSize) != ERROR_SUCCESS)
   	ShowError("ReadRegistry() -> RegQueryValueEx(Server port)");
	ServerPort = (int)MAKEDEC(DataValue);

   DataSize = 1024;
 	//query the username
	if(RegQueryValueEx(RootKey, "Username", NULL, &DataType, DataValue, &DataSize) != ERROR_SUCCESS)
   	ShowError("ReadRegistry() -> RegQueryValueEx(Username)");
	Username = new char[DataSize];
   strcpy(Username, (char*)DataValue);

   DataSize = 1024;
 	//query the server IP
	if(RegQueryValueEx(RootKey, "Server IP", NULL, &DataType, DataValue, &DataSize) != ERROR_SUCCESS)
   	ShowError("ReadRegistry() -> RegQueryValueEx(Server IP)");
	ServerIP = new char[DataSize];
   strcpy(ServerIP, (char*)DataValue);

   DataSize = 1024;
 	//query the database name
	if(RegQueryValueEx(RootKey, "Database name", NULL, &DataType, DataValue, &DataSize) != ERROR_SUCCESS)
   	ShowError("ReadRegistry() -> RegQueryValueEx(Database name)");
	Databasename = new char[DataSize];
   strcpy(Databasename, (char*)DataValue);

   DataSize = 1024;
 	//query the password
	if(RegQueryValueEx(RootKey, "Password", NULL, &DataType, DataValue, &DataSize) != ERROR_SUCCESS)
   	ShowError("ReadRegistry() -> RegQueryValueEx(Password)");
	Password = new char[DataSize];
   strcpy(Password, (char*)DataValue);

   DataSize = 1024;
 	//query the SQL statement
	if(RegQueryValueEx(RootKey, "SQL statement", NULL, &DataType, DataValue, &DataSize) != ERROR_SUCCESS)
   	ShowError("ReadRegistry() -> RegQueryValueEx(SQL statement)");
   QueryText = new char[DataSize];
   strcpy(QueryText, (char*)DataValue);

	RegCloseKey(RootKey);

   return 0x1;
}

int RemoveRegistry()
{
	HKEY RootKey = NULL;

   char* SubKeyName = "Control Panel\\Screen Saver.OpenGL Poem";

	if(RegOpenKeyEx(HKEY_CURRENT_USER, SubKeyName, 0, KEY_ALL_ACCESS, &RootKey) == ERROR_SUCCESS)
		if(RegDeleteKey(RootKey, NULL) != ERROR_SUCCESS)
      	{
         ShowError("Could not remove the registry entry");
         return -0x1;
         }

   return 0x1;
}

