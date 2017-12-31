program lesson39a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages,
  SysUtils,
  OpenGL,
  NeHeGL in 'NeHeGL.pas',
  Physics in 'Physics.pas';

var
  g_window: PGL_Window;                                     // Okno
  g_keys: PKeys;                                            // Klávesy
  CV: ConstantVelocity;                                     // Objekt s konstantní rzchlostí
  MUG: MotionUnderGravitation;                              // Objekt v gravitaèním poli
  MCWS: MassConnectedWithSpring;                            // Objekt na pružinì
  slowMotionRatio: GLfloat = 10.0;                          // Zpomalení simulace
  timeElapsed: GLfloat = 0;                                 // Uplynulý èas
  base: GLuint;
  gmf: array [0..255] of GLYPHMETRICSFLOAT;


procedure BuildFont(window: PGL_Window);                  // Vytvoøení fontu
var Font: HFONT;                                          // Promìnná fontu
begin
  base := glGenLists(256);                                // 256 znakù
  font := CreateFont(-12,                                 // Výška
                      0,                                  // Šíøka
                      0,                                  // Úhel escapement
                      0,                                  // Úhel orientace
                      FW_BOLD,                            // Tuènost
                      0,                                  // Kurzíva
                      0,                                  // Podtržení
                      0,                                  // Pøeškrtnutí
                      ANSI_CHARSET,                       // Znaková sada
                      OUT_TT_PRECIS,                      // Pøesnost výstupu (TrueType)
                      CLIP_DEFAULT_PRECIS,                // Pøesnost oøezání
                      ANTIALIASED_QUALITY,                // Výstupní kvalita
                      FF_DONTCARE or DEFAULT_PITCH,       // Rodina a pitch
                      nil);                               // Jméno fontu
  SelectObject(window.hDc,font);                          // Výbìr fontu do DC
  wglUseFontOutlines(window.hDc,                          // Vybere DC
                      0,                                  // Poèáteèní znak
                      255,                                // Koncový znak
                      base,                               // Adresa prvního znaku
                      0,                                  // Hranatost
                      0.0,                                // Hloubka v ose z
                      WGL_FONT_POLYGONS,                  // Polygony ne drátìný model
                      @gmf);                              // Adresa bufferu pro uložení informací
end;

procedure KillFont;                                       // Smaže font
begin
  glDeleteLists(base,256);                                // Smaže všech 256 znakù (display listù)
end;

procedure glPrint(x, y, z: GLfloat; text: string);
var
  delka: glfloat;                                                               // Délka znaku
  loop: integer;                                                                // Cyklus
begin
  if text = '' then exit;                                                       // Byl pøedán text?
  delka := 0;
  for loop:=1 to length(text) do delka := delka + gmf[Ord(text[loop])].gmfCellIncX; // Inkrementace o šíøku znaku
  glTranslatef(x - delka,y,z);                                                  // Zarovnání
  glPushAttrib(GL_LIST_BIT);                                                    // Uloží souèasný stav display listù
  glListBase(base);                                                             // Nastaví první display list na base
  glCallLists(length(text),GL_UNSIGNED_BYTE,Pchar(text));                       // Vykreslí display listy
  glPopAttrib;                                                                  // Obnoví pùvodní stav display listù
  glTranslatef(-x,-y,-z);                                                       // Zpìt na souøadnice pøed výpisem textu
end;

function Initialize(window: PGL_Window; key: PKeys): boolean;	                  // Inicializace OpenGL
begin
  g_window := window;
  g_keys := key;
  CV := ConstantVelocity.Create;                                                // Vytvoøení objektù
  MUG := MotionUnderGravitation.Create(Vektor(0.0,-9.81,0.0));
  MCWS := MassConnectedWithSpring.Create(2.0);
  glClearColor(0.0,0.0,0.0,0.5);                                                // Èerné pozadí
  glShadeModel(GL_SMOOTH);                                                      // Jemné stínování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);                             // Perspektivní korekce
  BuildFont(window);                                                            // Vytvoøí font
  Result := true;                                                               // Inicializace úspìšná
end;

procedure Deinitialize;                                                         // Deinicializace
begin
  KillFont;                                                                     // Zrušení fontu
  CV.Release;                                                                   // Uvolnìní prostøedkù
  CV.Free;
  CV := nil;
  MUG.Release;
  MUG.Free;
  MUG := nil;
  MCWS.Release;
  MCWS.Free;
  MCWS := nil;
end;

procedure Update(milliseconds: DWORD);                                // Aktualizace pohybù ve scénì a stisk kláves
var
  dt: GLfloat;
  maxPossible_dt: GLfloat;
  numOfIterations: integer;
  a: integer;
begin
  if g_keys.keyDown[VK_ESCAPE] then                                   // Klávesa ESC?
    TerminateApplication(g_window^);                                  // Ukonèení programu
  if g_keys.keyDown[VK_F1] then                                       // Klávesa F1?
    ToggleFullscreen(g_window^);                                      // Pøepnutí fullscreen/okno
  if g_keys.keyDown[VK_F2] then                                       // Klávesa F2?
    slowMotionRatio := 1.0;                                           // Reálný èas
  if g_keys.keyDown[VK_F3] then                                       // Klávesa F3?
    slowMotionRatio := 10.0;                                          // Zpomalení 10x
  dt := milliseconds / 1000.0;                                        // Pøepoèítá milisekundy na sekundy
  dt := dt / slowMotionRatio;                                         // Dìlení dt zpomalovací promìnnou
  timeElapsed := timeElapsed + dt;                                    // Zvìtšení uplynulého èasu
  // Abychom nepøekroèili hranici kdy už se simulace nechová reálnì
  maxPossible_dt := 0.1;                                              // Nastavení maximální hodnoty dt na 0.1 sekund
  numOfIterations := Trunc(dt / maxPossible_dt) + 1;                  // Výpoèet poètu opakování simulace v závislosti na dt a maximální možné hodnotì dt
  if numOfIterations <> 0 then                                        // Vyhneme se dìlení nulou
    dt := dt / numOfIterations;                                       // dt by se mìla aktualizovat pomocí numOfIterations
  for a := 0 to numOfIterations - 1 do                                // Simulaci potøebujeme opakovat numOfIterations-krát
    begin
    CV.operate(dt);                                                   // Provedení simulace konstantní rychlosti za dt sekund
    MUG.operate(dt);                                                  // Provedení simulace pohybu v gravitaci za dt sekund
    MCWS.operate(dt);                                                 // Provedení simulace pružiny za dt sekund
    end;
end;

procedure Draw;                                                                 // Vykreslení scény
var
  x, y, a: integer;                                                             // Øídící promìnné cyklù
  massObj: Mass;
  pos: Vector3D;
begin
  glMatrixMode(GL_MODELVIEW);                                                   // Druh matice
	glLoadIdentity;                                                               // Reset
  gluLookAt(0,0,40,0,0,0,0,1,0);                                                // Nastavení kamery
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                          // Smaže obrazovku a hloubkový buffer
  glColor3ub(0,0,255);										                                      // Modrá
	glBegin(GL_LINES);                                                            // Kreslení èar
    for x := -20 to 20 do                                                       // vertikální èáry v møížce
      begin
      glVertex3f(x, 20,0);
		  glVertex3f(x,-20,0);
      end;
    for y := -20 to 20 do                                                       // Horizontální èáry v møížce
      begin
      glVertex3f( 20,y,0);
		  glVertex3f(-20,y,0);
      end;
  glEnd;                                                                        // Konec kreslení èar
  glColor3ub(255,0,0);                                                          // Èervená
  for a := 0 to CV.numOfMasses - 1 do                                           // Vykreslí všechny objekty s konstantní rychlostí
    begin
    massObj := CV.getMass(a);
    pos := massObj.pos;
    glPrint(pos.x,pos.y + 1,pos.z,'Mass with constant vel');
		glPointSize(4);
		glBegin(GL_POINTS);
			glVertex3f(pos.x,pos.y,pos.z);
		glEnd;
    end;
  glColor3ub(255,255,0);                                                        // Žlutá
  for a := 0 to MUG.numOfMasses - 1 do                                          // Vykreslí všechny objekty v gravitaèním poli
    begin
    massObj := MUG.getMass(a);
    pos := massObj.pos;
    glPrint(pos.x,pos.y + 1,pos.z,'Motion under gravitation');
		glPointSize(4);
		glBegin(GL_POINTS);
			glVertex3f(pos.x,pos.y,pos.z);
		glEnd;
    end;
  glColor3ub(0,255,0);                                                          // Zelená
  for a := 0 to MCWS.numOfMasses - 1 do                                         // Vykreslí všechny objekty na pružinì
    begin
    massObj := MCWS.getMass(a);
    pos := massObj.pos;
    glPrint(pos.x,pos.y + 1,pos.z,'Mass connected with spring');
		glPointSize(8);
		glBegin(GL_POINTS);
			glVertex3f(pos.x,pos.y,pos.z);
		glEnd;
		// Vykreslení pružiny (èára mezi objektem a úchytem)
		glBegin(GL_LINES);
			glVertex3f(pos.x,pos.y,pos.z);
			pos := MCWS.connectionPos;
			glVertex3f(pos.x,pos.y,pos.z);
		glEnd;
    end;
  glColor3ub(255,255,255);									                                    // Bílá
	glPrint(-5.0,14,0,Format('Time elapsed (seconds): %.2f',[timeElapsed]));	    // Výpis uplynulého èasu
	glPrint(-5.0,13,0,Format('Slow motion ratio: %.2f',[slowMotionRatio]));	      // Výpis zpomalení
	glPrint(-5.0,12,0,'Press F2 for normal motion');
	glPrint(-5.0,11,0,'Press F3 for slow motion');
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
    init.title := 'NeHe & Erkin Tunca''s Physics Tutorial';
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

