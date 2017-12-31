
/********************
*                   *
*   NeHeGL Header   *
*    SDL Version    *
*                   *
*********************************************************************************
*										*
*    You Need To Provide The Following Functions:				*
*										*
*    bool Initialize (void);							*
*        Performs All Your Initialization					*
*        Returns TRUE If Initialization Was Successful, FALSE If Not		*
*										*
*    void Deinitialize (void);							*
*        Performs All Your DeInitialization					*
*										*
*    void Update (Uint32 Milliseconds, Uint8 * Keys);				*
*        Perform Motion Updates							*
*        'Milliseconds' Is The Number Of Milliseconds Passed Since The Last Call*
*        With Whatever Accuracy SDL_GetTicks() Provides				*
*        'Keys' Is A Pointer To An Array Where The Snapshot Of The Keyboard	*
*        State Is Stored. The Snapshot Is Updated Every Time A Key Is Pressed	*
*										*
*    void Draw (void);								*
*        Perform All Your Scene Drawing						*
*										*
*********************************************************************************/


#ifndef _MAIN_H_
#define _MAIN_H_


#ifdef WIN32
#include <windows.h>
#else
#include <stdio.h>
#endif
#include <SDL.h>

#define APP_NAME	"NeHe OpenGL Basecode - SDL port by SnowDruid"

#define SCREEN_W	640
#define SCREEN_H	480
#define SCREEN_BPP	16

#define LOG_FILE	"log.txt"

typedef unsigned char	bool;

#ifndef true
#define true	1
#endif
#ifndef false
#define false	0
#endif

typedef struct
{
    bool Visible;
    bool MouseFocus;
    bool KeyboardFocus;
} S_AppStatus;

int main(int, char **);

bool InitErrorLog(void);
void CloseErrorLog(void);
int  Log(char *, ...);

bool InitTimers(Uint32 *);
bool InitGL(SDL_Surface *);
bool CreateWindowGL(SDL_Surface *, int, int, int, Uint32);

void ReshapeGL(int, int);
void ToggleFullscreen(void);
void TerminateApplication(void);

bool Initialize(void);
void Deinitialize(void);
void Update(Uint32, Uint8 *);
void Draw(void);

#endif
