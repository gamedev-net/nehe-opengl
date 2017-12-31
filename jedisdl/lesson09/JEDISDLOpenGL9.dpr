program JEDISDLOpenGL9;
{******************************************************************}
{                                                                  }
{       Borland Delphi SDL with OpenGL Example                     }
{       Conversion of the SDL OpenGL Examples                      }
{                                                                  }
{ Portions created by Ti Leggett <leggett@eecs.tulane.edu>,  are   }
{ Copyright (C) 2001 Ti Leggett.                                   }
{ All Rights Reserved.                                             }
{                                                                  }
{ The original files are : lesson09.c                              }
{                                                                  }
{ The original Pascal code is : JEDISDLOpenGL9.dpr                 }
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

type
  TStar = record // Star structure
    r, g, b: TGLubyte; // stars color
    dist: TGLfloat; // stars distance from center
    angle: TGLfloat; // stars current angle
  end; // name is stars

const
  // screen width, height, and bit depth
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;
  SCREEN_BPP = 16;

  STAR_NUM = 50; // number of stars to have
  
var
  // This is our SDL surface
  surface : PSDL_Surface;

  // Twinkling stars
  twinkle : Boolean = FALSE;

  stars: array[0..STAR_NUM - 1] of TStar;
  // make 'star' array of STAR_NUM size using info from the structure 'stars'
  zoom: TGLfloat = -15.0; // viewing distance from stars.
  tilt: TGLfloat = 90.0; // tilt the view
  //spin: TGLfloat; // spin twinkling stars
  loop: TGLuint; // general loop variable
  texture: TGLuint; // Storage For 1 Texture

  //Status indicator
  Status : Boolean = false;

  spin : TGlFloat = 0;
  
procedure TerminateApplication;
begin
  SDL_QUIT;
  UnLoadOpenGL;
  Halt(0);
end;

// Load Bitmaps And Convert To Textures
function LoadGLTextures : Boolean;
var
  // Create storage space for the texture
  TextureImage: PSDL_Surface;
begin
  // Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit
  TextureImage := SDL_LoadBMP('Data/star.bmp');
  if ( TextureImage <> nil ) then
  begin
    // Set the status to true
    Status := true;
    
    // Create Texture
    glGenTextures( 1, @texture );

    // Load in texture 1
    // Typical Texture Generation Using Data From The Bitmap
    glBindTexture( GL_TEXTURE_2D, texture );

    // Linear Filtering 
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

    // Generate The Texture
    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage.w,
                  TextureImage.h, 0, GL_BGR,
                  GL_UNSIGNED_BYTE, TextureImage.pixels );
  end
  else
  begin
    Log.LogError( Format( 'Could not Load Image : %s', [SDL_GetError] ),
      'LoadGLTextures' );
    TerminateApplication;
  end;

  // Free up any memory we may have used
  if ( TextureImage <> nil ) then
    SDL_FreeSurface( TextureImage );

  result := Status;
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
    SDLK_t:
      {* 't' key was pressed
       * this toggles the twinkling of the stars
       *}
      twinkle := not twinkle;

    SDLK_PAGEUP:
      {* PageUp key was pressed
       * this zooms into the scene
       *}
      zoom  := zoom  - 0.02;

    SDLK_PAGEDOWN:
      {* PageDown key was pressed
       * this zooms out of the scene
       *}
      zoom  := zoom  + 0.02;

    SDLK_UP:
      {* Up arrow key was pressed
       * this changes the tilt of the stars
       *}
      tilt  := tilt - 0.5;

    SDLK_DOWN:
      {* Up arrow key was pressed
       * this changes the tilt of the stars
       *}
      tilt  := tilt + 0.5;

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
function InitGL : Boolean;
begin
  // Load in the texture
  if ( not LoadGLTextures ) then
  begin
    result := false;
    exit;
  end;

  // Enable Texture Mapping
  glEnable( GL_TEXTURE_2D );

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

  glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  // Set The Blending Function For Translucency
  glEnable(GL_BLEND); // Enable Blending

  Randomize;
  // set up the stars
  for loop := 0 to STAR_NUM - 1 do
  begin
    stars[loop].angle := 0.0; // initially no rotation.
    stars[loop].dist := loop * 1.0 / STAR_NUM * 5.0;
    // calculate distance form the center
    stars[loop].r := TGLubyte( random(256) ); // random red intensity;
    stars[loop].g := TGLubyte( random(256) ); // random green intensity;
    stars[loop].b := TGLubyte( random(256) ); // random blue intensity;
  end;

  result := true;
end;

// The main drawing function.
procedure DrawGLScene;
begin
  // Clear The Screen And The Depth Buffer
  glClear( GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );

  // Reset the view
  glBindTexture( GL_TEXTURE_2D, texture ); 
  glLoadIdentity;

  for loop := 0 to STAR_NUM - 1 do // loop through all the stars.
  begin
    glLoadIdentity(); // reset the view before we draw each star.
    glTranslatef(0.0, 0.0, zoom); // zoom into the screen.
    glRotatef(tilt, 1.0, 0.0, 0.0); // tilt the view.
    glRotatef(stars[loop].angle, 0.0, 1.0, 0.0); // rotate to the current star's angle.
    
    glTranslatef(stars[loop].dist, 0.0, 0.0);   // move forward on the X plane (the star's x plane).
    
    glRotatef(-stars[loop].angle, 0.0, 1.0, 0.0); // cancel the current star's angle.
    
    glRotatef(-tilt, 1.0, 0.0, 0.0); // cancel the screen tilt.
    if (twinkle) then
    begin // twinkling stars enabled ... draw an additional star.
      // assign a color using bytes
      glColor4ub( stars[STAR_NUM - loop].r, stars[STAR_NUM - loop].g, stars[STAR_NUM
        - loop].b,  TGLubyte(255));
      glBegin(GL_QUADS); // begin drawing the textured quad.
      glTexCoord2f(0.0, 0.0);
      glVertex3f(-1.0, -1.0, 0.0);
      glTexCoord2f(1.0, 0.0);
      glVertex3f(1.0, -1.0, 0.0);
      glTexCoord2f(1.0, 1.0);
      glVertex3f(1.0, 1.0, 0.0);
      glEnd; // done drawing the textured quad.
    end;
    // main star
    glRotatef(spin, 0.0, 0.0, 1.0); // rotate the star on the z axis.
    // Assign A Color Using Bytes
    glColor4ub(stars[loop].r, stars[loop].g, stars[loop].b, TGLubyte(255));
    glBegin(GL_QUADS); // Begin Drawing The Textured Quad
    glTexCoord2f(0.0, 0.0);
    glVertex3f(-1.0, -1.0, 0.0);
    glTexCoord2f(1.0, 0.0);
    glVertex3f(1.0, -1.0, 0.0);
    glTexCoord2f(1.0, 1.0);
    glVertex3f(1.0, 1.0, 0.0);
    glTexCoord2f(0.0, 1.0);
    glVertex3f(-1.0, 1.0, 0.0);
    glEnd; // Done Drawing The Textured Quad
    spin := spin + 0.01; // used to spin the stars.
    stars[loop].angle := stars[loop].angle + (loop * 1.0 / STAR_NUM * 1.0);
      // change star angle.
    stars[loop].dist := stars[loop].dist - 0.01; // bring back to center.
    randomize;
    if (stars[loop].dist < 0.0) then // star hit the center
    begin
      stars[loop].dist := stars[loop].dist + 5.0; // move 5 units from the center.
      stars[loop].r := TGLubyte( random(256) ); // new red color.
      stars[loop].g := TGLubyte( random(256) ); // new green color.
      stars[loop].b := TGLubyte( random(256) ); // new blue color.
    end;
  end;

  // swap buffers to display, since we're double buffered.
  SDL_GL_SwapBuffers;
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
  SDL_WM_SetCaption( 'Jeff Molofee''s OpenGL Code Tutorial 9 using JEDI-SDL', nil
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
          InitGL;
          ResizeWindow( event.resize.w, event.resize.h );
        end;
      end;
    end;
    // draw the scene
    DrawGLScene;
  end;
  TerminateApplication;
end.

