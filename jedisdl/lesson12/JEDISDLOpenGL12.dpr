program JEDISDLOpenGL12;
{******************************************************************}
{                                                                  }
{       Borland Delphi SDL with OpenGL Example                     }
{       Conversion of the SDL OpenGL Examples                      }
{                                                                  }
{ Portions created by Ti Leggett <leggett@eecs.tulane.edu>,  are   }
{ Copyright (C) 2001 Ti Leggett.                                   }
{ All Rights Reserved.                                             }
{                                                                  }
{ The original files are : lesson12.c                              }
{                                                                  }
{ The original Pascal code is : JEDISDLOpenGL12.dpr                }
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

  xrot : TGLfloat; // X Rotation
  yrot : TGLfloat; // Y Rotation

  box: TGLuint; // Storage For The Display List
  top: TGLuint; // Storage For The Second Display List
  xloop: TGLuint; // Loop For X Axis
  yloop: TGLuint; // Loop For Y Axis
  
  // Array For Box Colors 
  boxcol: array[0..4] of array[0..2] of TGLfloat =
  (
    (1.0, 0.0, 0.0), (1.0, 0.5, 0.0), (1.0, 1.0, 0.0), (0.0, 1.0, 0.0),
    (0.0, 1.0, 1.0)
  );

  // Array For Top Colors
  topcol: array[0..4] of array[0..2] of TGLfloat =
  (
    (0.5, 0.0, 0.0), (0.5, 0.25, 0.0), (0.5, 0.5, 0.0), (0.0, 0.5, 0.0),
    (0.0, 0.5, 0.5)
  );

  texture : TGLuint; // Storage For One Texture

  //Status indicator
  Status : Boolean = false;

procedure TerminateApplication;
begin
  SDL_QUIT;
  UnLoadOpenGL;
  Halt(0);
end;

procedure BuildLists;
begin
  box := glGenLists(2);

  glNewList(box, GL_COMPILE);
    glBegin(GL_QUADS);
      // Bottom Face
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f( -1.0, -1.0, -1.0 );
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f(  1.0, -1.0, -1.0 );
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f(  1.0, -1.0,  1.0 );
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f( -1.0, -1.0,  1.0 );

      // Front Face
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f( -1.0, -1.0,  1.0 );
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f(  1.0, -1.0,  1.0 );
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f(  1.0,  1.0,  1.0 );
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f( -1.0,  1.0,  1.0 );

      // Back Face
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f( -1.0, -1.0, -1.0 );
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f( -1.0,  1.0, -1.0 );
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f(  1.0,  1.0, -1.0 );
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f(  1.0, -1.0, -1.0 );

      // Right face 
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f( 1.0, -1.0, -1.0 );
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f( 1.0,  1.0, -1.0 );
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f( 1.0,  1.0,  1.0 );
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f( 1.0, -1.0,  1.0 );

      // Left Face 
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f( -1.0, -1.0, -1.0 );
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f( -1.0, -1.0,  1.0 );
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f( -1.0,  1.0,  1.0 );
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f( -1.0,  1.0, -1.0 );
    glEnd;
  glEndList;
  
  top := box + 1;  // Top list value is box list value plus 1
  // New compiled list, top  
  glNewList(top, GL_COMPILE);
    glBegin(GL_QUADS);
      // Top Face
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f( -1.0,  1.0, -1.0 );
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f( -1.0,  1.0,  1.0 );
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f(  1.0,  1.0,  1.0 );
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f(  1.0,  1.0, -1.0 );
    glEnd;
  glEndList;
end;

// Load Bitmaps And Convert To Textures
function LoadGLTextures : Boolean;
var
  // Create storage space for the texture
  TextureImage: PSDL_Surface;
begin
  // Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit
  TextureImage := SDL_LoadBMP('Data/cube.bmp');
  if ( TextureImage <> nil ) then
  begin
    // Set the status to true
    Status := true;
    
    // Create Texture
    glGenTextures( 1, @texture );
    // Typical Texture Generation Using Data From The Bitmap
    glBindTexture( GL_TEXTURE_2D, texture );

    // Generate The Texture 
    gluBuild2DMipmaps( GL_TEXTURE_2D, 3, TextureImage.w,
                       TextureImage.h, GL_BGR,
                       GL_UNSIGNED_BYTE, TextureImage.pixels );

    // Linear Filtering
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                     GL_LINEAR_MIPMAP_NEAREST );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
                     GL_LINEAR );
  end
  else
  begin
    Log.LogError( Format( 'Could not Load Image : %s', [SDL_GetError] ),
      'LoadGLTextures' );
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

  // Build our display lists */
  BuildLists;

  // Enable Texture Mapping
  glEnable( GL_TEXTURE_2D );

  // Enable smooth shading 
  glShadeModel( GL_SMOOTH );

  // Set the background black 
  glClearColor( 0.0, 0.0, 0.0, 0.5 );

  // Depth buffer setup 
  glClearDepth( 1.0 );

  // Enables Depth Testing 
  glEnable( GL_DEPTH_TEST );

  // The Type Of Depth Test To Do 
  glDepthFunc( GL_LEQUAL );

  // Enable lighting
  glEnable( GL_LIGHT0 );         // Quick And Dirty Lighting
  glEnable( GL_LIGHTING );       // Enable Lighting
  glEnable( GL_COLOR_MATERIAL ); // Enable Material Coloring

  // Really Nice Perspective Calculations
  glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

  result := true;
end;

// The main drawing function.
procedure DrawGLScene;
begin
  // Clear The Screen And The Depth Buffer
  glClear( GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );

  // Select Our Texture 
  glBindTexture( GL_TEXTURE_2D, texture );

  for yloop := 1 to 5 do
  begin
    for xloop := 0 to yloop - 1 do
    begin
      glLoadIdentity; // Reset The View
      glTranslatef(1.4 + ((xloop) * 2.8) - ((yloop) * 1.4), ((6.0
        - (yloop)) * 2.4) - 7.0, -20.0);
      // Tilt the cubes 
      // Tilt The Cubes Up And Down
      glRotatef( 45.0 - (2.0 * yloop) + xrot, 1.0, 0.0, 0.0 );

      // Spin Cubes Left And Right
      glRotatef( 45.0 + yrot, 0.0, 1.0, 0.0 );

      glColor3fv( @boxcol[yloop - 1] ); // Select A Box Color
      glCallList( box );               // Draw the box

      glColor3fv( @topcol[yloop - 1] ); // Select The Top Color
      glCallList( top );               // Draw The Top
    end;
  end;

  // swap buffers to display, since we're double buffered.
  SDL_GL_SwapBuffers;
end;

var
  Done : Boolean;
  event : TSDL_Event;
  keystate: PKeyStateArr;
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
  SDL_WM_SetCaption( 'Jeff Molofee''s OpenGL Code Tutorial 12 using JEDI-SDL', nil
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
    keystate := PKeyStateArr(SDL_GetKeyState(nil));
    if (keystate[SDLK_UP] <> 0) then
    begin
      {* Up arrow key was pressed
       * this affects x-rotation
       *}
      xrot := xrot - 0.2;
    end;

    if (keystate[SDLK_DOWN] <> 0) then
    begin
      {* Down arrow key was pressed
       * this affects x-rotation
       *}
      xrot := xrot + 0.2;
    end;

    if (keystate[SDLK_LEFT] <> 0) then
    begin
      {* Left arrow key was pressed
       * this affects y-rotation
       *}
      yrot := yrot - 0.2;
    end;

    if (keystate[SDLK_RIGHT] <> 0) then
    begin
      {* Right arrow key was pressed
       * this affects y-rotation
       *}
      yrot := yrot + 0.2;
    end;
    // draw the scene
    DrawGLScene;
  end;
  TerminateApplication;
end.

