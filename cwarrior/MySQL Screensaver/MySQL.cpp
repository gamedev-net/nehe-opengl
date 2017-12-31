//Author: Kristo Kaas
//Ported for MSVC by: Brian Tegart
//
//Module name: MySQL.cpp
//Comes with: the GLPoem screensaver tutorial hosted at nehe.gamedev.net
//Copyright: see copyright.txt accompanying this source project
//Bugs/questions/suggestions/ideas: crispy@hot.ee

#include "main.h"
#include "include/mysql.h"

//RetrieveText() connects to a remote database and tries to retrieve a
//poem text. If it fails NULL is returned.
char* RetrieveText()
{
	char* Text = NULL;

	//http://www.mysql.com/doc/en/
   //create an SQL object
	MYSQL* MySQLObject;
   //create a database record object
   MYSQL_ROW Row;

   //try to initialize the SQL object
	if(!(MySQLObject = mysql_init((MYSQL*)0)))
   	{
   	WinError("Cannot initialize MySQL client");
      return NULL;
      }

   //try to connect to a remote database
	if(!mysql_real_connect(MySQLObject, ServerIP, Username, Password, Databasename, ServerPort, NULL, 0))
   	{
		WinError("Cannot connect to database");
      return NULL;
      }

   int Length;

   //submit the query
	if(!mysql_query(MySQLObject, QueryText))
   	{
      //acquire the record from the returned query results
		Row = mysql_fetch_row(mysql_store_result(MySQLObject));
      //get the length of the record
	   Length = strlen(*Row);

      //get the length and allocate memory for the text
      if(Length > 0)
	  	   Text = new char[Length];

      //copy the entire record into Text
		for(unsigned i = 0, j = 0; i < Length; i++)
	    	{
         //if there's a field change in the record, skip the newline
 			if((unsigned char)*(*Row + i + 1) == '\n')
   	   	continue;
		   else
				//otherwise just copy the character
   		 	Text[j++] = (char)*(*Row  + i);
   	   }
		}
	else
		WinError("  Cannot execute the specified query. Please check the syntax and semantics.\n"
      			" Possible causes: the query is invalid, the database and/or table does not exis\n"
               "                  exist at the specified IP address/port.                       ");

   return Text;
}

