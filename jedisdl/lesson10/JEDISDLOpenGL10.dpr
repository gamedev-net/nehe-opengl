program JEDISDLOpenGL10;
{******************************************************************}
{                                                                  }
{       Borland Delphi SDL with OpenGL Example                     }
{       Conversion of the SDL OpenGL Examples                      }
{                                                                  }
{ Portions created by Ti Leggett <leggett@eecs.tulane.edu>,  are   }
{ Copyright (C) 2001 Ti Leggett.                                   }
{ All Rights Reserved.                                             }
{                                                                  }
{ The original files are : lesson10.c                              }
{                                                                  }
{ The original Pascal code is : JEDISDLOpenGL10.dpr                }
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
  Classes,
  Logger,
  SDL;

const
  piover180: single = 0.0174532925;

  // screen width, height, and bit depth
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;
  SCREEN_BPP = 16;

type
  PVertex = ^TVertex;
  TVertex = record // vertex coordinates - 3d and texture
    x, y, z: TGLfloat; // 3d coords.
    u, v: TGLfloat; // texture coords.
  end;

  PTriangle = ^TTriangle;
  TTriangle = record // triangle
    vertex: array[0..2] of TVertex; // 3 vertices array
  end;

  PSector = ^TSector;
  TSector = record // sector of a 3d environment
    numtriangles: integer; // number of triangles in the sector
    triangle: array of TTriangle; // pointer to array of triangles.
  end;

var
  // This is our SDL surface
  surface : PSDL_Surface;

  yrot: TGlFloat; // Y Rotation
  xpos, zpos: TGlFloat;

  walkbias: TGLfloat = 0;
  walkbiasangle: TGLfloat = 0;
  lookupdown: TGLfloat = 0.0;

  sector1: TSECTOR;

  // white ambient light at half intensity (rgba)
  LightAmbient: array[0..3] of TGLfloat = (0.5, 0.5, 0.5, 1.0);
  // super bright, full intensity diffuse light.
  LightDiffuse: array[0..3] of TGLfloat = (1.0, 1.0, 1.0, 1.0);
  // position of light (x, y, z, (position of light))
  LightPosition: array[0..3] of TGLfloat = (0.0, 0.0, 2.0, 1.0);
  
  filter: TGLuint = 0; // Which Filter To Use (nearest/linear/mipmapped)
  texture: array[0..2] of TGLuint; // Storage For 3 Texture

  //Status indicator
  Status : Boolean = false;

procedure TerminateApplication;
begin
  SDL_QUIT;
  UnLoadOpenGL;

  // Deallocate things we allocated
  {if ( sector1.triangle <> nil ) then
	FreeMem( sector1.triangle );}
  SetLength(sector1.triangle, 0);

  Halt(0);
end;

// Load Bitmaps And Convert To Textures
function LoadGLTextures : Boolean;
var
  // Create storage space for the texture
  TextureImage: PSDL_Surface;
begin
  // Load The Bitmap, Check For Errors, If Bitmap's Not Found Quit
  TextureImage := SDL_LoadBMP('Data/mud.bmp');
  if ( TextureImage <> nil ) then
  begin
    // Set the status to true
    Status := true;
    
    // Create Texture
    glGenTextures( 3, @texture[0] );

    // Load in texture 1
    // Typical Texture Generation Using Data From The Bitmap
    glBindTexture( GL_TEXTURE_2D, texture[0] );

    // Nearest Filtering
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                     GL_NEAREST );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
                     GL_NEAREST );
                     
    // Generate The Texture
    glTexImage2D( GL_TEXTURE_2D, 0, 3, TextureImage.w,
                  TextureImage.h, 0, GL_BGR,
                  GL_UNSIGNED_BYTE, TextureImage.pixels );

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
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
                     GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                     GL_LINEAR_MIPMAP_NEAREST );

    // Generate The MipMapped Texture ( NEW )
    gluBuild2DMipmaps( GL_TEXTURE_2D, 3, TextureImage.w,
                       TextureImage.h, GL_BGR,
                       GL_UNSIGNED_BYTE, TextureImage.pixels );
  end
  else
  begin
    Log.LogWarning( Format( 'Could not Load Image : %s', [SDL_GetError] ),
      'LoadGLTextures' );
  end;

  // Free up any memory we may have used
  if ( TextureImage <> nil ) then
    SDL_FreeSurface( TextureImage );

  result := Status;
end;

// loads the world from a text file.
procedure SetupWorld( MapFile : string );
var
  oneline: string;
  //x, y, z, u, v: TGLfloat;
  triloop : integer; // Triangle loop variable
  verloop : integer; // Vertex loop variable
  numtriangles: integer;
  Map : TStringList;
  strLoop, endPos : integer;
begin
  Map := TStringList.Create;
  try
    Map.LoadFromFile( MapFile );
    strLoop := 0;
    numtriangles := StrtoInt( Copy(Map.Strings[strLoop], Length('NUMPOLLIES ') + 1 , 2 ) );
    inc(strLoop);
    
    SetLength(sector1.triangle, numtriangles);

    if ( sector1.triangle = nil ) then
    begin
      Log.LogError( 'Could not allocate memory for triangles', 'SetupWorld' );
      TerminateApplication;
    end;
    try
      sector1.numtriangles := numtriangles;
      for triloop := 0 to numtriangles - 1 do
      begin
        for verloop := 0 to 2 do
        begin
          while ( Pos('//', Map.Strings[strLoop]) > 0 ) or ( Length( Map.Strings[strLoop] ) = 0) do
            Inc( strLoop );
          oneline := Map.Strings[strLoop];
          endPos := Pos( ' ', oneline );
          sector1.triangle[triloop].vertex[verloop].x := StrToFloat( Copy( oneline, 0, endPos - 1 ) );

          oneline := Copy(oneline, endPos + 1, Length(oneline) );
          endPos := Pos( ' ', oneline );
          sector1.triangle[triloop].vertex[verloop].y := StrToFloat( Copy( oneline, 0, endPos ) );

          oneline := Copy(oneline, endPos + 1, Length(oneline) );
          endPos := Pos( ' ', oneline );
          sector1.triangle[triloop].vertex[verloop].z := StrToFloat( Copy( oneline, 0, endPos ) );

          oneline := Copy(oneline, endPos + 1, Length(oneline) );
          endPos := Pos( ' ', oneline );
          sector1.triangle[triloop].vertex[verloop].u := StrToFloat( Copy( oneline, 0, endPos ) );

          oneline := Copy(oneline, endPos + 1, Length(oneline) );
          sector1.triangle[triloop].vertex[verloop].v := StrToFloat( oneline );
          Inc( strLoop );
        end;
      end;
    except
      on E: Exception do
      begin
       Log.LogError( E.Message, 'SetupWorld' );
      TerminateApplication;
      end;
    end;
  finally
    Map.Free;
  end;
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

  // Setup The Ambient Light 
  glLightfv( GL_LIGHT1, GL_AMBIENT, @LightAmbient );

  // Setup The Diffuse Light
  glLightfv( GL_LIGHT1, GL_DIFFUSE, @LightDiffuse );

  // Position The Light
  glLightfv( GL_LIGHT1, GL_POSITION, @LightPosition );

  // Enable Light One 
  glEnable( GL_LIGHT1 );

  lookupdown    := 0.0;
  walkbias      := 0.0;
  walkbiasangle := 0.0;

  // Full Brightness, 50% Alpha 
  glColor4f( 1.0, 1.0, 1.0, 0.5);

  // Blending Function For Translucency Based On Source Alpha Value 
  glBlendFunc( GL_SRC_ALPHA, GL_ONE );

  result := true;
end;

// The main drawing function.
procedure DrawGLScene;
var
  // Floating Point For Temp X, Y, Z, U And V Vertices
  x_m, y_m, z_m, u_m, v_m: TGLfloat;
  // Used For Player Translation On The X Axis
  xtrans: TGLfloat;
  // Used For Bouncing Motion Up And Down
  ytrans: TGLfloat;
  // Used For Player Translation On The Z Axis
  ztrans: TGLfloat;
  // 360 Degree Angle For Player Direction
  sceneroty: TGLfloat;
  numtriangles: integer;
  // Loop variable
  loop_m : integer;
begin
  // calculate translations and rotations.
  xtrans := -xpos;
  ztrans := -zpos;
  ytrans := -walkbias - 0.25;
  sceneroty := 360.0 - yrot;

  // Clear The Screen And The Depth Buffer
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity; // Reset The View

  // Rotate Up And Down To Look Up And Down
  glRotatef(lookupdown, 1.0, 0, 0);

  // Rotate Depending On Direction Player Is Facing
  glRotatef(sceneroty, 0, 1.0, 0);
  
  // Translate The Scene Based On Player Position
  glTranslatef(xtrans, ytrans, ztrans);

  // Select A Texture Based On filter
  glBindTexture(GL_TEXTURE_2D, texture[filter]);
  
  numtriangles := sector1.numtriangles;
  // Process Each Triangle
  for loop_m := 0 to numtriangles - 1 do
  begin
    glBegin(GL_TRIANGLES);
      // Normal Pointing Forward
      glNormal3f(0.0, 0.0, 1.0);
      // X Vertex Of 1st Point
      x_m := sector1.triangle[loop_m].vertex[0].x;
      // Y Vertex Of 1st Point
      y_m := sector1.triangle[loop_m].vertex[0].y;
      // Z Vertex Of 1st Point
      z_m := sector1.triangle[loop_m].vertex[0].z;
      // U Texture Coord Of 1st Point
      u_m := sector1.triangle[loop_m].vertex[0].u;
      // V Texture Coord Of 1st Poin
      v_m := sector1.triangle[loop_m].vertex[0].v;

      // Set The TexCoord And Vertice
      glTexCoord2f(u_m, v_m);
      glVertex3f(x_m, y_m, z_m);

      
      // X Vertex Of 2nd Point
      x_m := sector1.triangle[loop_m].vertex[1].x;
      // Y Vertex Of 2nd Point
      y_m := sector1.triangle[loop_m].vertex[1].y;
      // Z Vertex Of 2nd Point
      z_m := sector1.triangle[loop_m].vertex[1].z;
      // U Texture Coord Of 2nd Point
      u_m := sector1.triangle[loop_m].vertex[1].u;
      // V Texture Coord Of 2nd Point
      v_m := sector1.triangle[loop_m].vertex[1].v;

      // Set The TexCoord And Vertice
      glTexCoord2f(u_m, v_m);
      glVertex3f(x_m, y_m, z_m);

      // X Vertex Of 3rd Point
      x_m := sector1.triangle[loop_m].vertex[2].x;
      // Y Vertex Of 3rd Point
      y_m := sector1.triangle[loop_m].vertex[2].y;
      // Z Vertex Of 3rd Point
      z_m := sector1.triangle[loop_m].vertex[2].z;
      // U Texture Coord Of 3rd Point
      u_m := sector1.triangle[loop_m].vertex[2].u;
      // V Texture Coord Of 3rd Point
      v_m := sector1.triangle[loop_m].vertex[2].v;

      // Set The TexCoord And Vertice
      glTexCoord2f(u_m, v_m);
      glVertex3f(x_m, y_m, z_m);
    glEnd;
  end;

  // swap buffers to display, since we're double buffered.
  SDL_GL_SwapBuffers;
end;

var
  Done : Boolean;
  event : TSDL_Event;
  videoflags : Uint32;
  videoInfo : PSDL_VideoInfo;
  keystate: PKeyStateArr;
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
  SDL_WM_SetCaption( 'Jeff Molofee''s OpenGL Code Tutorial 10 using JEDI-SDL', nil
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

  // Enable key repeat
  if ( ( SDL_EnableKeyRepeat( 100, SDL_DEFAULT_REPEAT_INTERVAL ) ) <> 0 ) then
  begin
    Log.LogError( Format( 'Setting keyboard repeat failed: %s', [SDL_GetError]
      ),
      'Main' );
    TerminateApplication;
  end;


  // initialize OpenGL
  InitGL;

  // Read in the data
  SetupWorld( 'Data/world.map' );

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

    //Handle real-time key events
    keystate := PKeyStateArr(SDL_GetKeyState(nil));
    if (keystate[SDLK_UP] <> 0) then
    begin
      {* Up arrow key was pressed
       * this moves the player forward
       *}
      // Move On The X-Plane Based On Player Direction
      xpos := xpos - sin( yrot * piover180 ) * 0.05;

      // Move On The Z-Plane Based On Player Direction
      zpos := zpos - cos( yrot * piover180 ) * 0.05;
      if ( walkbiasangle >= 359.0 ) then
          walkbiasangle := 0.0
      else
          walkbiasangle := walkbiasangle + 10;

      // Causes the player to bounce
      walkbias := sin( walkbiasangle * piover180 ) / 20.0;
    end;

    if (keystate[SDLK_DOWN] <> 0) then
    begin
      {* Down arrow key was pressed
       * this causes the player to move backwards
       *}
      // Move On The X-Plane Based On Player Direction
      xpos := xpos + sin( yrot * piover180 ) * 0.05;

      // Move On The Z-Plane Based On Player Direction
      zpos := zpos + cos( yrot * piover180 ) * 0.05;
      if ( walkbiasangle <= 1.0 ) then
          walkbiasangle := 359.0
      else
          walkbiasangle := walkbiasangle - 10;

      walkbias := sin( walkbiasangle * piover180 ) / 20.0;
    end;

    if (keystate[SDLK_LEFT] <> 0) then
    begin
      {* Left arrow key was pressed
       * this effectively turns the camera left, but does it by
       * rotating the scene right
       *}
      yrot := yrot + 1.5;
    end;

    if (keystate[SDLK_RIGHT] <> 0) then
    begin
      {* Right arrow key was pressed
       * this effectively turns the camera right, but does it by
       * rotating the scene left
       *}
      yrot := yrot - 1.5;
    end;

    // draw the scene
    DrawGLScene;
  end;
  TerminateApplication;
end.

