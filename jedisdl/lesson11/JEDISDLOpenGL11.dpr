program JEDISDLOpenGL11;
{******************************************************************}
{                                                                  }
{       Borland Delphi SDL with OpenGL Example                     }
{       Conversion of the SDL OpenGL Examples                      }
{                                                                  }
{ Portions created by Ti Leggett <leggett@eecs.tulane.edu>,  are   }
{ Copyright (C) 2001 Ti Leggett.                                   }
{ All Rights Reserved.                                             }
{                                                                  }
{ The original files are : lesson11.c                              }
{                                                                  }
{ The original Pascal code is : JEDISDLOpenGL11.dpr                }
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

  xrot : TGLfloat; // X Rotation ( NEW )
  yrot : TGLfloat; // Y Rotation ( NEW ) 
  zrot : TGLfloat ; // Z Rotation ( NEW ) 

  points : array[0..44] of array[0..44] of array[0..2] of TGLfloat ;    // The Points On The Grid Of Our "Wave" */
  wiggle_count : integer = 0; // Counter Used To Control How Fast Flag Waves */
  hold : TGLfloat;            // Temporarily Holds A Floating Point Value */

  texture : TGLuint; // Storage For One Texture ( NEW )

  //Status indicator
  Status : Boolean = false;
  
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
  TextureImage := SDL_LoadBMP('Data/tim.bmp');
  if ( TextureImage <> nil ) then
  begin
    // Set the status to true
    Status := true;
    
    // Create Texture
    glGenTextures( 1, @texture );
    // Typical Texture Generation Using Data From The Bitmap
    glBindTexture( GL_TEXTURE_2D, texture );

    // Generate The Texture
    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage.w,
			  TextureImage.h, 0, GL_BGR,
			  GL_UNSIGNED_BYTE, TextureImage.pixels );

    // Linear Filtering
    // scale linearly when image bigger than texture
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    // scale linearly when image smaller than texture
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
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
var
  x, y : integer; 
begin
  // Load in the texture
  if ( not LoadGLTextures ) then
  begin
    result := false;
    exit;
  end;

  // Enable Texture Mapping ( NEW )
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

  // Really Nice Perspective Calculations 
  glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

  // Fill the back with the texture. The front will only be wireline
  glPolygonMode( GL_BACK, GL_FILL );
  glPolygonMode( GL_FRONT, GL_LINE );

  // Loop Through The X Plane
  for x := 0 to 44 do
  begin
    // Loop Through The Y Plane
    for y := 0 to 44 do
    begin
      // Apply The Wave To Our Mesh
      points[x][y][0] := (x / 5.0) - 4.5;
      points[x][y][1] := (y / 5.0) - 4.5;
      points[x][y][2] := sin((((x / 5.0) * 40.0) / 360.0) * 3.141592654 * 2.0);
    end;
  end;

  result := true;
end;

// The main drawing function.
procedure DrawGLScene;
var
  x, y : integer;                       // Loop Variables */
  float_x, float_y, float_xb, float_yb : single ; // Used To Break The Flag Into Tiny Quads
begin
  // Clear The Screen And The Depth Buffer
  glClear( GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );

  // Reset The Current Matrix
  glLoadIdentity;
  // Translate 17 Units Into The Screen
  glTranslatef( 0.0, 0.0, -12.0 );

  glRotatef( xrot, 1.0, 0.0, 0.0 ); // Rotate On The X Axis
  glRotatef( yrot, 0.0, 1.0, 0.0 ); // Rotate On The Y Axis
  glRotatef( zrot, 0.0, 0.0, 1.0 ); // Rotate On The Z Axis

  // Select Our Texture 
  glBindTexture( GL_TEXTURE_2D, texture );

  // Start Drawing Our Quads
  glBegin(GL_QUADS);
  for x := 0 to 43 do
  begin
    for y := 0 to 43 do
    begin
      float_x := x / 44;
      float_y := y / 44;
      float_xb := (x + 1) / 44;
      float_yb := (y + 1) / 44;

      glTexCoord2f(float_x, float_y);
      glVertex3f(points[x][y][0], points[x][y][1], points[x][y][2]);
      glTexCoord2f(float_x, float_yb);
      glVertex3f(points[x][y + 1][0], points[x][y + 1][1], points[x][y + 1][2]);

      glTexCoord2f(float_xb, float_yb);
      glVertex3f(points[x + 1][y + 1][0], points[x + 1][y + 1][1], points[x +
        1][y + 1][2]);
      glTexCoord2f(float_xb, float_y);
      glVertex3f(points[x + 1][y][0], points[x + 1][y][1], points[x + 1][y][2]);
    end;
  end;
  glEnd();
  
  if (wiggle_count = 2) then
  begin
    for y := 0 to 44 do
    begin
      hold := points[0][y][2];			// Store Current Value One Left Side Of Wave
      for x := 0 to 43 do
      begin
        // Current Wave Value Equals Value To The Right
        points[x][y][2] := points[x+1][y][2];
      end;
      points[44][y][2] := hold; // Last Value Becomes The Far Left Stored Value
    end;
    wiggle_count := 0;
  end;
  
  inc(wiggle_count);
  
  xrot := xrot + 0.3;      // Increase the X Rotation variable
  yrot := xrot + 0.2;      // Increase the Y Rotation variable
  zrot := xrot + 0.4;      // Increase the Z Rotation variable

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
  SDL_WM_SetCaption( 'Jeff Molofee''s OpenGL Code Tutorial 11 using JEDI-SDL', nil
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

