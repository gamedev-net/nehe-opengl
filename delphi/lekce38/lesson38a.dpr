program lesson38a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages,
  OpenGL,
  NeHeGL in 'NeHeGL.pas';

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;
procedure glDeleteTextures(n: GLsizei; textures: PGLuint); stdcall; external 'opengl32';

type
  Objekt = record                                           // Struktura nazvaná objekt
    tex: integer;                                           // Kterou texturu namapovat
    x, y, z: GLfloat;                                       // X, Y, Z Pozice
    yi: GLfloat;                                            // Rychlost pádu
    spinz: GLfloat;                                         // Úhel otoèení kolem osy z
    spinzi: GLfloat;                                        // Rychlost otáèení kolem osy z
    flap: GLfloat;                                          // Mávání køídly
    fi: GLfloat;                                            // Smìr mávání
    end;

const
  GL_BGR_EXT = $80E0;                                       // Extension konstanta z jednotky gl.pas, abych ji nemusel celou linkovat

var
  g_window: PGL_Window;                                     // Okno
  g_keys: PKeys;                                            // Klávesy
  texture: array [0..2] of GLuint;                          // Místo pro 3 textury
  obj: array [0..49] of Objekt;                             // Vytvoøí 50 objektù na bázi struktury


{$R zdroje.res}                                             // Soubor pro Resource (*DÙLEŽITÉ*) - tam jsou naši motýli

procedure SetObject(loop: integer);                         // Nastavení základních vlastností objektu
begin
  with obj[loop] do
    begin
    tex := Random(3);                                       // Výbìr jedné ze tøí textur
    x := Random(34) - 17.0;                                 // Náhodné x od -17.0 do 17.0
    y := 18.0;                                              // Pozici y nastavíme na 18 (nad obrazovku)
    z := -((Random(30000) / 1000.0) + 10.0);                // Náhodné z od -10.0 do -40.0
    spinzi := Random(10000) / 5000.0 - 1.0;                 // Spinzi je náhodné èíslo od -1.0 do 1.0
    flap := 0.0;                                            // Flap zaène na 0.0
    fi := 0.05 + Random(100) / 1000.0;                      // Fi je náhodné èíslo od 0.05 do 0.15
    yi := 0.001 + Random(1000) / 10000.0;                   // Yi je náhodné èíslo od 0.001 do 0.101
    end;
end;

procedure LoadGLTextures;                                                       // Vytvoøí textury z bitmap ve zdrojovém souboru
var
  hBMP: HBITMAP;                                                                // Ukazatel na bitmapu
  BMP: BITMAP;                                                                  // Struktura bitmapy
  loop: integer;
  TextureID: array [0..2] of PAnsiChar;                                         // ID bitmap
begin
  TextureID[0] := 'BUTTERFLY1';                                                 // ID bitmap, které chceme naèíst
  TextureID[1] := 'BUTTERFLY2';
  TextureID[2] := 'BUTTERFLY3';
  glGenTextures(3,texture[0]);                                                  // Vygenerování tøí textur
  for loop := 0 to 2 do                                                         // Projde všechny bitmapy ve zdrojích
    begin
    hBMP := LoadImage(GetModuleHandle(nil),TextureID[loop],IMAGE_BITMAP,0,0,LR_CREATEDIBSECTION); // Nahraje bitmapu ze zdrojù
    if hBMP <> 0 then                                                           // Pokud existuje bitmapa
      begin
      GetObject(hBMP,sizeof(BMP),@BMP);                                         // Získání objektu
      glPixelStorei(GL_UNPACK_ALIGNMENT,4);                                     // 4 byty na jeden pixel
      glBindTexture(GL_TEXTURE_2D,texture[loop]);                               // Zvolí texturu
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);           // Lineární filtrování
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR); // Mipmapované lineární filtrování
      gluBuild2DMipmaps(GL_TEXTURE_2D,3,BMP.bmWidth,BMP.bmHeight,GL_BGR_EXT,GL_UNSIGNED_BYTE,BMP.bmBits); // Vygenerování mipmapované textury (3 byty, šíøka, výška a BMP data)
      DeleteObject(hBMP);                                                       // Smaže objekt bitmapy
      end;
    end;
end;

function Initialize(window: PGL_Window; key: PKeys): boolean;	                  // Inicializace OpenGL
var
  loop: integer;                                                                // Øídící promìnná cyklù
begin
  g_window := window;
  g_keys := key;
  LoadGLTextures;                                                               // Nahraje textury ze zdrojù
  glClearColor(0.0,0.0,0.0,0.5);                                                // Èerné pozadí
  glClearDepth(1.0);                                                            // Nastavení hloubkového bufferu
  glDepthFunc(GL_LEQUAL);                                                       // Typ testování hloubky
  glDisable(GL_DEPTH_TEST);                                                     // Vypnutí hloubkového testování
  glShadeModel(GL_SMOOTH);                                                      // Jemné stínování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);                             // Perspektivní korekce
  glEnable(GL_TEXTURE_2D);                                                      // Povolí texturové mapování
  glBlendFunc(GL_ONE,GL_SRC_ALPHA);                                             // Nastavení blendingu (nenároèný / rychlý)
  glEnable(GL_BLEND);                                                           // Povolení blendingu
  for loop := 0 to 49 do SetObject(loop);                                       // Inicializace 50 motýlù
  Result := true;                                                               // Inicializace úspìšná
end;

procedure Deinitialize;                                                         // Deinicializace
begin
  glDeleteTextures(3,@texture);                                                 // Smaže textury
end;

procedure Update(milliseconds: DWORD);                                // Aktualizace pohybù ve scénì a stisk kláves
begin
  if g_keys.keyDown[VK_ESCAPE] then                                   // Klávesa ESC?
    TerminateApplication(g_window^);                                  // Ukonèení programu
  if g_keys.keyDown[VK_F1] then                                       // Klávesa F1?
    ToggleFullscreen(g_window^);                                      // Pøepnutí fullscreen/okno
end;

procedure Draw;                                                       // Vykreslení scény
var
  loop: integer;                                                      // Øídící promìnné cyklù
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                // Smaže obrazovku a hloubkový buffer
  for loop := 0 to 49 do                                              // Projde 50 motýlkù
    begin
    glLoadIdentity;                                                   // Reset matice
    glBindTexture(GL_TEXTURE_2D,texture[obj[loop].tex]);              // Zvolí texturu
    glTranslatef(obj[loop].x,obj[loop].y,obj[loop].z);                // Umístìní
    glRotatef(45.0,1.0,0.0,0.0);                                      // Rotace na ose x
    glRotatef(obj[loop].spinz,0.0,0.0,1.0);                           // Rotace na ose y
    glBegin(GL_TRIANGLES);                                            // Kreslení trojúhelníkù
      // První trojúhelník
      glTexCoord2f(1.0,1.0); glVertex3f( 1.0, 1.0, 0.0);              // Pravý horní bod
      glTexCoord2f(0.0,1.0); glVertex3f(-1.0, 1.0, obj[loop].flap);   // Levý horní bod
      glTexCoord2f(0.0,0.0); glVertex3f(-1.0,-1.0, 0.0);              // Levý dolní bod
      // Druhý trojúhelník
      glTexCoord2f(1.0,1.0); glVertex3f( 1.0, 1.0, 0.0);              // Pravý horní bod
      glTexCoord2f(0.0,0.0); glVertex3f(-1.0,-1.0, 0.0);              // Levý dolní bod
      glTexCoord2f(1.0,0.0); glVertex3f( 1.0,-1.0, obj[loop].flap);   // Pravý dolní bod
    glEnd;                                                            // Konec kreslení
    obj[loop].y := obj[loop].y - obj[loop].yi;                        // Pád motýla dolù
    obj[loop].spinz := obj[loop].spinz + obj[loop].spinzi;            // Zvýšení natoèení na ose z o spinzi
    obj[loop].flap := obj[loop].flap + obj[loop].fi;                  // Zvìtšení máchnutí køídlem o fi
    if obj[loop].y < -18.0 then                                       // Je motýl mimo obrazovku?
      SetObject(loop);                                                // Nastavíme mu nové parametry
    if (obj[loop].flap > 1.0) or (obj[loop].flap < -1.0) then         // Máme zmìnit smìr mávnutí køídly
      obj[loop].fi := - obj[loop].fi;                                 // Zmìní smìr mávnutí
    end;
  Sleep(15);                                                          // Pozastavení programu na 15 milisekund
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
    init.title := 'NeHe''s Resource File Tutorial';
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

