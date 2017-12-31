
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

#include <stdio.h>															// We're Including The Standard IO Header
#include <stdlib.h>															// And The Standard Lib Header
#include <GL/gl.h>															// We're Including The OpenGL Header
#include <GL/glu.h>															// And The GLu Header
#include <SDL/SDL.h>															// We're Including the Simple Directmedia Library
#include "Physics2.h"

#define APP_NAME	"NeHe & Erkin Tunca's Rope Physics Tutorial - SDL porting by Gianni Cestari"

#define SCREEN_W	800
#define SCREEN_H	600
#define SCREEN_BPP	16

typedef struct
{
    bool Visible;
    bool MouseFocus;
    bool KeyboardFocus;
} S_AppStatus;

int main(int, char **);

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
