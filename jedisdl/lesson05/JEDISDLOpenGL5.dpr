program JEDISDLOpenGL5;
{******************************************************************}
{                                                                  }
{       Borland Delphi SDL with OpenGL Example                     }
{       Conversion of the SDL OpenGL Examples                      }
{                                                                  }
{ Portions created by Ti Leggett <leggett@eecs.tulane.edu>,  are   }
{ Copyright (C) 2001 Ti Leggett.                                   }
{ All Rights Reserved.                                             }
{                                                                  }
{ The original files are : lesson05.c                              }
{                                                                  }
{ The original Pascal code is : JEDISDLOpenGL5.dpr                 }
{ The initial developer of the Pascal code is :                    }
{ Dominique Louis <Dominique@SavageSoftware.com.au>                }
{                                                                  }
{ Portions created by Dominique Louis are                          }
{ Copyright (C) 2001 Dominique Louis.                              }
{                                                                  }
{ Contributor(s)                                                   }
{ --------------                                                   }
{                                                                  }
{                                                                  }
{ Obtained through:                                                }
{ Joint Endeavour of Delphi Innovators ( Project JEDI )            }
{                                                                  }
{ You may retrieve the latest version of this file at the Project  }
{ JEDI home page, located at http://delphi-jedi.org                }
{                                                                  }
{ The contents of this file are used with permission, subject to   }
{ the Mozilla Public License Version 1.1 (the "License"); you may  }
{ not use this file except in compliance with the License. You may }
{ obtain a copy of the License at                                  }
{ http://www.mozilla.org/NPL/NPL-1_1Final.html                     }
{                                                                  }
{ Software distributed under the License is distributed on an      }
{ "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or   }
{ implied. See the License for the specific language governing     }
{ rights and limitations under the License.                        }
{                                                                  }
{ Description                                                      }
{ -----------                                                      }
{  Shows how to use OpenGL with the SDL libraries                  }
{                                                                  }
{                                                                  }
{ Requires                                                         }
{ --------                                                         }
{   SDL runtime libary somewhere in your path                      }
{   The Latest SDL runtime can be found on http://www.libsdl.org   }
{   Also Makes uses of Mike Lischke's Cross-Platform OpenGL header.}
{   You can pick it up from...                                     }
{   http://www.lischke-online.de/Graphics.html#OpenGL12            }
{                                                                  }
{ Programming Notes                                                }
{ -----------------                                                }
{                                                                  }
{                                                                  }
{                                                                  }
{                                                                  }
{                                                                  }
{ Revision History                                                 }
{ ----------------                                                 }
{   April   11 2001 - DL : Initial translation.                    }
{                                                                  }
{******************************************************************}

uses
  OpenGL12,
  SysUtils,
  Logger,
  SDL;

const
  // screen width, height, and bit depth 
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;
  SCREEN_BPP = 16;

var
  // This is our SDL surface
  surface : PSDL_Surface;

  rtri : TGLfloat = 0;
  rquad : TGLfloat = 0;

procedure TerminateApplication;
begin
  SDL_QUIT;
  UnLoadOpenGL;
  Halt(0);
end;

// function to reset our viewport after a window resize 
function ResizeWindow( width : integer; height : integer ) : Boolean;
begin
  // Protect against a divide by zero 
  if ( height = 0 ) then
    height := 1;

  // Setup our viewport. 
  glViewport( 0, 0, width, height );

  // change to the projection matrix and set our viewing volume. 
  glMatrixMode( GL_PROJECTION );
  glLoadIdentity;

  // Set our perspective 
  gluPerspective( 45.0, width / height, 0.1, 100.0 );

  // Make sure we're changing the model view and not the projection 
  glMatrixMode( GL_MODELVIEW );

  // Reset The View 
  glLoadIdentity;

  result := true;
end;

// function to handle key press events
procedure HandleKeyPress( keysym : PSDL_keysym );
begin
  case keysym.sym of
    SDLK_ESCAPE :
      // ESC key was pressed
      TerminateApplication;

    SDLK_RETURN :
    begin
      if (keysym.Modifier and KMOD_ALT <> 0) then
      begin
        {* Alt+Enter key was pressed
         * this toggles fullscreen mode
         *}
        SDL_WM_ToggleFullScreen( surface );
      end;
    end;
  end;
end;

// A general OpenGL initialization function.  Sets all of the initial parameters.
// We call this right after our OpenGL window is created.
procedure InitGL;
begin
  // Enable smooth shading 
  glShadeModel( GL_SMOOTH );

  // Set the background black 
  glClearColor( 0.0, 0.0, 0.0, 0.0 );

  // Depth buffer setup 
  glClearDepth( 1.0 );

  // Enables Depth Testing 
  glEnable( GL_DEPTH_TEST );

  // The Type Of Depth Test To Do 
  glDepthFunc( GL_LEQUAL );

  // Really Nice Perspective Calculations 
  glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
end;

// The main drawing function.
procedure DrawGLScene;
begin
  // Clear The Screen And The Depth Buffer
  glClear( GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );

  // Move Left 1.5 Units And Into The Screen 6.0
  glLoadIdentity;
  glTranslatef( -1.5, 0.0, -6.0 );

  // Rotate The Triangle On The Y axis ( NEW )
  glRotatef( rtri, 0.0, 1.0, 0.0 );

  // draw a triangle
  glBegin( GL_TRIANGLES  );            // Drawing Using Triangles
    glColor3f(   1.0,  0.0,  0.0 ); // Red                           
    glVertex3f(  0.0,  1.0,  0.0 ); // Top Of Triangle (Front)       
    glColor3f(   0.0,  1.0,  0.0 ); // Green                         
    glVertex3f( -1.0, -1.0,  1.0 ); // Left Of Triangle (Front)      
    glColor3f(   0.0,  0.0,  1.0 ); // Blue                          
    glVertex3f(  1.0, -1.0,  1.0 ); // Right Of Triangle (Front)     

    glColor3f(   1.0,  0.0,  0.0 ); // Red                           
    glVertex3f(  0.0,  1.0,  0.0 ); // Top Of Triangle (Right)       
    glColor3f(   0.0,  0.0,  1.0 ); // Blue                          
    glVertex3f(  1.0, -1.0,  1.0 ); // Left Of Triangle (Right)      
    glColor3f(   0.0,  1.0,  0.0 ); // Green                         
    glVertex3f(  1.0, -1.0, -1.0 ); // Right Of Triangle (Right)     

    glColor3f(   1.0,  0.0,  0.0 ); // Red                           
    glVertex3f(  0.0,  1.0,  0.0 ); // Top Of Triangle (Back)        
    glColor3f(   0.0,  1.0,  0.0 ); // Green                         
    glVertex3f(  1.0, -1.0, -1.0 ); // Left Of Triangle (Back)       
    glColor3f(   0.0,  0.0,  1.0 ); // Blue                          
    glVertex3f( -1.0, -1.0, -1.0 ); // Right Of Triangle (Back)      

    glColor3f(   1.0,  0.0,  0.0 ); // Red                           
    glVertex3f(  0.0,  1.0,  0.0 ); // Top Of Triangle (Left)        
    glColor3f(   0.0,  0.0,  1.0 ); // Blue                          
    glVertex3f( -1.0, -1.0, -1.0 ); // Left Of Triangle (Left)       
    glColor3f(   0.0,  1.0,  0.0 ); // Green                         
    glVertex3f( -1.0, -1.0,  1.0 ); // Right Of Triangle (Left)
  glEnd;                               // Finished Drawing The Triangle

  // Move Right 3 Units
  glLoadIdentity;
  glTranslatef( 1.5, 0.0, -6.0 );

  // Rotate The Quad On The X axis ( NEW )
  glRotatef( rquad, 1.0, 0.0, 0.0 );

  // Set The Color To Blue One Time Only
  glColor3f( 0.5, 0.5, 1.0);

  // draw a square (quadrilateral)
  glBegin( GL_QUADS );                 // Draw A Quad
    glColor3f(   0.0,  1.0,  0.0 ); // Set The Color To Green           
    glVertex3f(  1.0,  1.0, -1.0 ); // Top Right Of The Quad (Top)      
    glVertex3f( -1.0,  1.0, -1.0 ); // Top Left Of The Quad (Top)       
    glVertex3f( -1.0,  1.0,  1.0 ); // Bottom Left Of The Quad (Top)    
    glVertex3f(  1.0,  1.0,  1.0 ); // Bottom Right Of The Quad (Top)   

    glColor3f(   1.0,  0.5,  0.0 ); // Set The Color To Orange          
    glVertex3f(  1.0, -1.0,  1.0 ); // Top Right Of The Quad (Botm)     
    glVertex3f( -1.0, -1.0,  1.0 ); // Top Left Of The Quad (Botm)      
    glVertex3f( -1.0, -1.0, -1.0 ); // Bottom Left Of The Quad (Botm)   
    glVertex3f(  1.0, -1.0, -1.0 ); // Bottom Right Of The Quad (Botm)  

    glColor3f(   1.0,  0.0,  0.0 ); // Set The Color To Red             
    glVertex3f(  1.0,  1.0,  1.0 ); // Top Right Of The Quad (Front)    
    glVertex3f( -1.0,  1.0,  1.0 ); // Top Left Of The Quad (Front)     
    glVertex3f( -1.0, -1.0,  1.0 ); // Bottom Left Of The Quad (Front)  
    glVertex3f(  1.0, -1.0,  1.0 ); // Bottom Right Of The Quad (Front) 

    glColor3f(   1.0,  1.0,  0.0 ); // Set The Color To Yellow          
    glVertex3f(  1.0, -1.0, -1.0 ); // Bottom Left Of The Quad (Back)   
    glVertex3f( -1.0, -1.0, -1.0 ); // Bottom Right Of The Quad (Back)  
    glVertex3f( -1.0,  1.0, -1.0 ); // Top Right Of The Quad (Back)     
    glVertex3f(  1.0,  1.0, -1.0 ); // Top Left Of The Quad (Back)      

    glColor3f(   0.0,  0.0,  1.0 ); // Set The Color To Blue            
    glVertex3f( -1.0,  1.0,  1.0 ); // Top Right Of The Quad (Left)     
    glVertex3f( -1.0,  1.0, -1.0 ); // Top Left Of The Quad (Left)      
    glVertex3f( -1.0, -1.0, -1.0 ); // Bottom Left Of The Quad (Left)   
    glVertex3f( -1.0, -1.0,  1.0 ); // Bottom Right Of The Quad (Left)  

    glColor3f(   1.0,  0.0,  1.0 ); // Set The Color To Violet          
    glVertex3f(  1.0,  1.0, -1.0 ); // Top Right Of The Quad (Right)    
    glVertex3f(  1.0,  1.0,  1.0 ); // Top Left Of The Quad (Right)     
    glVertex3f(  1.0, -1.0,  1.0 ); // Bottom Left Of The Quad (Right)  
    glVertex3f(  1.0, -1.0, -1.0 ); // Bottom Right Of The Quad (Right) 
  glEnd;                               // Done Drawing The Quad

  // swap buffers to display, since we're double buffered.
  SDL_GL_SwapBuffers;

  // Increase The Rotation Variable For The Triangle ( NEW ) 
  rtri := rtri  + 1.0;
  // Decrease The Rotation Variable For The Quad     ( NEW )
  rquad := rquad - 0.95;
end;

var
  Done : Boolean;
  event : TSDL_Event;
  videoflags : Uint32;
  videoInfo : PSDL_VideoInfo;
begin
  // Load the appropriate .DLL or .SO
  LoadOpenGL;

  // Initialize SDL
  if ( SDL_Init( SDL_INIT_VIDEO ) < 0 ) then
  begin
    Log.LogError( Format( 'Could not initialize SDL : %s', [SDL_GetError] ),
      'Main' );
    TerminateApplication;
  end;

  // Fetch the video info 
  videoInfo := SDL_GetVideoInfo;

  if ( videoInfo = nil ) then
  begin
    Log.LogError( Format( 'Video query failed : %s', [SDL_GetError] ),
      'Main' );
    TerminateApplication;
  end;

  // the flags to pass to SDL_SetVideoMode 
  videoFlags := SDL_OPENGL;                  // Enable OpenGL in SDL 
  videoFlags := videoFlags or SDL_DOUBLEBUF; // Enable double buffering 
  videoFlags := videoFlags or SDL_HWPALETTE; // Store the palette in hardware 

  // This checks to see if surfaces can be stored in memory 
  if ( videoInfo.hw_available <> 0 ) then
    videoFlags := videoFlags or SDL_HWSURFACE
  else
    videoFlags := videoFlags or SDL_SWSURFACE;

  // This checks if hardware blits can be done * /
  if ( videoInfo.blit_hw <> 0 ) then
    videoFlags := videoFlags or SDL_HWACCEL;

  // Set the OpenGL Attributes
  SDL_GL_SetAttribute( SDL_GL_RED_SIZE, 5 );
  SDL_GL_SetAttribute( SDL_GL_GREEN_SIZE, 5 );
  SDL_GL_SetAttribute( SDL_GL_BLUE_SIZE, 5 );
  SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 16 );
  SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );

  // Set the title bar in environments that support it 
  SDL_WM_SetCaption( 'Jeff Molofee''s OpenGL Code Tutorial 5 using JEDI-SDL', nil
    );

  videoflags := videoFlags or SDL_RESIZABLE;    // Enable window resizing 

  surface := SDL_SetVideoMode( SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP,
    videoflags );
  if ( surface = nil ) then
  begin
    Log.LogError( Format( 'Unable to create OpenGL screen : %s', [SDL_GetError]
      ),
      'Main' );
    TerminateApplication;
  end;

  // Loop, drawing and checking events
  InitGL;
  ReSizeWindow( SCREEN_WIDTH, SCREEN_HEIGHT );

  Done := False;
  while ( not Done ) do
  begin
    // This could go in a separate function 
    while ( SDL_PollEvent( @event ) = 1 ) do
    begin
      case event.type_ of
        SDL_QUITEV :
        begin
          Done := true;
        end;

        SDL_KEYDOWN :
        begin
          // handle key presses
          HandleKeyPress( @event.key.keysym );
        end;

        SDL_VIDEORESIZE :
        begin
          surface := SDL_SetVideoMode( event.resize.w, event.resize.h, SCREEN_BPP, videoflags );
          if ( surface = nil ) then
          begin
            Log.LogError( Format( 'Could not get a surface after resize : %s', [SDL_GetError] ),
            'Main' );
            TerminateApplication;
          end;
          ResizeWindow( event.resize.w, event.resize.h );
        end;
      end;
    end;
    // draw the scene
    DrawGLScene;
  end;
  TerminateApplication;
end.

