program JEDISDLOpenGL7;
{******************************************************************}
{                                                                  }
{       Borland Delphi SDL with OpenGL Example                     }
{       Conversion of the SDL OpenGL Examples                      }
{                                                                  }
{ Portions created by Ti Leggett <leggett@eecs.tulane.edu>,  are   }
{ Copyright (C) 2001 Ti Leggett.                                   }
{ All Rights Reserved.                                             }
{                                                                  }
{ The original files are : lesson07.c                              }
{                                                                  }
{ The original Pascal code is : JEDISDLOpenGL7.dpr                 }
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

  // Whether or not lighting is on
  light : Boolean = FALSE;

  xrot : TGLfloat ;      // X Rotation 
  yrot : TGLfloat ;      // Y Rotation 
  xspeed : TGLfloat ;    // X Rotation Speed 
  yspeed : TGLfloat ;    // Y Rotation Speed 
  z : TGLfloat = -5.0;    // Depth Into The Screen

  // Ambient Light Values ( NEW )
  LightAmbient: array[0..3] of TGLfloat = (0.5, 0.5, 0.5, 1.0);
  // Diffuse Light Values ( NEW )
  LightDiffuse: array[0..3] of TGLfloat = (1.0, 1.0, 1.0, 1.0);
  // Light Position ( NEW )
  LightPosition: array[0..3] of TGLfloat = (0.0, 0.0, 2.0, 1.0);

  filter : TGLuint;     // Which Filter To Use  ( NEW )
  texture : array[0..2] of TGLuint; // Storage For 3 Textures ( NEW )

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
  TextureImage := SDL_LoadBMP('Data/crate.bmp');
  if ( TextureImage <> nil ) then
  begin
    // Set the status to true
    Status := true;
    
    // Create Texture
    glGenTextures( 3, @texture[0] );

    // Load in texture 1 
    // Typical Texture Generation Using Data From The Bitmap 
    glBindTexture( GL_TEXTURE_2D, texture[0] );

    // Generate The Texture 
    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage.w,
                  TextureImage.h, 0, GL_BGR,
                  GL_UNSIGNED_BYTE, TextureImage.pixels );

    // Nearest Filtering 
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                     GL_NEAREST );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
                     GL_NEAREST );

    // Load in texture 2 
    // Typical Texture Generation Using Data From The Bitmap 
    glBindTexture( GL_TEXTURE_2D, texture[1] );

    // Linear Filtering 
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                     GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
                     GL_LINEAR );

    // Generate The Texture 
    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage.w,
                  TextureImage.h, 0, GL_BGR,
                  GL_UNSIGNED_BYTE, TextureImage.pixels );

    // Load in texture 3 
    // Typical Texture Generation Using Data From The Bitmap 
    glBindTexture( GL_TEXTURE_2D, texture[2] );

    // Mipmapped Filtering 
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                     GL_LINEAR_MIPMAP_NEAREST );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
                     GL_LINEAR );

    // Generate The MipMapped Texture ( NEW )
    gluBuild2DMipmaps( GL_TEXTURE_2D, 3, TextureImage.w,
                       TextureImage.h, GL_BGR,
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

    SDLK_f:
    begin
      {* 'f' key was pressed
       * this pages through the different filters
       *}
      inc( filter );
      if ( filter > 2 ) then
        filter := 0;
    end;

    SDLK_l:
    begin
      {* 'l' key was pressed
       * this toggles the light
       *}
      light := not light;
      if ( not light ) then
        glDisable( GL_LIGHTING )
      else
        glEnable( GL_LIGHTING );
    end;

    SDLK_PAGEUP:
      {* PageUp key was pressed
       * this zooms into the scene
       *}
      z := z - 0.02;

    SDLK_PAGEDOWN:
      {* PageDown key was pressed
       * this zooms out of the scene
       *}
      z := z + 0.02;

    SDLK_UP:
      {* Up arrow key was pressed
       * this affects the x rotation
       *}
      xspeed := xspeed - 0.01;

    SDLK_DOWN:
      {* Down arrow key was pressed
       * this affects the x rotation
       *}
      xspeed := xspeed + 0.01;

    SDLK_RIGHT:
      {* Right arrow key was pressed
       * this affects the y rotation
       *}
      yspeed := yspeed + 0.01;

    SDLK_LEFT:
      {* Left arrow key was pressed
       * this affects the y rotation
       *}
      yspeed := yspeed - 0.01;

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

  // Enable Texture Mapping ( NEW )
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

  // Setup The Ambient Light 
  glLightfv( GL_LIGHT1, GL_AMBIENT, @LightAmbient );

  // Setup The Diffuse Light
  glLightfv( GL_LIGHT1, GL_DIFFUSE, @LightDiffuse );

  // Position The Light
  glLightfv( GL_LIGHT1, GL_POSITION, @LightPosition );

  // Enable Light One 
  glEnable( GL_LIGHT1 );
  
  result := true;
end;

// The main drawing function.
procedure DrawGLScene;
begin
  // Clear The Screen And The Depth Buffer
  glClear( GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );

  // Reset the view 
  glLoadIdentity;

  // Translate Into/Out Of The Screen By z 
  glTranslatef( 0.0, 0.0, z );

  glRotatef( xrot, 1.0, 0.0, 0.0 ); // Rotate On The X Axis
  glRotatef( yrot, 0.0, 1.0, 0.0 ); // Rotate On The Y Axis

  // Select A Texture Based On filter
  glBindTexture( GL_TEXTURE_2D, texture[filter] );

  // NOTE:
  //   *   The x coordinates of the glTexCoord2f function need to inverted
  //   * for SDL because of the way SDL_LoadBmp loads the data. So where
  //   * in the tutorial it has glTexCoord2f( 1.0, 0.0 ); it should
  //   * now read glTexCoord2f( 0.0, 0.0 );
    glBegin( GL_QUADS );
      // Front Face 
      // Bottom Left Of The Texture and Quad 
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f( -1.0, -1.0, 1.0 );
      // Bottom Right Of The Texture and Quad
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f(  1.0, -1.0, 1.0 );
      // Top Right Of The Texture and Quad
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f(  1.0,  1.0, 1.0 );
      // Top Left Of The Texture and Quad
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f( -1.0,  1.0, 1.0 );

      // Back Face
      // Bottom Right Of The Texture and Quad
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f( -1.0, -1.0, -1.0 );
      // Top Right Of The Texture and Quad
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f( -1.0,  1.0, -1.0 );
      // Top Left Of The Texture and Quad
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f(  1.0,  1.0, -1.0 );
      // Bottom Left Of The Texture and Quad
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f(  1.0, -1.0, -1.0 );

      // Top Face
      // Top Left Of The Texture and Quad
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f( -1.0,  1.0, -1.0 );
      // Bottom Left Of The Texture and Quad
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f( -1.0,  1.0,  1.0 );
      // Bottom Right Of The Texture and Quad
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f(  1.0,  1.0,  1.0 );
      // Top Right Of The Texture and Quad
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f(  1.0,  1.0, -1.0 );

      // Bottom Face
      // Top Right Of The Texture and Quad
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f( -1.0, -1.0, -1.0 );
      // Top Left Of The Texture and Quad
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f(  1.0, -1.0, -1.0 );
      // Bottom Left Of The Texture and Quad
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f(  1.0, -1.0,  1.0 );
      // Bottom Right Of The Texture and Quad
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f( -1.0, -1.0,  1.0 );

      // Right face
      // Bottom Right Of The Texture and Quad
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f( 1.0, -1.0, -1.0 );
      // Top Right Of The Texture and Quad
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f( 1.0,  1.0, -1.0 );
      // Top Left Of The Texture and Quad
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f( 1.0,  1.0,  1.0 );
      // Bottom Left Of The Texture and Quad
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f( 1.0, -1.0,  1.0 );

      // Left Face
      // Bottom Left Of The Texture and Quad
      glTexCoord2f( 1.0, 0.0 );
      glVertex3f( -1.0, -1.0, -1.0 );
      // Bottom Right Of The Texture and Quad
      glTexCoord2f( 0.0, 0.0 );
      glVertex3f( -1.0, -1.0,  1.0 );
      // Top Right Of The Texture and Quad
      glTexCoord2f( 0.0, 1.0 );
      glVertex3f( -1.0,  1.0,  1.0 );
      // Top Left Of The Texture and Quad
      glTexCoord2f( 1.0, 1.0 );
      glVertex3f( -1.0,  1.0, -1.0 );
    glEnd;

  // swap buffers to display, since we're double buffered.
  SDL_GL_SwapBuffers;

  xrot := xrot + 0.3; // X Axis Rotation
  yrot := yrot + 0.2; // Y Axis Rotation
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
  SDL_WM_SetCaption( 'Jeff Molofee''s OpenGL Code Tutorial 7 using JEDI-SDL', nil
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

