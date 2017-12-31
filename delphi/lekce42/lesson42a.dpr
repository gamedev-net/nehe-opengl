program lesson42a;

{   kód pro Delphi 7}

uses
  Windows,
  SysUtils,
  Messages,
  OpenGL,
  NeHeGL in 'NeHeGL.pas';

procedure glTexSubImage2D(target: GLenum; level, xoffset, yoffset: GLint; width, height: GLsizei; format, atype: GLenum; const pixels: Pointer); stdcall; external 'opengl32';

const
  width = 128;                                                  // Šíøka textury (musí být mocninou èísla 2)
  height = 128;                                                 // Výška textury (musí být mocninou èísla 2)

var
  g_window: PGL_Window;                                         // Okno
  g_keys: PKeys;                                                // Klávesy
  mx, my: integer;                                              // Øídící promìnné cyklù
  done: boolean;                                                // Bludištì vygenerováno?
  sp: boolean;                                                  // Flag stisku mezerníku
  r, g, b: array [0..3] of Byte;                                // Ètyøi náhodné barvy
  tex_data: array of Byte;                                      // Data textury
  xrot, yrot, zrot: GLfloat;                                    // Úhly rotací objektù
  quadric: GLUquadricObj;                                       // Objekt quadraticu


procedure UpdateTex(dmx, dmy: integer);                                         // Zabílí urèený pixel na textuøe
begin
  tex_data[0 + ((dmx + (width * dmy)) * 3)] := 255;                             // Èervená složka
  tex_data[1 + ((dmx + (width * dmy)) * 3)] := 255;                             // Zelená složka
  tex_data[2 + ((dmx + (width * dmy)) * 3)] := 255;                             // Modrá složka
end;

procedure Reset;                                                                // Reset textury, barev, aktuální pozice v bludišti
var
  loop: integer;
begin
  ZeroMemory(tex_data,width * height * 3);                                      // Nuluje pamì textury
  RandSeed := GetTickCount;                                                     // Inicializace generátoru náhodných èísel
  for loop := 0 to 3 do                                                         // Generuje ètyøi náhodné barvy
    begin
    r[loop] := Random(128) + 128;                                               // Èervená složka
    g[loop] := Random(128) + 128;                                               // Zelená složka
    b[loop] := Random(128) + 128;                                               // Modrá složka
    end;
  mx := Random(width div 2) * 2;                                                // Náhodná x pozice
  my := Random(height div 2) * 2;                                               // Náhodná y pozice
end;

function Initialize(window: PGL_Window; key: PKeys): boolean;	                  // Inicializace OpenGL
begin
  SetLength(tex_data,width * height * 3);                                       // Alokace pamìti pro texturu
  g_window := window;                                                           // Okno
  g_keys := key;                                                                // Klávesnice
  Reset;
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP);                    // Clamp parametry textury
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);               // Lineární filtrování
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D,0,GL_RGB,width,height,0,GL_RGB,GL_UNSIGNED_BYTE,tex_data); // Vytvoøí texturu
  glClearColor(0.0,0.0,0.0,0.0);                                                // Èerné pozadí
  glClearDepth(1.0);                                                            // Nastavení hloubkového bufferu
  glDepthFunc(GL_LEQUAL);                                                       // Typ testování hloubky
  glEnable(GL_DEPTH_TEST);                                                      // Zapne testování hloubky
  glEnable(GL_COLOR_MATERIAL);                                                  // Zapne vybarvování materiálù
  glEnable(GL_TEXTURE_2D);                                                      // Zapne mapování textur
  quadric := gluNewQuadric;                                                     // Vytvoøí objekt quadraticu
  gluQuadricNormals(quadric,GLU_SMOOTH);                                        // Normály pro svìtlo
  gluQuadricTexture(quadric,GL_TRUE);                                           // Texturové koordináty
  glEnable(GL_LIGHT0);                                                          // Zapne svìtlo 0
  Result := true;                                                               // OK
end;

procedure Deinitialize;                                                         // Deinicializace
begin
  SetLength(tex_data,0);                                                        // Smaže data textury
end;

procedure Update(milliseconds: GLfloat);                                        // Aktualizace pohybù ve scénì a stisk kláves
var
  dir: integer;                                                                 // Ukládá aktuální smìr pohybu
  x, y: integer;
begin
  if g_keys.keyDown[VK_ESCAPE] then                                             // Klávesa ESC?
    TerminateApplication(g_window^);                                            // Ukonèení programu
  if g_keys.keyDown[VK_F1] then                                                 // Klávesa F1?
    ToggleFullscreen(g_window^);                                                // Pøepnutí fullscreen/okno
  if g_keys.keyDown[Ord(' ')] and (not sp) then                                 // Mezerník
    begin
    sp := true;
    Reset;                                                                      // Resetuje scénu
    end;
  if not g_keys.keyDown[Ord(' ')] then                                          // Uvolnìní mezerníku
    begin
    sp := false;
    end;
  xrot := xrot + milliseconds * 0.02;                                           // Aktualizace úhlù natoèení
  yrot := yrot + milliseconds * 0.03;
  zrot := zrot + milliseconds * 0.015;
  done := true;                                                                 // Pøedpokládá se, že je už bludištì kompletní
  x := 0;
  repeat                                                                        // Prochází všechny místnosti na ose x
    y := 0;
    repeat                                                                      // Prochází všechny místnosti na ose y
    if tex_data[((x + (width * y)) * 3)] = 0 then                                                            // Pokud má pixel èernou barvu
      done := false;                                                            // Bludištì ještì není hotové
    Inc(y,2);
    until y >= height;
  Inc(x,2);
  until x >= width;
  if done then                                                                  // Je bludištì hotové?
    begin                                                                       // Zmìna titulku okna
    SetWindowText(g_window.hWnd,'Lesson 42: Multiple Viewports... 2003 NeHe Productions... Maze Complete!');
    Sleep(5000);                                                                // Zastavení na pìt sekund
    SetWindowText(g_window.hWnd,'Lesson 42: Multiple Viewports... 2003 NeHe Productions... Building Maze!');
    Reset;                                                                      // Reset bludištì a scény
    end;
  if (((tex_data[(((mx+2)+(width*my))*3)] = 255) or (mx >(width-4)))            // Máme kam jít?
      and ((tex_data[(((mx-2)+(width*my))*3)] = 255) or (mx < 2))
      and ((tex_data[((mx+(width*(my+2)))*3)] = 255) or (my > (height-4)))
      and ((tex_data[((mx+(width*(my-2)))*3)] = 255) or( my <2 ))) then
    begin
    repeat
    mx := Random(width div 2) * 2;                                              // Nová pozice
    my := Random(height div 2) * 2;
    until tex_data[((mx + (width * my)) * 3)] <> 0;                             // Hledá se navštívená místnost
    end;
  dir := Random(4);                                                             // Náhodný smìr pohybu
  if (dir = 0) and (mx <= (width-4)) then                                       // Smìr doprava; vpravo je místo
    if tex_data[(((mx+2) + (width*my)) * 3)] = 0 then                           // Místnost vpravo ještì nebyla navštívena
      begin
      UpdateTex(mx+1, my);                                                      // Oznaèí prùchod mezi místnostmi
      mx := mx + 2;                                                             // Posunutí doprava
      end;
  if (dir = 1) and (my <= (height-4)) then                                      // Smìr dolù; dole je místo
    if tex_data[((mx + (width * (my+2))) * 3)] = 0 then                         // Místnost dole ještì nebyla navštívena
    begin
    UpdateTex(mx, my+1);                                                        // Oznaèí prùchod mezi místnostmi
    my := my + 2;                                                               // Posunutí dolù
    end;
  if (dir = 2) and (mx >= 2) then                                               // Smìr doleva; vlevo je místo
    if tex_data[(((mx-2) + (width*my)) * 3)] = 0 then                           // Místnost vlevo ještì nebyla navštívena
    begin
    UpdateTex(mx-1, my);                                                        // Oznaèí prùchod mezi místnostmi
    mx := mx - 2;                                                               // Posunutí doleva
    end;
  if (dir = 3) and (my >= 2) then                                               // Smìr nahoru; nahoøe je místo
    if tex_data[((mx + (width * (my-2))) * 3)] = 0 then                         // Místnost nahoøe ještì nebyla navštívena
    begin
    UpdateTex(mx, my-1);                                                        // Oznaèí prùchod mezi místnostmi
    my := my - 2;                                                               // Posunutí nahoru
    end;                                                                        // Oznaèení nové místnosti
  UpdateTex(mx,my);
end;

procedure Draw;                                                                 // Vykreslení scény
var
  rect: TRect;                                                                  // Struktura obdélníku
  window_width: integer;                                                        // Šíøka okna
  window_height: integer;                                                       // Výška okna
  loop: integer;
begin
  GetClientRect(g_window.hWnd,rect);                                            // Grabování rozmìrù okna
  window_width := rect.Right - rect.Left;                                       // Šíøka okna
  window_height := rect.Bottom - rect.Top;                                      // Výška okna
  glTexSubImage2D(GL_TEXTURE_2D,0,0,0,width,height,GL_RGB,GL_UNSIGNED_BYTE,tex_data); // Zvolí aktualizovanou texturu
  glClear(GL_COLOR_BUFFER_BIT);                                                 // Smaže obrazovku
  for loop := 0 to 3 do                                                         // Prochází viewporty
    begin
    glColor3ub(r[loop],g[loop],b[loop]);                                        // Barva
    if loop = 0 then                                                            // První scéna
      begin
      glViewport(0,window_height div 2,window_width div 2,window_height div 2); // Levý horní viewport, velikost poloviny okna
      glMatrixMode(GL_PROJECTION);                                              // Projekèní matice
      glLoadIdentity;                                                           // Reset projekèní matice
      gluOrtho2D(0,window_width div 2,window_height div 2,0);                   // Pravoúhlá projekce
      end;
    if loop = 1 then                                                            // Druhá scéna
      begin
      glViewport(window_width div 2,window_height div 2,window_width div 2,window_height div 2);  // Pravý horní viewport, velikost poloviny okna
      glMatrixMode(GL_PROJECTION);                                              // Projekèní matice
      glLoadIdentity;                                                           // Reset projekèní matice
      gluPerspective(45.0,width / height,0.1,500.0);                            // Perspektivní projekce
      end;
    if loop = 2 then                                                            // Tøetí scéna
      begin
      glViewport(window_width div 2,0,window_width div 2,window_height div 2);  // Pravý dolní viewport, velikost poloviny okna
      glMatrixMode(GL_PROJECTION);                                              // Projekèní matice
      glLoadIdentity;                                                           // Reset projekèní matice
      gluPerspective(45.0,width / height,0.1,500.0);                            // Perspektivní projekce
      end;
    if loop = 3 then                                                            // Ètvrtá scéna
      begin
      glViewport(0,0,window_width div 2,window_height div 2);                   // Levý dolní viewport, velikost poloviny okna
      glMatrixMode(GL_PROJECTION);                                              // Projekèní matice
      glLoadIdentity;                                                           // Reset projekèní matice
      gluPerspective(45.0,width / height,0.1,500.0);                            // Perspektivní projekce
      end;
    glMatrixMode(GL_MODELVIEW);                                                 // Matice modelview
    glLoadIdentity;                                                             // Reset matice
    glClear(GL_DEPTH_BUFFER_BIT);                                               // Smaže hloubkový buffer
    if loop = 0 then                                                            // První scéna, bludištì pøes celý viewport
      begin
      glBegin(GL_QUADS);
        glTexCoord2f(1.0,0.0); glVertex2i(window_width div 2,0);
        glTexCoord2f(0.0,0.0); glVertex2i(0,0);
        glTexCoord2f(0.0,1.0); glVertex2i(0,window_height div 2);
        glTexCoord2f(1.0,1.0); glVertex2i(window_width div 2,window_height div 2);
      glEnd;
      end;
    if loop = 1 then                                                            // Druhá scéna, koule
      begin
      glTranslatef(0.0,0.0,-14.0);                                              // Pøesun do hloubky
      glRotatef(xrot,1.0,0.0,0.0);                                              // Rotace
      glRotatef(yrot,0.0,1.0,0.0);
      glRotatef(zrot,0.0,0.0,1.0);
      glEnable(GL_LIGHTING);                                                    // Zapne svìtlo
      gluSphere(quadric,4.0,32,32);                                             // Koule
      glDisable(GL_LIGHTING);                                                   // Vypne svìtlo
      end;
    if loop = 2 then                                                            // Tøetí scéna, bludištì na rovinì
      begin
      glTranslatef(0.0,0.0,-2.0);                                               // Pøesun do hloubky
      glRotatef(-45.0,1.0,0.0,0.0);                                             // Rotace o 45 stupòù
      glRotatef(zrot / 1.5,0.0,0.0,1.0);                                        // Rotace na ose z
      glBegin(GL_QUADS);
        glTexCoord2f(1.0,1.0); glVertex3f( 1.0, 1.0,0.0);
        glTexCoord2f(0.0,1.0); glVertex3f(-1.0, 1.0,0.0);
        glTexCoord2f(0.0,0.0); glVertex3f(-1.0,-1.0,0.0);
        glTexCoord2f(1.0,0.0); glVertex3f( 1.0,-1.0,0.0);
      glEnd;
      end;
    if loop = 3 then                                                            // Tøetí scéna, válec
      begin
      glTranslatef(0.0,0.0,-7.0);                                               // Pøesun do hloubky
      glRotatef(-xrot/2,1.0,0.0,0.0);                                           // Rotace
      glRotatef(-yrot/2,0.0,1.0,0.0);
      glRotatef(-zrot/2,0.0,0.0,1.0);
      glEnable(GL_LIGHTING);                                                    // Zapne svìtlo
      glTranslatef(0.0,0.0,-2.0);                                               // Vycentrování
      gluCylinder(quadric,1.5,1.5,4.0,32,16);                                   // Válec
      glDisable(GL_LIGHTING);                                                   // Vypne svìtlo
      end;
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
    init.title := 'Lesson 42: Multiple Viewports... 2003 NeHe Productions... Building Maze!';
    init.width := 1024;
    init.height := 768;
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

