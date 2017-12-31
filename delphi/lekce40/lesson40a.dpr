program lesson40a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages,
  OpenGL,
  NeHeGL in 'NeHeGL.pas',
  Physics in 'Physics.pas',
  Physics2 in 'Physics2.pas';

var
  g_window: PGL_Window;                                     // Okno
  g_keys: PKeys;                                            // Klávesy
  RS: RopeSimulation;                                       // Lano


function Initialize(window: PGL_Window; key: PKeys): boolean;	                  // Inicializace OpenGL
begin
  g_window := window;
  g_keys := key;
  RS := RopeSimulation.Create(80,                                               // Vytvoøení objektu simulace lana - 80 èástic
                              0.05,                                             // Každá èástice váží 50 gramù
                              10000.0,                                          // Tuhost pružin
                              0.05,                                             // Délka pružin, pøi nepùsobení žádný sil
                              0.2,                                              // Konstanta vnitøního tøení pružiny
                              Vektor(0,-9.81,0),                                // Gravitaèní zrychlení
                              0.02,                                             // Odpor vzduchu
                              100.0,                                            // Síla odrazu od zemì
                              0.2,                                              // Tøecí síla zemì
                              2.0,                                              // Absorbèní síla zemì
                              -1.5);                                            // Poloha zemì na ose y
  RS.getMass(RS.numOfMasses-1).vel.z := 10.0;                                   // Umístìní v hloubce
  glClearColor(0.0,0.0,0.0,0.5);                                                // Èerné pozadí
  glClearDepth(1.0);
  glShadeModel(GL_SMOOTH);                                                      // Jemné stínování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);                             // Perspektivní korekce
  Result := true;                                                               // Inicializace úspìšná
end;

procedure Deinitialize;                                                         // Deinicializace
begin
  RS.release;
  RS := nil;
end;

procedure Update(milliseconds: DWORD);                                // Aktualizace pohybù ve scénì a stisk kláves
var
  ropeConnectionVel: Vector3D;
  dt: GLfloat;
  maxPossible_dt: GLfloat;
  numOfIterations: integer;
  a: integer;
begin
  ropeConnectionVel := Vektor(0,0,0);
  if g_keys.keyDown[VK_ESCAPE] then                                   // Klávesa ESC?
    TerminateApplication(g_window^);                                  // Ukonèení programu
  if g_keys.keyDown[VK_F1] then                                       // Klávesa F1?
    ToggleFullscreen(g_window^);                                      // Pøepnutí fullscreen/okno
  if g_keys.keyDown[VK_RIGHT] then                                    // Vpravo
    ropeConnectionVel.x := ropeConnectionVel.x + 3.0;
  if g_keys.keyDown[VK_LEFT] then                                     // Vlevo
    ropeConnectionVel.x := ropeConnectionVel.x - 3.0;
  if g_keys.keyDown[VK_UP] then                                       // Dozadu
    ropeConnectionVel.z := ropeConnectionVel.z - 3.0;
  if g_keys.keyDown[VK_DOWN] then                                     // Dopøedu
    ropeConnectionVel.z := ropeConnectionVel.z + 3.0;
  if g_keys.keyDown[VK_HOME] then                                     // Nahoru
    ropeConnectionVel.y := ropeConnectionVel.y + 3.0;
  if g_keys.keyDown[VK_END] then                                      // Dolu
    ropeConnectionVel.y := ropeConnectionVel.y - 3.0;
  RS.setRopeConnectionVel(ropeConnectionVel);                         // Vektor pohybu
  dt := milliseconds / 1000.0;                                        // Pøepoèítá milisekundy na sekundy
  // Abychom nepøekroèili hranici kdy už se simulace nechová reálnì
  maxPossible_dt := 0.002;                                            // Nastavení maximální hodnoty dt na 0.1 sekund
  numOfIterations := Trunc(dt / maxPossible_dt) + 1;                  // Výpoèet poètu opakování simulace v závislosti na dt a maximální možné hodnotì dt
  if numOfIterations <> 0 then                                        // Vyhneme se dìlení nulou
    dt := dt / numOfIterations;                                       // dt by se mìla aktualizovat pomocí numOfIterations
  for a := 0 to numOfIterations - 1 do                                // Simulaci potøebujeme opakovat numOfIterations-krát
    begin
    RS.operate(dt);                                                   // Krok simulace
    end;
end;

procedure Draw;                                                                 // Vykreslení scény
var
  a: integer;                                                                   // Øídící promìnné cyklù
  mass1, mass2: Mass;
  pos1, pos2: Vector3D;
begin
  glMatrixMode(GL_MODELVIEW);                                                   // Druh matice
	glLoadIdentity;                                                               // Reset
  gluLookAt(0,0,4,0,0,0,0,1,0);                                                 // Nastavení kamery
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                          // Smaže obrazovku a hloubkový buffer
  glBegin(GL_QUADS);                                                            // Podlaha
		glColor3ub(0,0,255);
		glVertex3f(20,RS.groundHeight,20);
		glVertex3f(-20,RS.groundHeight,20);
		glColor3ub(0,0,0);
		glVertex3f(-20,RS.groundHeight,-20);
		glVertex3f(20,RS.groundHeight,-20);
	glEnd;
  glColor3ub(0,0,0);                                                            // Stín lana
  for a := 0 to RS.numOfMasses - 2 do
    begin
    mass1 := RS.getMass(a);
    pos1 := mass1.pos;
    mass2 := RS.getMass(a+1);
    pos2 := mass2.pos;
    glLineWidth(2);
		glBegin(GL_LINES);
			glVertex3f(pos1.x,RS.groundHeight,pos1.z);
			glVertex3f(pos2.x,RS.groundHeight,pos2.z);
		glEnd;
    end;
  glColor3ub(255,255,0);                                                        // Lano
  for a := 0 to RS.numOfMasses - 2 do
    begin
    mass1 := RS.getMass(a);
    pos1 := mass1.pos;
    mass2 := RS.getMass(a+1);
    pos2 := mass2.pos;
    glLineWidth(4);
		glBegin(GL_LINES);
			glVertex3f(pos1.x,pos1.y,pos1.z);
			glVertex3f(pos2.x,pos2.y,pos2.z);
		glEnd;
    end;
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
  tickCount: DWORD;
begin
  app.className := 'OpenGL';
  app.hInstance := hInstance;
  ZeroMemory(@window,Sizeof(window));
  with window do
    begin
    keys := @key;
    init.application := @app;
    init.title := 'NeHe & Erkin Tunca''s Rope Physics Tutorial';
    init.width := 640;
    init.height := 480;
    init.bitsPerPixel := 16;
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
              else
              begin
              tickCount := GetTickCount;
              Update(tickCount - window.lastTickCount);
              window.lastTickCount := tickCount;
              Draw;
              SwapBuffers(window.hDc);
              end;
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

