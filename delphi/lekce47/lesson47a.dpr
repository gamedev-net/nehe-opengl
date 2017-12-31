program lesson47a;

{   kód pro Delphi 7}

uses
  Windows,
  SysUtils,
  Messages,
  OpenGL,
  cg,
  cgGL,
  NeHeGL in 'NeHeGL.pas';

const
  TWO_PI = 6.2831853071;                                        // PI * 2
  SIZE = 64;                                                    // Velikost meshe

var
  g_window: PGL_Window;                                         // Okno
  g_keys: PKeys;                                                // Klávesy
  cg_enable: boolean = true;                                    // Flag spuštìní CG
  sp: boolean;
  mesh: array [0..SIZE-1,0..SIZE-1,0..2] of GLfloat;            // Data meshe
  wave_movement: GLfloat = 0.0;                                 // Pro vytvoøení sinusové vlny
  cgKontext: CGcontext;                                         // CG kontext
  cgPrg: CGprogram;                                             // CG vertex program
  cgVertexProfile: CGprofile;                                   // CG profil
  position, color, modelViewMatrix, wave: CGparameter;          // Parametry pro shader


function Initialize(window: PGL_Window; key: PKeys): boolean;	                  // Inicializace OpenGL
var
  x, z: integer;
  Error: CGerror;
begin
  g_window := window;                                                           // Okno
  g_keys := key;                                                                // Klávesnice
  glClearColor(0.0,0.0,0.0,0.5);                                                // Èerné pozadí
  glClearDepth(1.0);                                                            // Nastavení hloubkového bufferu
  glDepthFunc(GL_LEQUAL);                                                       // Typ testování hloubky
  glEnable(GL_DEPTH_TEST);                                                      // Zapne testování hloubky
  glShadeModel(GL_SMOOTH);                                                      // Jemné stínování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);                             // Nastavení perspektivy
  glPolygonMode(GL_FRONT_AND_BACK,GL_LINE);                                     // Drátìný model
  for x := 0 to SIZE - 1 do                                                     // Inicializace meshe
    for z := 0 to SIZE - 1 do
      begin
      mesh[x,z,0] := (SIZE / 2) - x;                                            // Vycentrování na ose x
      mesh[x,z,1] := 0.0;                                                       // Plochá rovina
      mesh[x,z,2] := (SIZE / 2) - z;                                            // Vycentrování na ose z
      end;
  cgKontext := cgCreateContext;                                                 // Vytvoøení CG kontextu
  if cgKontext = nil then                                                       // OK?
    begin
    MessageBox(0,'Failed To Create Cg Context','Error',MB_OK);
    Result := false;
    exit;
    end;
  cgVertexProfile := cgGLGetLatestProfile(CG_GL_VERTEX);                        // Získání minulého profilu vertexù
  if cgVertexProfile = CG_PROFILE_UNKNOWN then                                  // OK?
    begin
    MessageBox(0,'Invalid profile type','Error',MB_OK);
    Result := false;
    exit;
    end;
  cgGLSetOptimalOptions(cgVertexProfile);                                       // Nastavení profilu
  // Nahraje a zkompiluje vertex shader
  cgPrg := cgCreateProgramFromFile(cgKontext,CG_SOURCE,'CG/Wave.cg',cgVertexProfile,'main',nil);
  if cgPrg = nil then                                                           // OK?
    begin
    Error := cgGetError;                                                        // Typ chyby
    MessageBox(0,cgGetErrorString(Error),'Error',MB_OK);
    Result := false;
    exit;
    end;
  cgGLLoadProgram(cgPrg);                                                       // Nahraje program do grafické karty
  // Handle na promìnné
  position := cgGetNamedParameter(cgPrg,'IN.position');
  color := cgGetNamedParameter(cgPrg,'IN.color');
  wave := cgGetNamedParameter(cgPrg,'IN.wave');
  modelViewMatrix := cgGetNamedParameter(cgPrg,'ModelViewProj');
  Result := true;                                                               // OK
end;

procedure Deinitialize;                                                         // Deinicializace
begin
  cgDestroyContext(cgKontext);                                                  // Smaže CG kontext
end;

procedure Update(milliseconds: GLfloat);                                        // Aktualizace pohybù ve scénì a stisk kláves
begin
  if g_keys.keyDown[VK_ESCAPE] then                                             // Klávesa ESC?
    TerminateApplication(g_window^);                                            // Ukonèení programu
  if g_keys.keyDown[VK_F1] then                                                 // Klávesa F1?
    ToggleFullscreen(g_window^);                                                // Pøepnutí fullscreen/okno
  if g_keys.keyDown[Ord(' ')] and (not sp) then                                 // Mezerník
    begin
    sp := true;
    cg_enable := not cg_enable;                                                 // Zapne/vypne CG program
    end;
  if not g_keys.keyDown[Ord(' ')] then                                          // Uvolnìní mezerníku
    begin
    sp := false;
    end;
end;

procedure Draw;                                                                 // Vykreslení scény
var
  x, z: integer;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                          // Smaže obrazovku
  glLoadIdentity;                                                               // Reset matice
  gluLookAt(0.0,25.0,-45.0,0.0,0.0,0.0,0,1,0);                                  // Pozice kamery
  // Nastavení modelview matice v shaderu
  cgGLSetStateMatrixParameter(modelViewMatrix,CG_GL_MODELVIEW_PROJECTION_MATRIX,CG_GL_MATRIX_IDENTITY);
  if cg_enable then                                                             // Zapnout CG shader?
    begin
    cgGLEnableProfile(cgVertexProfile);                                         // Zapne profil
    cgGLBindProgram(cgPrg);                                                     // Zvolí program
    cgGLSetParameter4f(color,0.5,1.0,0.5,1.0);                                  // Nastaví barvu (svìtle zelená)
    end;
  for x := 0 to SIZE - 2 do                                                     // Vykreslení meshe
    begin
    glBegin(GL_TRIANGLE_STRIP);                                                 // Každý proužek jedním triangle stripem
    for z := 0 to SIZE - 2 do
      begin
      cgGLSetParameter3f(wave,wave_movement,1.0,1.0);                           // Parametr vlny
      glVertex3f(mesh[x,z,0],mesh[x,z,1],mesh[x,z,2]);                          // Vertex
      glVertex3f(mesh[x+1,z,0],mesh[x+1,z,1],mesh[x+1,z,2]);                    // Vertex
      wave_movement := wave_movement + 0.00001;                                 // Inkrementace parametru vlny
      if wave_movement > TWO_PI then                                            // Vìtší než dvì pí (6,28)?
        wave_movement := 0.0;                                                   // Vynulovat
      end;
    glEnd;                                                                      // Konec triangle stripu
    end;
  if cg_enable then                                                             // Zapnutý CG shader?
    cgGLDisableProfile(cgVertexProfile);                                        // Vypne profil
	glFlush;                                                                      // Vyprázdní OpenGL renderovací pipeline
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
  timer: Int64;
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
    WM_ERASEBKGND:
      begin
      Result := 0;
      end; 
    WM_PAINT:
      begin
      if window.hrTimer then
        begin
        QueryPerformanceCounter(timer);
				tickCount := timer;
        end
        else
        tickCount := GetTickCount;
      Update((tickCount - window.lastTickCount) * window.timerResolution * 1000.0);
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
    hbrBackground := COLOR_WINDOW+1;                                // Pozadí není nutné
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
    init.title := 'Lesson 47: NeHe & Owen Bourne''s Cg Vertex Shader Tutorial';
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

