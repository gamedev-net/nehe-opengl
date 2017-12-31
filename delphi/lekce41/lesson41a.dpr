program lesson41a;

{   kód pro Delphi 7}

//******************************************************************************
// Pùvodní verze funkce BuildTexture nechtìla fungovat, tak jsem použil starou
// dobrou knihovnu glaux pro nahrávání bitmapy. Kdyby nìkdo rozchodil ekvivalent
// funkce z C++, dejte mi vìdìt...
//******************************************************************************

uses
  Windows,
  glaux,
  Messages,
  OpenGL,
  NeHeGL in 'NeHeGL.pas';

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;
procedure glDeleteTextures(n: GLsizei; textures: PGLuint); stdcall; external 'opengl32';

type
  PFNGLFOGCOORDFEXTPROC = procedure(coord: GLfloat); stdcall;   // Funkèní prototyp

const
  GL_FOG_COORDINATE_SOURCE_EXT = $8450;                         // Symbolické konstanty potøebné pro rozšíøení FogCoordfEXT
  GL_FOG_COORDINATE_EXT = $8451; 

var
  g_window: PGL_Window;                                         // Okno
  g_keys: PKeys;                                                // Klávesy
  fogColor: array [0..3] of GLfloat = (0.6,0.3,0.0,1.0);        // Barva mlhy
  camz: GLfloat;                                                // Pozice kamery na ose z
  glFogCoordfEXT: PFNGLFOGCOORDFEXTPROC = nil;                  // Ukazatel na funkci glFogCoordfEXT
  texture: GLuint;                                              // Jedna textura


function BuildTexture(szPathName: PChar; var texid: GLuint): boolean;           // Nahraje obrázek a konvertuje ho na texturu
var
  TextureImage: PTAUX_RGBImageRec;
begin
  TextureImage := auxDIBImageLoadA(szPathName);
  if not Assigned(TextureImage) then
    begin
    Result := false;
    exit;
    end;
  glGenTextures(1,texid);                                                       // Generování jedné textury
  glBindTexture(GL_TEXTURE_2D,texid);                                           // Zvolí texturu
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);               // Lineární filtrování
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D,0,3,TextureImage.sizeX,TextureImage.sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage.data);  // Vytvoøení textury
  Result := true;                                                               // OK
end;

function Extension_Init: boolean;                                               // Je rozšíøení EXT_fog_coord podporováno?
var
  Extension_Name: string;
  glextstring: string;
begin
  Extension_Name := 'EXT_fog_coord';
  glextstring := glGetString(GL_EXTENSIONS);                                    // Grabování seznamu podporovaných rozšíøení
  if Pos(Extension_Name,glextstring) = 0 then                                   // Není podporováno?
    begin
    Result := false;
    exit;
    end;
  glFogCoordfEXT := wglGetProcAddress('glFogCoordfEXT');                        // Nastaví ukazatel na funkci
  Result := true;                                                               // OK
end;

function Initialize(window: PGL_Window; key: PKeys): boolean;	                  // Inicializace OpenGL
begin
  g_window := window;                                                           // Okno
  g_keys := key;                                                                // Klávesnice
  if not Extension_Init then                                                    // Je rozšíøení podporováno?
    begin
    Result := false;                                                            // Konec
    exit;
    end;
  if not BuildTexture('data/wall.bmp',texture) then                             // Nahrání textury
    begin
    Result := false;                                                            // Konec
    exit;
    end;
  glEnable(GL_TEXTURE_2D);                                                      // Zapne mapování textur
  glClearColor(0.0,0.0,0.0,0.5);                                                // Èerné pozadí
  glClearDepth(1.0);                                                            // Nastavení hloubkového bufferu
  glDepthFunc(GL_LEQUAL);                                                       // Typ testování hloubky
  glEnable(GL_DEPTH_TEST);                                                      // Zapne testování hloubky
  glShadeModel(GL_SMOOTH);                                                      // Jemné stínování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);                             // Nejlepší perspektivní korekce
  glEnable(GL_FOG);                                                             // Zapne mlhu
  glFogi(GL_FOG_MODE,GL_LINEAR);                                                // Lineární pøechody
  glFogfv(GL_FOG_COLOR,@fogColor);                                              // Barva
  glFogf(GL_FOG_START,0.0);                                                     // Poèátek
  glFogf(GL_FOG_END,1.0);                                                       // Konec
  glHint(GL_FOG_HINT,GL_NICEST);                                                // Výpoèty na jednotlivých pixelech
  glFogi(GL_FOG_COORDINATE_SOURCE_EXT,GL_FOG_COORDINATE_EXT);                   // Mlha v závislosti na souøadnicích vertexù
  camz := -19.0;                                                                // Pozice kamery
  Result := true;                                                               // OK
end;

procedure Deinitialize;                                                         // Deinicializace
begin
  glDeleteTextures(1,@texture);                                                 // Smaže texturu
end;

procedure Update(milliseconds: DWORD);                                // Aktualizace pohybù ve scénì a stisk kláves
begin
  if g_keys.keyDown[VK_ESCAPE] then                                   // Klávesa ESC?
    TerminateApplication(g_window^);                                  // Ukonèení programu
  if g_keys.keyDown[VK_F1] then                                       // Klávesa F1?
    ToggleFullscreen(g_window^);                                      // Pøepnutí fullscreen/okno
  if g_keys.keyDown[VK_UP] and (camz < 14.0) then                     // Šipka nahoru
    begin
    camz := camz + milliseconds / 100.0;                              // Pohyb dopøedu
    end;
  if g_keys.keyDown[VK_DOWN] and (camz > -19.0) then                  // Šipka dolù
    begin
    camz := camz - milliseconds / 100.0;                              // Pohyb dozadu
    end;
end;

procedure Draw;                                                       // Vykreslení scény
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                // Smaže obrazovku a hloubkový buffer
  glLoadIdentity;	                                                    // Reset matice
  glTranslatef(0.0,0.0,camz);                                         // Translace v hloubce
  glBegin(GL_QUADS);                                                  // Zadní stìna
    glFogCoordfEXT(1.0); glTexCoord2f(0.0,0.0);glVertex3f(-2.5,-2.5,-15.0);
    glFogCoordfEXT(1.0); glTexCoord2f(1.0,0.0);glVertex3f( 2.5,-2.5,-15.0);
    glFogCoordfEXT(1.0); glTexCoord2f(1.0,1.0);glVertex3f( 2.5, 2.5,-15.0);
    glFogCoordfEXT(1.0); glTexCoord2f(0.0,1.0);glVertex3f(-2.5, 2.5,-15.0);
  glEnd;
  glBegin(GL_QUADS);                                                  // Podlaha
    glFogCoordfEXT(1.0); glTexCoord2f(0.0,0.0);glVertex3f(-2.5,-2.5,-15.0);
    glFogCoordfEXT(1.0); glTexCoord2f(1.0,0.0);glVertex3f( 2.5,-2.5,-15.0);
    glFogCoordfEXT(0.0); glTexCoord2f(1.0,1.0);glVertex3f( 2.5,-2.5, 15.0);
    glFogCoordfEXT(0.0); glTexCoord2f(0.0,1.0);glVertex3f(-2.5,-2.5, 15.0);
  glEnd;
  glBegin(GL_QUADS);                                                  // Strop
    glFogCoordfEXT(1.0); glTexCoord2f(0.0,0.0);glVertex3f(-2.5,2.5,-15.0);
    glFogCoordfEXT(1.0); glTexCoord2f(1.0,0.0);glVertex3f( 2.5,2.5,-15.0);
    glFogCoordfEXT(0.0); glTexCoord2f(1.0,1.0);glVertex3f( 2.5,2.5, 15.0);
    glFogCoordfEXT(0.0); glTexCoord2f(0.0,1.0);glVertex3f(-2.5,2.5, 15.0);
  glEnd;
  glBegin(GL_QUADS);                                                  // Pravá stìna
    glFogCoordfEXT(0.0); glTexCoord2f(0.0,0.0);glVertex3f(2.5,-2.5, 15.0);
    glFogCoordfEXT(0.0); glTexCoord2f(0.0,1.0);glVertex3f(2.5, 2.5, 15.0);
    glFogCoordfEXT(1.0); glTexCoord2f(1.0,1.0);glVertex3f(2.5, 2.5,-15.0);
    glFogCoordfEXT(1.0); glTexCoord2f(1.0,0.0);glVertex3f(2.5,-2.5,-15.0);
  glEnd;
  glBegin(GL_QUADS);                                                  // Levá stìna
    glFogCoordfEXT(0.0); glTexCoord2f(0.0,0.0);glVertex3f(-2.5,-2.5, 15.0);
    glFogCoordfEXT(0.0); glTexCoord2f(0.0,1.0);glVertex3f(-2.5, 2.5, 15.0);
    glFogCoordfEXT(1.0); glTexCoord2f(1.0,1.0);glVertex3f(-2.5, 2.5,-15.0);
    glFogCoordfEXT(1.0); glTexCoord2f(1.0,0.0);glVertex3f(-2.5,-2.5,-15.0);
  glEnd;
	glFlush;                                                            // Vyprázdní OpenGL renderovací pipeline
end;

function WindowProc(hWnd: HWND;                                       // Handle okna
                 uMsg: UINT;                                          // Zpráva pro okno
                 wParam: WPARAM;                                      // Doplòkové informace
                 lParam: LPARAM):                                     // Doplòkové informace
                                  LRESULT; stdcall;
var
  window: ^GL_Window;
  creation: ^CREATESTRUCT;
  tickCount: DWORD;
begin
  if uMsg = WM_SYSCOMMAND then                                        // Systémový pøíkaz
      case wParam of                                                  // Typ systémového pøíkazu
        SC_SCREENSAVE,SC_MONITORPOWER:                                // Pokus o zapnutí šetøièe obrazovky, Pokus o pøechod do úsporného režimu?
          begin
            Result := 0;                                              // Zabrání obojímu
            exit;
          end;
      end;
  window := Pointer(GetWindowLong(hWnd,GWL_USERDATA));
  case uMsg of                                                        // Vìtvení podle pøíchozí zprávy
    WM_PAINT:
      begin
      tickCount := GetTickCount;
      Update(tickCount - window.lastTickCount);
      window.lastTickCount := tickCount;
      Draw;
      SwapBuffers(window.hDc);
      Result := 0;
      end;
    WM_CREATE:
      begin
      creation := Pointer(lParam);
      window := Pointer(creation.lpCreateParams);
      SetWindowLong(hWnd,GWL_USERDATA,Integer(window));
      Result := 0;
      end;
    WM_CLOSE:                                                         // Povel k ukonèení programu
      begin
      TerminateApplication(window^);                                  // Pošle zprávu o ukonèení
      Result := 0                                                     // Návrat do hlavního cyklu programu
      end;
    WM_SIZE:                                                          // Zmìna velikosti okna
      begin
      case wParam of
        SIZE_MINIMIZED:
          begin
          window.isVisible := false;
          Result := 0;
          end;
        SIZE_MAXIMIZED,
        SIZE_RESTORED:
          begin
          window.isVisible := true;
          ReshapeGL(LOWORD(lParam),HIWORD(lParam));                 // LoWord=Šíøka, HiWord=Výška
          Result := 0;                                              // Návrat do hlavního cyklu programu
          end;
      end;
     // Result := 0;
      end;
    WM_KEYDOWN:                                                     // Stisk klávesy
      begin
      if (wParam >= 0) and (wParam <= 255) then
        begin
        window^.keys^.keyDown[wParam] := true;                      // Oznámí to programu
        Result := 0;
        end;
      //Result := 0;                                                // Návrat do hlavního cyklu programu
      end;
    WM_KEYUP:                                                       // Uvolnìní klávesy
      begin
      if (wParam >= 0) and (wParam <= 255) then
        begin
    	  window^.keys^.keyDown[wParam] := false;                     // Oznámí to programu
        Result := 0;                                                // Návrat do hlavního cyklu programu
        end;
      //exit;
      end;
    WM_TOGGLEFULLSCREEN:
      begin
      g_createFullScreen := not g_createFullScreen;
      PostMessage(hWnd,WM_QUIT,0,0);
      Result := 0;
      end;
    else
      // Pøedání ostatních zpráv systému
      begin
      	Result := DefWindowProc(hWnd,uMsg,wParam,lParam);
      end;
    end;
end;

function RegisterWindowClass(application: Application): boolean;
var
  windowClass: WNDCLASSEX;
begin
  ZeroMemory(@windowClass,Sizeof(windowClass));
  with windowClass do
    begin
    cbSize := Sizeof(windowClass);
    style := CS_HREDRAW or CS_VREDRAW or CS_OWNDC;                  // Pøekreslení pøi zmìnì velikosti a vlastní DC
    lpfnWndProc := @WindowProc;                                     // Definuje proceduru okna
    hInstance := application.hInstance;                             // Instance
    hbrBackground := COLOR_APPWORKSPACE;                            // Pozadí není nutné
    hCursor := LoadCursor(0,IDC_ARROW);                             // Standardní kurzor myši
    lpszClassName := PChar(application.className);                  // Jméno tøídy okna
    end;
  if RegisterClassEx(windowClass) = 0 then                          // Registruje tøídu okna
    begin
    MessageBox(HWND_DESKTOP,'RegisterClassEx Failed!','Error',MB_OK or MB_ICONEXCLAMATION);
    Result := false;                                                // Pøi chybì vrátí false
    exit;
    end;
  Result := true;
end;

function WinMain(hInstance: HINST;                                  // Instance
		 hPrevInstance: HINST;                                          // Pøedchozí instance
		 lpCmdLine: PChar;                                              // Parametry pøíkazové øádky
		 nCmdShow: integer):                                            // Stav zobrazení okna
                        integer; stdcall;
var
  app: Application;
  window: GL_Window;
  key: Keys;
  isMessagePumpActive: boolean;
  msg: TMsg;                                                        // Struktura zpráv systému
begin
  app.className := 'OpenGL';
  app.hInstance := hInstance;
  ZeroMemory(@window,Sizeof(window));
  with window do
    begin
    keys := @key;
    init.application := @app;
    init.title := 'Lesson 41: NeHe''s Volumetric Fog Tutorial';
    init.width := 640;
    init.height := 480;
    init.bitsPerPixel := 32;
    init.isFullScreen := true;
    end;
  ZeroMemory(@key,Sizeof(key));
  // Dotaz na uživatele pro fullscreen/okno
  if MessageBox(HWND_DESKTOP,'Would You Like To Run In FullScreen Mode?','Start FullScreen',
                MB_YESNO or MB_ICONQUESTION) = IDNO then
    window.init.isFullScreen := false;                                 // Bìh v oknì
  if not RegisterWindowClass(app) then
    begin
    MessageBox(HWND_DESKTOP,'Error Registering Window Class!','Error',MB_OK or MB_ICONEXCLAMATION);
    Result := -1;
    exit;
    end;
  g_isProgramLooping := true;
  g_createFullScreen := window.init.isFullScreen;
  while g_isProgramLooping do
    begin
    window.init.isFullScreen := g_createFullScreen;
    if CreateWindowGL(window) then
      begin
      if not Initialize(@window,@key) then
        TerminateApplication(window)
        else
        begin
        isMessagePumpActive := true;
        while isMessagePumpActive do
          if PeekMessage(msg,0,0,0,PM_REMOVE) then                  // Pøišla zpráva?
            if msg.message <> WM_QUIT then                          // Obdrželi jsme zprávu pro ukonèení?
              DispatchMessage(msg)                                
              else
              isMessagePumpActive := false                          // Konec programu
            else
            if not window.isVisible then
              WaitMessage
        end;
      Deinitialize;
      DestroyWindowGL(window);
      end
      else
      begin
      MessageBox(HWND_DESKTOP,'Error Creating OpenGL Window','Error',MB_OK or MB_ICONEXCLAMATION);
      g_isProgramLooping := false;
      end;
    end;
  UnregisterClass(PChar(app.className),app.hInstance);
  Result := 0;
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );                  // Start programu
end.

