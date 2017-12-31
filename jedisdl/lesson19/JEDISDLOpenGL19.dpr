program JEDISDLOpenGL19; //DL
{
  All Major changes I have made are marked with //DL
}


uses
  SysUtils,
  SDL,
  OpenGL12,
  Logger;

const
// screen width, height, and bit depth
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;
  SCREEN_BPP = 16;

  MAX_PARTICLES = 1000;

  // Rainbow Of Colors
  colors: array[0..11, 0..2] of TGLFloat = (
    (1.0, 0.5, 0.5), (1.0, 0.75, 0.5), (1.0, 1.0, 0.5), (0.75, 1.0, 0.5),
    (0.5, 1.0, 0.5), (0.5, 1.0, 0.75), (0.5, 1.0, 1.0), (0.5, 0.75, 1.0),
    (0.5, 0.5, 1.0), (0.75, 0.5, 1.0), (1.0, 0.5, 1.0), (1.0, 0.5, 0.75));

type
  TParticle = record // Create A Structure For Particle
    active: Boolean; // Active (Yes/No)
    life: Single; // Particle Life
    fade: Single; // Fade Speed
    r: Single; // Red Value
    g: Single; // Green Value
    b: Single; // Blue Value
    x: Single; // X Position
    y: Single; // Y Position
    z: Single; // Z Position
    xi: Single; // X Direction
    yi: Single; // Y Direction
    zi: Single; // Z Direction
    xg: Single; // X Gravity
    yg: Single; // Y Gravity
    zg: Single; // Z Gravity
  end; // Particles Structure

var
  Screen: PSDL_Surface = nil;
  rainbow: Boolean = TRUE; // Toggle rainbow effect
  slowdown: single = 2.0; // Slow Down Particles  //DL
  xspeed: single; // Base X Speed (To Allow Keyboard Direction Of Tail)
  yspeed: single; // Base Y Speed (To Allow Keyboard Direction Of Tail)
  zoom: single = -40.0; // Used To Zoom Out    //DL

  // particles array
  particles : array[0..MAX_PARTICLES - 1] of TParticle;

  col: TGLUInt; // Current Color Selection
  delay: TGLUInt; // Rainbow Effect Delay
  texture: TGLUInt; // Storage For Our Particle Texture

  T0, Frames: TGLInt;

procedure TerminateApplication;
begin
  SDL_QUIT;
  UnLoadOpenGL;
  Halt(0);
end;

procedure Finalize;
begin
  // Clean up our textures
  glDeleteTextures(1, @texture);

  SDL_FreeSurface(Screen);
  TerminateApplication
end;

//------------------------------------------------------------------------------
// LoadGLTextures : Load Bitmaps And Convert To Textures
//------------------------------------------------------------------------------

function LoadGLTextures: boolean;
var
  Status: boolean;
  TextureImage: PSDL_Surface; // Create Storage Space For The Textures
begin
  Status := FALSE;

  TextureImage := SDL_LoadBMP('Data/Particle.bmp');

  if (TextureImage <> nil) then
  begin
    Status := TRUE;
    // Create Texture
    glGenTextures( 1, @texture );
    // Typical Texture Generation Using Data From The Bitmap
    glBindTexture( GL_TEXTURE_2D, texture );

    // Linear Filtering
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    // Generate The Texture
    glTexImage2D(GL_TEXTURE_2D, 0, 3, TextureImage.w, TextureImage.h,
      0, GL_BGR, GL_UNSIGNED_BYTE, TextureImage.pixels);
  end;
  if TextureImage <> nil then
    SDL_FreeSurface(TextureImage);

  Result := Status; // Return The Status
end;

(* function to reset one particle to initial state
 * NOTE: I added this function to replace doing the same thing in several
 * places and to also make it easy to move the pressing of numpad keys
 * 2, 4, 6, and 8 into handleKeyPress function.
 *)

procedure ResetParticle(num, color: integer; xDir, yDir, zDir: single);
begin
    // Make the particels active */
  particles[num].active := TRUE;
    // Give the particles life */
  particles[num].life := 1.0;
    // Random Fade Speed *)
  particles[num].fade := (random(10) mod 100) / 1000.0 + 0.003;  //DL
    // Select Red Rainbow Color *)
  particles[num].r := colors[color][0];
    // Select Green Rainbow Color *)
  particles[num].g := colors[color][1];
    // Select Blue Rainbow Color *)
  particles[num].b := colors[color][2];
    // Set the position on the X axis *)
  particles[num].x := 0.0;
    // Set the position on the Y axis *)
  particles[num].y := 0.0;
    // Set the position on the Z axis *)
  particles[num].z := 0.0;
    // Random Speed On X Axis *)
  particles[num].xi := xDir;
    // Random Speed On Y Axi *)
  particles[num].yi := yDir;
    // Random Speed On Z Axis *)
  particles[num].zi := zDir;
    // Set Horizontal Pull To Zero *)
  particles[num].xg := 0.0;
    // Set Vertical Pull Downward *)
  particles[num].yg := -0.8;
    // Set Pull On Z Axis To Zero *)
  particles[num].zg := 0.0;
end;

// function to handle key press events *)

procedure HandleKeyPress(keysym: PSDL_keysym); //DL
var
  loop: word;
  color: Integer;
  xi, yi, zi: single;
begin
  case keysym.sym of
    SDLK_ESCAPE:
     (* ESC key was pressed *)
      Finalize;
    SDLK_F1:
     (* F1 key was pressed
      * this toggles fullscreen mode
      *)
      SDL_WM_ToggleFullScreen(Screen);
    SDLK_KP_PLUS:
     (* '+' key was pressed
      * this speeds up the particles
      *)
      if (slowdown > 1.0) then
        slowdown := slowdown - 0.01;
    SDLK_KP_MINUS:
     (* '-' key was pressed
      * this slows down the particles
      *)
      if (slowdown < 4.0) then        //DL
        slowdown := slowdown + 0.01;
    SDLK_PAGEUP:
     (* PageUp key was pressed
      * this zooms into the scene
      *)
      zoom := zoom + 0.01;
    SDLK_PAGEDOWN:
     (* PageDown key was pressed
      * this zooms out of the scene
      *)
      zoom := zoom - 0.01;
    SDLK_UP:
     (* Up arrow key was pressed
      * this increases the particles' y movement
      *)
      if (yspeed < 200) then
        yspeed := yspeed + 1;
    SDLK_DOWN:
     (* Down arrow key was pressed
      * this decreases the particles' y movement
      *)
      if (yspeed > -200) then
        yspeed := yspeed - 1;
    SDLK_RIGHT:
     (* Right arrow key was pressed
      * this increases the particles' x movement
      *)
      if (xspeed < 200) then
        xspeed := xspeed + 1;
    SDLK_LEFT:
     (* Left arrow key was pressed
      * this decreases the particles' x movement
      *)
      if (xspeed > -200) then
        xspeed := xspeed - 1;
    SDLK_KP8:
     (* NumPad 8 key was pressed
      * increase particles' y gravity
      *)
      for loop := 0 to MAX_PARTICLES - 1 do
      begin
        if (particles[loop].yg < 1.5) then
        begin
          particles[loop].yg := particles[loop].yg + 0.01;
        end;
      end;
    SDLK_KP2:
     (* NumPad 2 key was pressed
      * decrease particles' y gravity
      *)
      for loop := 0 to MAX_PARTICLES - 1 do
      begin
        if (particles[loop].yg > -1.5) then
        begin
          particles[loop].yg := particles[loop].yg - 0.01;
        end;
      end;
    SDLK_KP6:
     (* NumPad 6 key was pressed
      * this increases the particles' x gravity
      *)
      for loop := 0 to MAX_PARTICLES - 1 do
      begin
        if (particles[loop].xg < 1.5) then
        begin
          particles[loop].xg := particles[loop].xg + 0.01;
        end;
      end;
    SDLK_KP4:
     (* NumPad 4 key was pressed
      * this decreases the particles' y gravity
      *)
      for loop := 0 to MAX_PARTICLES - 1 do
      begin
        if (particles[loop].xg > -1.5) then
        begin
          particles[loop].xg := particles[loop].xg - 0.01;
        end;
      end;
    SDLK_TAB:
     (* Tab key was pressed
      * this resets the particles and makes them re-explode
      *)
      for loop := 0 to MAX_PARTICLES - 1 do
      begin
        color := Round((loop + 1) / (MAX_PARTICLES / 12));
        xi := ((random(5) mod 50) - 26) * 10.0;  //DL
        yi := ((random(5) mod 50) - 25) * 10.0;  //DL
        zi := yi;
        ResetParticle(loop, color, xi, yi, zi);
      end;
    SDLK_RETURN:
      begin
      (* Return key was pressed
       * this toggles the rainbow color effect
       *)
        rainbow := not rainbow;
        delay := 25;
      end;
    SDLK_SPACE:
      begin
            (* Spacebar was pressed
      * this turns off rainbow-ing and manually cycles through colors
      *)
        rainbow := FALSE;
        delay := 0;
        col := ( col + 1 ) mod 12; //DL
        //col := col + 1;
        //if (col > 11) then col := 0;
      end;
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
  gluPerspective( 45.0, width / height, 0.1, 200.0 );

  // Make sure we're changing the model view and not the projection 
  glMatrixMode( GL_MODELVIEW );

  // Reset The View 
  glLoadIdentity;

  result := true;
end;

// general OpenGL initialization function */
function initGL: boolean;
var
  loop: word;
  color: Integer;
  xi, yi, zi: single;
begin
    // Load in the texture */
  if not LoadGLTextures then
  begin
    Result := FALSE;
    Exit;
  end;

  // Enable smooth shading */
  glShadeModel(GL_SMOOTH);

    // Set the background black */
  glClearColor(0.0, 0.0, 0.0, 0.5);

    // Depth buffer setup */
  glClearDepth(1.0);

    // Enables Depth Testing */
  glDisable(GL_DEPTH_TEST);

    // Enable Blending */
  glEnable(GL_BLEND);
    // Type Of Blending To Perform */
  glBlendFunc(GL_SRC_ALPHA, GL_ONE);

    // singlely Nice Perspective Calculations */
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
    // singlely Nice Point Smoothing */
  glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);

    // Enable Texture Mapping */
  glEnable(GL_TEXTURE_2D);
    // Select Our Texture */
  glBindTexture(GL_TEXTURE_2D, texture);

  // Reset all the particles */
  for loop := 0 to MAX_PARTICLES - 1 do
  begin
    color := Round((loop + 1) / (MAX_PARTICLES / 12));
    xi := ((random(5) mod 50 ) - 26.0 ) * 10.0; //DL
    yi := ((random(5) mod 50 ) - 25.0 ) * 10.0; //DL
    zi := yi;
    ResetParticle(loop, color, xi, yi, zi);
  end;

  Result := True;
end;

// Here goes our drawing code
function DrawGLScene: boolean;
var
  loop: word;
  x, y, z: single;
  xi, yi, zi: single;
  time1: TGLInt;
  seconds, fps: TGLFloat;
begin
  // Clear The Screen And The Depth Buffer */
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT); //DL

  glLoadIdentity;

    // Modify each of the particles */
  for loop := 0 to MAX_PARTICLES - 1 do
  begin
    if particles[loop].active then
    begin
      // Grab Our Particle X Position */
      x := particles[loop].x;
      // Grab Our Particle Y Position */
      y := particles[loop].y;
      // Particle Z Position + Zoom */
      z := particles[loop].z + zoom;

     { Draw The Particle Using Our RGB Values,
       * Fade The Particle Based On It's Life
                    }
      glColor4f(particles[loop].r,
        particles[loop].g,
        particles[loop].b,
        particles[loop].life);

      // Build Quad From A Triangle Strip */
      glBegin(GL_TRIANGLE_STRIP);
        // Top Right */
        glTexCoord2d(1, 1);
        glVertex3f(x + 0.5, y + 0.5, z);
        // Top Left */
        glTexCoord2d(0, 1);
        glVertex3f(x - 0.5, y + 0.5, z);
        // Bottom Right */
        glTexCoord2d(1, 0);
        glVertex3f(x + 0.5, y - 0.5, z);
        // Bottom Left */
        glTexCoord2d(0, 0);
        glVertex3f(x - 0.5, y - 0.5, z);
      glEnd;

      // Move On The X Axis By X Speed */
      particles[loop].x := particles[loop].x + particles[loop].xi /
        (slowdown * 1000);
      // Move On The Y Axis By Y Speed */
      particles[loop].y := particles[loop].y + particles[loop].yi /
        (slowdown * 1000);
      // Move On The Z Axis By Z Speed */
      particles[loop].z := particles[loop].z + particles[loop].zi /
        (slowdown * 1000);

      // Take Pull On X Axis Into Account */
      particles[loop].xi := particles[loop].xi + particles[loop].xg;
      // Take Pull On Y Axis Into Account */
      particles[loop].yi := particles[loop].yi + particles[loop].yg;
      // Take Pull On Z Axis Into Account */
      particles[loop].zi := particles[loop].zi + particles[loop].zg;

      // Reduce Particles Life By 'Fade' */
      particles[loop].life := particles[loop].life - particles[loop].fade; //DL

      // If the particle dies, revive it */
      if (particles[loop].life < 0.0) then
      begin
        xi := xspeed +
          random(60) mod 60  - 32.0; //DL
        yi := yspeed +
          random(60) mod 60 - 30.0;  //DL
        zi := random(60) mod 60 - 30.0; //DL
        ResetParticle(loop, col, xi, yi, zi);
      end;
    end;
  end;

    // Draw it to the screen */
  SDL_GL_SwapBuffers();

  // Gather our frames per second */
  Inc(Frames);
  time1 := SDL_GetTicks;
  if (time1 - T0 >= 5000) then
  begin
    seconds := (time1 - T0) / 1000.0;
    fps := Frames / seconds;
    SDL_WM_SetCaption( PChar(Format('%d frames in %g seconds = %g FPS.', [Frames, seconds, fps] )), nil ); // DL
    T0 := time1;
    Frames := 0;
  end;

  Result := TRUE;
end;


var
 // Flags to pass to SDL_SetVideoMode */
  videoFlags: cardinal;
  // main loop variable */
  Done: Boolean = FALSE;
  // used to collect events */
  event: TSDL_Event;
  // this holds some info about our display */
  videoInfo: PSDL_VideoInfo;
  // whether or not the window is active */
  isActive: Boolean = True;
begin
   // Load the appropriate .DLL or .SO
  LoadOpenGL;

  // initialize SDL */
  if (SDL_Init(SDL_INIT_VIDEO) < 0) then
  begin
    Log.LogWarning(Format('Video initialization failed: %s\n',
      [SDL_GetError]), 'Start');
    Halt(1);
  end;

  // Fetch the video info */
  videoInfo := SDL_GetVideoInfo();

  if videoInfo = nil then
  begin
    Log.LogWarning(Format('Video query failed: %s\n',
      [SDL_GetError]), 'Start');
    Halt(1);
  end;

  // the flags to pass to SDL_SetVideoMode                            */
  // Enable OpenGL in SDL          */
  videoFlags := SDL_OPENGL;
  // Enable double buffering       */
  videoFlags := videoFlags or SDL_DOUBLEBUF;  //DL
  // Store the palette in hardware */
  videoFlags := videoFlags or SDL_HWPALETTE;  //DL
  // Enable window resizing        */
  videoFlags := videoFlags or SDL_RESIZABLE;  //DL

  // This checks to see if surfaces can be stored in memory 
  if ( videoInfo.hw_available <> 0 ) then     //DL
    videoFlags := videoFlags or SDL_HWSURFACE
  else
    videoFlags := videoFlags or SDL_SWSURFACE;

  // This checks if hardware blits can be done * /
  if ( videoInfo.blit_hw <> 0 ) then           //DL
    videoFlags := videoFlags or SDL_HWACCEL;

  // Sets up OpenGL double buffering */
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

  // Set the title bar in environments that support it 
  SDL_WM_SetCaption( 'Jeff Molofee''s OpenGL Code Tutorial 19 using JEDI-SDL', nil ); //DL

  // get a SDL surface */
  Screen := SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP,
    videoFlags);

    // Verify there is a surface */
  if Screen = nil then
  begin
    Log.LogWarning(Format('Video mode set failed: %s',
      [SDL_GetError]), 'Main');
    Finalize;
  end;

    // Enable key repeat */
  if SDL_EnableKeyRepeat(100, SDL_DEFAULT_REPEAT_INTERVAL) = -1 then
  begin
    Log.LogWarning(Format('Setting keyboard repeat failed: %s',
      [SDL_GetError]), 'Main');
    Finalize;
  end;

    // initialize OpenGL */
  if not initGL then
  begin
    Log.LogWarning(Format('Could not initialize OpenGL. %s',
      [SDL_GetError]), 'Main');
    Finalize;
  end;

  ReSizeWindow( SCREEN_WIDTH, SCREEN_HEIGHT );

  // wait for events */
  while (not done) do
  begin
     // handle the events in the queue */

    while (SDL_PollEvent(@event) > 0) do
    begin
//  switch( event.type )
      case Event.key.type_ of
        SDL_QUITEV:
       // handle quit requests */
          done := TRUE;

        (*SDL_ACTIVEEVENT:
        begin
                          { Something's happend with our focus
      * If we lost focus or we are iconified, we
      * shouldn't draw the screen
      *}
          if (event.active.gain = 0) then
            isActive := FALSE
          else
            isActive := TRUE;
        end;*)
        
        SDL_VIDEORESIZE:
        begin
          // handle resize event */
          Screen := SDL_SetVideoMode(event.resize.w,
            event.resize.h,
            SCREEN_BPP, videoFlags);
          if Screen = nil then
          begin
            Log.LogWarning(Format('Could not get a surface after resize: %s',
              [SDL_GetError]), 'Start');
            Finalize;
          end;
          ResizeWindow( event.resize.w, event.resize.h );
        end;
        
        SDL_KEYDOWN:
       // handle key presses */
          HandleKeyPress(@event.key.keysym); //DL
      end;
    end;
     // If rainbow coloring is turned on, cycle the colors */
    if (rainbow and (delay > 25)) then
    begin
//		col:= ( ++col ) % 12;
      col := (col + 1) mod 12; //DL
      if (col > 11) then col := 0;
    end;

     // draw the scene */
    if (isActive) then
      DrawGLScene();

    Inc(delay);
  end;
end.

