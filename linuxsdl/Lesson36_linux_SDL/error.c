
/**************************************
*                                     *
*   Jeff Molofee's Basecode Example   *
*   SDL porting by Fabio Franchello   *
*          nehe.gamedev.net           *
*                2001                 *
*                                     *
***************************************
*                                     *
*   Basic Error Handling Routines:    *
*                                     *
*   InitErrorLog() Inits The Logging  *
*   CloseErrorLog() Stops It          *
*   Log() Is The Logging Funtion,     *
*   It Works Exactly Like printf()    *
*                                     *
**************************************/


// Includes
#ifdef WIN32										// If We're under MSVC
#include <windows.h>								// We Need The Windows Header
#else												// Otherwhise
#include <stdio.h>									// We Need The Standard IO Header
#include <stdlib.h>									// The Standard Library Header
#include <stdarg.h>									// And The Standard Argument Header For va_list
#endif												// Then

#include <SDL.h>									// We Want To Have The SDL Header :)
#include "main.h"									// And The Basecode Header


// Globals
static FILE *ErrorLog;								// The File For Error Logging


// Code
bool InitErrorLog(void)								// Initializes Error Logging
{
	if(!(ErrorLog = fopen(LOG_FILE, "w")))			// If We Can't Open LOG_FILE For Writing
	{
		perror("Can't init Logfile!\n" );			// Report With perror() (Standard + Explains Cause Of The Error) 
		exit(1);									// And Exit, This Is Critical, We Want Logging
	}

	Log("%s -- Log Init...\n", APP_NAME);			// We Print The Name Of The App In The Log

	return true;									// Otherwhise Return TRUE (Everything Went OK)
}

void CloseErrorLog(void)							// Closes Error Logging
{
	Log("-- Closing Log...\n");						// Print The End Mark

	if(ErrorLog)									// If The File Is Open
	{
		fclose(ErrorLog);							// Close It
	}

	return;											// And Return, Quite Plain Huh? :)
}

int Log(char *szFormat, ...)						// Add A Line To The Log
{
	va_list Arg;									// We're Using The Same As The printf() Family, A va_list
													// To Substitute The Tokens Like %s With Their Value In The Output

	va_start(Arg,szFormat);							// We Start The List

	if(ErrorLog)									// If The Log Is Open
	{
		vfprintf(ErrorLog, szFormat, Arg);			// We Use vprintf To Perform Substituctions
		fflush(ErrorLog);							// And Ensure The Line Is Written, The Log Must Be Quick
	}

	va_end(Arg);									// We End The List

	return 0;										// And Return A Ok
}

