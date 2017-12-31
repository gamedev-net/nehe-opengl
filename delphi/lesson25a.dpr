program lesson25a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages, sysutils,
  OpenGL;

type
  Vertex = record                   // Struktura pro bod ve 3D
    x, y, z: GLfloat;               // X, y, z sloky pozice
    end;

  Objekt = record                   // Struktura objektu
    verts: integer;                 // Poèet bodù, ze kterıch se skládá
    points: array of Vertex;        // Ukazatel do pole vertexù
    end;

var
  h_Rc: HGLRC;		                  // Trvalı Rendering Context
  h_Dc: HDC;                        // Privátní GDI Device Context
  h_Wnd: HWND;                      // Obsahuje Handle našeho okna
  keys: array [0..255] of BOOL;	    // Pole pro ukládání vstupu z klávesnice
  Active: bool = true;              // Ponese informaci o tom, zda je okno aktivní
  FullScreen:bool = true;           // Ponese informaci o tom, zda je program ve fullscreenu
  xrot, yrot, zrot: GLfloat;        // Rotace
  xspeed, yspeed, zspeed: GLfloat;  // Rychlost rotace
  cx, cy: GLfloat;                  // Pozice
  cz: GLfloat = -15;                // Pozice
  key: integer = 1;                 // Právì zobrazenı objekt
  morph: boolean = false;           // Probíhá právì morfování?
  steps: integer = 200;             // Poèet krokù zmìny
  step: integer = 0;                // Aktuální krok
  maxver: integer;                  // Eventuálnì ukládá maximální poèet bodù v jednom objektu
  morph1, morph2, morph3, morph4: Objekt; // Koule, toroid, válec (trubka), náhodné body
  helper, sour, dest: Objekt;       // Pomocnı, zdrojovı a cílovı objekt

function ObjAllocate(var k: Objekt; n: integer): boolean;   // Alokuje dynamickou pamì pro objekt
begin
  Result := true;
  try
  SetLength(k.points,n);                                    // Alokuje pamì
  except
    on EOutOfMemory do Result := false;                     // Pøi chybì vrací false
  end;
end;

procedure ObjFree(var k: Objekt);                           // Uvolní dynamickou pamì objektu
begin
  SetLength(k.points,0);                                    // Uvolní pamì
end;

procedure ReadStr(var f: textfile; var s: string);          // Naète jeden pouitelnı øádek ze souboru
begin
  readln(f,s);                                              // Naèti øádek
  while ((copy(s, 1, 1) = '/') or (length(s) = 0)) do       // Pokud není pouitelnı naèti další
    readln(f,s);
end;

function ObjLoad(name: string; var k: Objekt): boolean;     // Nahraje objekt ze souboru
var
  ver: integer;                                             // Poèet bodù
  rx, ry, rz: GLfloat;                                      // X, y, z pozice
  filein: TextFile;                                         // Soubor
  oneline: string;                                          // Znakovı buffer
  i: integer;                                               // Cyklus
begin
  AssignFile(filein,name);
  {$I-}
  Reset(filein);                                            // Otevøe soubor
  {$I+}
  if IOResult <> 0 then                                     // Podaøilo se soubor otevøít?
    begin
    Result := false;                                        // Konec
    exit;
    end;
  ReadStr(filein,oneline);                                  // Naète první øádku ze souboru
  Delete(oneline,1,10);                                     // Odstraní prvních 10 znakù "Vertices: "
  ver := StrToIntDef(oneline,0);                            // Poèet vertexù
  k.verts := ver;                                           // Nastaví poloku struktury na správnou hodnotu
  if not ObjAllocate(k,ver) then                            // Alokace pamìti pro objekt
    begin
    CloseFile(filein);                                      // Zavøe soubor
    Result := false;                                        // Konec
    exit;
    end;
  for i := 0 to ver - 1 do                                  // Postupnì naèítá body
    begin
      ReadStr(filein,oneline);                              // Naète øádek ze souboru
      rx := StrToFloat(Copy(oneline,1,6));                  // Najde a uloí tøi èísla
      ry := StrToFloat(Copy(oneline,10,8));
      rz := StrToFloat(Copy(oneline,19,Length(oneline)));
      k.points[i].x := rx;                                  // Nastaví vnitøní promìnnou struktury
      k.points[i].y := ry;                                  // Nastaví vnitøní promìnnou struktury
      k.points[i].z := rz;                                  // Nastaví vnitøní promìnnou struktury
    end;
  CloseFile(filein);                                        // Zavøe soubor
  if ver > maxver then maxver := ver;                       // Aktualizuje maximální poèet vertexù
  Result := true;
end;

function Calculate(i: integer): Vertex;                     // Spoèítá o kolik pohnout bodem pøi morfingu
var
  a: Vertex;                                                // Pomocnı bod
begin
  a.x := (sour.points[i].x - dest.points[i].x) / steps;     // Spoèítá posun
  a.y := (sour.points[i].y - dest.points[i].y) / steps;     // Spoèítá posun
  a.z := (sour.points[i].z - dest.points[i].z) / steps;     // Spoèítá posun
  Result := a;                                              // Vrátí vısledek
end;

procedure ReSizeGLScene(Width: GLsizei; Height: GLsizei); // Zmìna velikosti a inicializace OpenGL okna
begin
  if (Height=0) then		                                  // Zabezpeèení proti dìlení nulou
     Height:=1;                                           // Nastaví vıšku na jedna
  glViewport(0, 0, Width, Height);                        // Resetuje aktuální nastavení
  glMatrixMode(GL_PROJECTION);                            // Zvolí projekèní matici
  glLoadIdentity();                                       // Reset matice
  gluPerspective(45.0,Width/Height,0.1,100.0);            // Vıpoèet perspektivy
  glMatrixMode(GL_MODELVIEW);                             // Zvolí matici Modelview
  glLoadIdentity;                                         // Reset matice
end;

function InitGL:bool;	                              // Všechno nastavení OpenGL
var
  i: integer;                                       // Cyklus
begin
  glBlendFunc(GL_SRC_ALPHA, GL_ONE);                // Typ blendingu
  glClearColor(0.0, 0.0, 0.0, 0.0);	  	            // Èerné pozadí
  glClearDepth(1.0);				                        // Nastavení hloubkového bufferu
  glDepthFunc(GL_LESS); 				                    // Typ hloubkového testování
  glEnable(GL_DEPTH_TEST);			                    // Povolí hloubkové testování
  glShadeModel(GL_SMOOTH);			                    // Povolí jemné stínování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST); // Nejlepší perspektivní korekce
  maxver := 0;                                      // Nulování maximálního poètu bodù
  if not ObjLoad('Data/Sphere.txt', morph1) then    //Naète kouli?
    begin
    Result := false;                                // Konec
    exit;
    end;
  if not ObjLoad('Data/Torus.txt', morph2) then     // Naète toroid?
    begin
    Result := false;                                // Konec
    exit;
    end;
  if not ObjLoad('Data/Tube.txt', morph3) then      // Naète válec?
    begin
    Result := false;                                // Konec
    exit;
    end;
  if not ObjAllocate(morph4,486) then               // Alokace pamìti pro 486 bodù?
    begin
    Result := false;                                // Konec
    exit;
    end;
  for i := 0 to 485 do                              // Cyklus generuje náhodné souøadnice
    begin
    morph4.points[i].x := (Random(14000) / 1000) - 7;   // Náhodná hodnota
    morph4.points[i].y := (Random(14000) / 1000) - 7;   // Náhodná hodnota
    morph4.points[i].z := (Random(14000) / 1000) - 7;   // Náhodná hodnota
    end;
  if not ObjLoad('Data/Sphere.txt',helper) then     // Naètení koule do pomocného objektu
    begin
    Result := false;                                // Konec
    exit;
    end;
  sour := morph1;                                   // Inicializace ukazatelù na objekty
  dest := morph1;                                   // Inicializace ukazatelù na objekty
  Result:=true;                                     // Inicializace probìhla v poøádku
end;

function DrawGLScene():bool;                            // Vykreslování
var
  tx, ty, tz: GLfloat;                                  // Pomocné souøadnice
  q: Vertex;                                            // Pomocnı bod pro vıpoèty
  i: integer;                                           // Cyklus
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);  // Smae obrazovku a hloubkovı buffer
  glLoadIdentity();	                                    // Reset matice
  glTranslatef(cx,cy,cz);                               // Pøesun na pozici
  glRotatef(xrot,1.0,0.0,0.0);                          // Rotace na ose x
  glRotatef(yrot,0.0,1.0,0.0);                          // Rotace na ose y
  glRotatef(zrot,0.0,0.0,1.0);                          // Rotace na ose z
  xrot := xrot + xspeed;                                // Zvìtší úhly rotace
  yrot := yrot + yspeed;
  zrot := zrot + zspeed;
  glBegin(GL_POINTS);                                   // Zaèátek kreslení bodù
    for i := 0 to morph1.verts - 1 do                   // Cyklus prochází vertexy
      begin
      if morph then q := Calculate(i)                   // Pokud zrovna morfujeme, Spoèítáme hodnotu posunutí
        else                                            // Jinak
        begin
        q.x := 0;                                       // Budeme odeèítat nulu, ale tím neposouváme
        q.y := 0;
        q.z := 0;
        end;
      helper.points[i].x := helper.points[i].x - q.x;   // Posunutí na ose x
      helper.points[i].y := helper.points[i].y - q.y;   // Posunutí na ose y
      helper.points[i].z := helper.points[i].z - q.z;   // Posunutí na ose z
      tx := helper.points[i].x;                         // Zpøehlednìní + efekt
      ty := helper.points[i].y;                         // Zpøehlednìní + efekt
      tz := helper.points[i].z;                         // Zpøehlednìní + efekt
      glColor3f(0.0,1.0,1.0);                           // Zelenomodrá barva
      glVertex3f(tx,ty,tz);                             // Vykreslí první bod
      glColor3f(0.0,0.5,1.0);                           // Modøejší zelenomodrá barva
      tx := tx - 2 * q.x;                               // Spoèítání novıch pozic
      ty := ty - 2 * q.y;
      tz := tz - 2 * q.z;
      glVertex3f(tx,ty,tz);                             // Vykreslí druhı bod v nové pozici
      glColor3f(0.0,0.0,1.0);                           // Modrá barva
      tx := tx - 2 * q.x;                               // Spoèítání novıch pozic
      ty := ty - 2 * q.y;
      tz := tz - 2 * q.z;
      glVertex3f(tx,ty,tz);                             // Vykreslí tøetí bod v nové pozici
      end;
  glEnd;                                                // Ukonèí kreslení
  if morph and (step <= steps) then                     // Morfujeme a krok je menší ne maximum
    step := step + 1                                    // Pøíštì pokraèuj následujícím krokem
    else                                                // Nemorfujeme nebo byl právì ukonèen
    begin
    morph := false;                                     // Konec morfingu
    sour := dest;                                       // Cílovı objekt je nyní zdrojovı
    step := 0;                                          // První (nulovı) krok morfingu
    end;
  Result := true;                                       // Vykreslení probìhlo v poøádku
end;

function WndProc(hWnd: HWND;                            // Handle okna
                 message: UINT;                         // Zpráva pro okno
                 wParam: WPARAM;                        // Doplòkové informace
                 lParam: LPARAM):                       // Doplòkové informace
                                  LRESULT; stdcall;
begin
  if message=WM_SYSCOMMAND then                         // Systémovı pøíkaz
    begin
      case wParam of                                    // Typ systémového pøíkazu
        SC_SCREENSAVE,SC_MONITORPOWER:                  // Pokus o zapnutí šetøièe obrazovky, Pokus o pøechod do úsporného reimu?
          begin
            result:=0;                                  // Zabrání obojímu
            exit;
          end;
      end;
    end;
  case message of                                       // Vìtvení podle pøíchozí zprávy
    WM_ACTIVATE:                                        // Zmìna aktivity okna
      begin
        if (Hiword(wParam)=0) then                      // Zkontroluje zda není minimalizované
          active:=true                                  // Program je aktivní
        else
          active:=false;                                // Program není aktivní
        Result:=0;                                      // Návrat do hlavního cyklu programu
      end;
    WM_CLOSE:                                           // Povel k ukonèení programu
      Begin
        PostQuitMessage(0);                             // Pošle zprávu o ukonèení
        result:=0                                       // Návrat do hlavního cyklu programu
      end;
    WM_KEYDOWN:                                         // Stisk klávesy
      begin
        keys[wParam] := TRUE;                           // Oznámí to programu
        result:=0;                                      // Návrat do hlavního cyklu programu
      end;
    WM_KEYUP:                                           // Uvolnìní klávesy
      begin
    	keys[wParam] := FALSE;                            // Oznámí to programu
        result:=0;                                      // Návrat do hlavního cyklu programu
      end;
    WM_SIZe:                                            // Zmìna velikosti okna
      begin
    	ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));     // LoWord=Šíøka, HiWord=Vıška
        result:=0;                                      // Návrat do hlavního cyklu programu
      end
    else
      // Pøedání ostatních zpráv systému
      begin
      	Result := DefWindowProc(hWnd, message, wParam, lParam);
      end;
    end;
end;


procedure KillGLWindow;                                 // Zavírání okna
begin
  if FullScreen then                                    // Jsme ve fullscreenu?
    begin
      ChangeDisplaySettings(devmode(nil^),0);           // Pøepnutí do systému
      showcursor(true);                                 // Zobrazí kurzor myši
    end;
  if h_rc<> 0 then                                      // Máme rendering kontext?
    begin
      if (not wglMakeCurrent(h_Dc,0)) then              // Jsme schopni oddìlit kontexty?
        MessageBox(0,'Release of DC and RC failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
      if (not wglDeleteContext(h_Rc)) then              // Jsme schopni smazat RC?
        begin
          MessageBox(0,'Release of Rendering Context failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
          h_Rc:=0;                                      // Nastaví hRC na 0
        end;
    end;
  if (h_Dc=1) and (releaseDC(h_Wnd,h_Dc)<>0) then       // Jsme schopni uvolnit DC
    begin
      MessageBox(0,'Release of Device Context failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
      h_Dc:=0;                                          // Nastaví hDC na 0
    end;
  if (h_Wnd<>0) and (not destroywindow(h_Wnd))then      // Jsme schopni odstranit okno?
    begin
      MessageBox(0,'Could not release hWnd.',' Shutdown Error',MB_OK or MB_ICONERROR);
      h_Wnd:=0;                                         // Nastaví hWnd na 0
    end;
  if (not UnregisterClass('OpenGL',hInstance)) then     // Jsme schopni odregistrovat tøídu okna?
    begin
      MessageBox(0,'Could Not Unregister Class.','SHUTDOWN ERROR',MB_OK or MB_ICONINFORMATION);
    end;
  ObjFree(morph1);                                      // Uvolní alokovanou pamì
  ObjFree(morph2);                                      // Uvolní alokovanou pamì
  ObjFree(morph3);                                      // Uvolní alokovanou pamì
  ObjFree(morph4);                                      // Uvolní alokovanou pamì
  ObjFree(helper);                                      // Uvolní alokovanou pamì
  ObjFree(sour);                                        // Uvolní alokovanou pamì
  ObjFree(dest);                                        // Uvolní alokovanou pamì
end;


function CreateGlWindow(title:Pchar; width,height,bits:integer;FullScreenflag:bool):boolean stdcall;
var
  Pixelformat: GLuint;            // Ukládá formát pixelù
  wc:TWndclass;                   // Struktura Windows Class
  dwExStyle:dword;                // Rozšíøenı styl okna
  dwStyle:dword;                  // Styl okna
  pfd: pixelformatdescriptor;     // Nastavení formátu pixelù
  dmScreenSettings: Devmode;      // Mód zaøízení
  h_Instance:hinst;               // Instance okna
  WindowRect: TRect;              // Obdélník okna
begin
  WindowRect.Left := 0;                               // Nastaví levı okraj na nulu
  WindowRect.Top := 0;                                // Nastaví horní okraj na nulu
  WindowRect.Right := width;                          // Nastaví pravı okraj na zadanou hodnotu
  WindowRect.Bottom := height;                        // Nastaví spodní okraj na zadanou hodnotu
  h_instance:=GetModuleHandle(nil);                   // Získá instanci okna
  FullScreen:=FullScreenflag;                         // Nastaví promìnnou fullscreen na správnou hodnotu
  with wc do
    begin
      style:=CS_HREDRAW or CS_VREDRAW or CS_OWNDC;    // Pøekreslení pøi zmìnì velikosti a vlastní DC
      lpfnWndProc:=@WndProc;                          // Definuje proceduru okna
      cbClsExtra:=0;                                  // ádná extra data
      cbWndExtra:=0;                                  // ádná extra data
      hInstance:=h_Instance;                          // Instance
      hIcon:=LoadIcon(0,IDI_WINLOGO);                 // Standardní ikona
      hCursor:=LoadCursor(0,IDC_ARROW);               // Standardní kurzor myši
      hbrBackground:=0;                               // Pozadí není nutné
      lpszMenuName:=nil;                              // Nechceme menu
      lpszClassName:='OpenGl';                        // Jméno tøídy okna
    end;
  if  RegisterClass(wc)=0 then                        // Registruje tøídu okna
    begin
      MessageBox(0,'Failed To Register The Window Class.','Error',MB_OK or MB_ICONERROR);
      Result:=false;                                  // Pøi chybì vrátí false
      exit;
    end;
  if FullScreen then                                  // Budeme ve fullscreenu?
    begin
      ZeroMemory( @dmScreenSettings, sizeof(dmScreenSettings) );  // Vynulování pamìti
      with dmScreensettings do
        begin
          dmSize := sizeof(dmScreenSettings);         // Velikost struktury Devmode
          dmPelsWidth  := width;	                    // Šíøka okna
	        dmPelsHeight := height;                     // Vıška okna
          dmBitsPerPel := bits;                       // Barevná hloubka
          dmFields     := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
        end;
      // Pokusí se pouít právì definované nastavení
      if (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN))<>DISP_CHANGE_SUCCESSFUL THEN
        Begin
          // Nejde-li fullscreen, mùe uivatel spustit program v oknì nebo ho opustit
          if MessageBox(0,'This FullScreen Mode Is Not Supported. Use Windowed Mode Instead?'
                                             ,'NeHe GL',MB_YESNO or MB_ICONEXCLAMATION)= IDYES then
                FullScreen:=false                     // Bìh v oknì
          else
            begin
              // Zobrazí uivateli zprávu, e program bude ukonèen
              MessageBox(0,'Program Will Now Close.','Error',MB_OK or MB_ICONERROR);
              Result:=false;                          // Vrátí FALSE
              exit;
            end;
          end;
    end;
  if FullScreen then                                  // Jsme stále ve fullscreenu?
    begin
      dwExStyle:=WS_EX_APPWINDOW;                     // Rozšíøenı styl okna
      dwStyle:=WS_POPUP or WS_CLIPSIBLINGS or WS_CLIPCHILDREN; // Styl okna
      Showcursor(false);                              // Skryje kurzor
    end
  else
    begin
      dwExStyle:=WS_EX_APPWINDOW or WS_EX_WINDOWEDGE;   // Rozšíøenı styl okna
      dwStyle:=WS_OVERLAPPEDWINDOW or WS_CLIPSIBLINGS or WS_CLIPCHILDREN; // Styl okna
    end;
  AdjustWindowRectEx(WindowRect,dwStyle,false,dwExStyle); // Pøizpùsobení velikosti okna
  // Vytvoøení okna
  H_wnd:=CreateWindowEx(dwExStyle,                    // Rozšíøenı styl
                               'OpenGl',              // Jméno tøídy
                               Title,                 // Titulek
                               dwStyle,               // Definovanı styl
                               0,0,                   // Pozice
                               WindowRect.Right-WindowRect.Left,  // Vıpoèet šíøky
                               WindowRect.Bottom-WindowRect.Top,  // Vıpoèet vıšky
                               0,                     // ádné rodièovské okno
                               0,                     // Bez menu
                               hinstance,             // Instance
                               nil);                  // Nepøedat nic do WM_CREATE
  if h_Wnd=0 then                                     // Pokud se okno nepodaøilo vytvoøit
    begin
      KillGlWindow();                                 // Zruší okno
      MessageBox(0,'Window creation error.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Vrátí chybu
      exit;
    end;
  with pfd do                                         // Oznámíme Windows jak chceme vše nastavit
    begin
      nSize:= SizeOf( PIXELFORMATDESCRIPTOR );        // Velikost struktury
      nVersion:= 1;                                   // Èíslo verze
      dwFlags:= PFD_DRAW_TO_WINDOW                    // Podpora okna
        or PFD_SUPPORT_OPENGL                         // Podpora OpenGL
        or PFD_DOUBLEBUFFER;                          // Podpora Double Bufferingu
      iPixelType:= PFD_TYPE_RGBA;                     // RGBA Format
      cColorBits:= bits;                              // Zvolí barevnou hloubku
      cRedBits:= 0;                                   // Bity barev ignorovány
      cRedShift:= 0;
      cGreenBits:= 0;
      cBlueBits:= 0;
      cBlueShift:= 0;
      cAlphaBits:= 0;                                 // ádnı alpha buffer
      cAlphaShift:= 0;                                // Ignorován Shift bit
      cAccumBits:= 0;                                 // ádnı akumulaèní buffer
      cAccumRedBits:= 0;                              // Akumulaèní bity ignorovány
      cAccumGreenBits:= 0;
      cAccumBlueBits:= 0;
      cAccumAlphaBits:= 0;
      cDepthBits:= 16;                                // 16-bitovı hloubkovı buffer (Z-Buffer)
      cStencilBits:= 0;                               // ádnı Stencil Buffer
      cAuxBuffers:= 0;                                // ádnı Auxiliary Buffer
      iLayerType:= PFD_MAIN_PLANE;                    // Hlavní vykreslovací vrstva
      bReserved:= 0;                                  // Rezervováno
      dwLayerMask:= 0;                                // Maska vrstvy ignorována
      dwVisibleMask:= 0;
      dwDamageMask:= 0;
    end;
  h_Dc := GetDC(h_Wnd);                               // Zkusí pøipojit kontext zaøízení
  if h_Dc=0 then                                      // Podaøilo se pøipojit kontext zaøízení?
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'Cant''t create a GL device context.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  PixelFormat := ChoosePixelFormat(h_Dc, @pfd);       // Zkusí najít Pixel Format
  if (PixelFormat=0) then                             // Podaøilo se najít Pixel Format?
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'Cant''t Find A Suitable PixelFormat.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  if (not SetPixelFormat(h_Dc,PixelFormat,@pfd)) then  // Podaøilo se nastavit Pixel Format?
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'Cant''t set PixelFormat.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  h_Rc := wglCreateContext(h_Dc);                     // Podaøilo se vytvoøit Rendering Context?
  if (h_Rc=0) then
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'Cant''t create a GL rendering context.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  if (not wglMakeCurrent(h_Dc, h_Rc)) then            // Podaøilo se aktivovat Rendering Context?
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'Cant''t activate the GL rendering context.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  ShowWindow(h_Wnd,SW_SHOW);                          // Zobrazení okna
  SetForegroundWindow(h_Wnd);                         // Do popøedí
  SetFOcus(h_Wnd);                                    // Zamìøí fokus
  ReSizeGLScene(width,height);                        // Nastavení perspektivy OpenGL scény
  if (not InitGl()) then                              // Inicializace okna
    begin
      KillGLWindow();                                 // Zavøe okno
      MessageBox(0,'initialization failed.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Ukonèí program
      exit;
    end;
  Result:=true;                                       // Vše probìhlo v poøádku
end;


function WinMain(hInstance: HINST;                    // Instance
		 hPrevInstance: HINST;                            // Pøedchozí instance
		 lpCmdLine: PChar;                                // Parametry pøíkazové øádky
		 nCmdShow: integer):                              // Stav zobrazení okna
                        integer; stdcall;
var
  msg: TMsg;                                          // Struktura zpráv systému
  done: Bool;                                         // Promìnná pro ukonèení programu

begin
  done:=false;
  // Dotaz na uivatele pro fullscreen/okno
  if MessageBox(0,'Would You Like To Run In FullScreen Mode?','Start FullScreen',
                             MB_YESNO or MB_ICONQUESTION)=IDNO then
    FullScreen:=false                                 // Bìh v oknì
  else
    FullScreen:=true;                                 // Fullscreen
  if not CreateGLWindow('NeHe''s OpenGL Framework',640,480,16,FullScreen) then // Vytvoøení OpenGL okna
    begin
      Result := 0;                                    // Konec programu pøi chybì
      exit;
    end;
  while not done do                                   // Hlavní cyklus programu
    begin
      if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then  // Pøišla zpráva?
        begin
          if msg.message=WM_QUIT then                 // Obdreli jsme zprávu pro ukonèení?
            done:=true                                // Konec programu
          else
            begin
	          TranslateMessage(msg);                    // Pøeloí zprávu
	          DispatchMessage(msg);                     // Odešle zprávu
	        end;
        end
      else      // Pokud nedošla ádná zpráva
        begin
          // Je program aktivní, ale nelze kreslit? Byl stisknut ESC?
          if (active and not(DrawGLScene()) or keys[VK_ESCAPE]) then
            done:=true                                // Ukonèíme program
          else                                        // Pøekreslení scény
            SwapBuffers(h_Dc);                        // Prohození bufferù (Double Buffering)
          if keys[VK_F1] then                         // Byla stisknuta klávesa F1?
            begin
            Keys[VK_F1] := false;                     // Oznaè ji jako nestisknutou
            KillGLWindow();                           // Zruší okno
            FullScreen := not FullScreen;             // Negace fullscreen
            // Znovuvytvoøení okna
            if not CreateGLWindow('NeHe''s OpenGL Framework',640,480,16,fullscreen) then
              Result := 0;                            // Konec programu pokud nebylo vytvoøeno
            end;
          if keys[VK_PRIOR] then                      // PageUp?
            zspeed := zspeed + 0.01;                  
          if keys[VK_NEXT] then                       // PageDown?
            zspeed := zspeed - 0.01;                  
          if keys[VK_DOWN] then                       // Šipka dolu?
            xspeed := xspeed + 0.01;                  
          if keys[VK_UP] then                         // Šipka nahoru?
            xspeed := xspeed - 0.01;                  
          if keys[VK_RIGHT] then                      // Šipka doprava?
            yspeed := yspeed + 0.01;                  
          if keys[VK_LEFT] then                       // Šipka doleva?
            yspeed := yspeed - 0.01;                  
          if keys[Ord('Q')] then                      // Q?
            cz := cz + 0.01;                          // Dále
          if keys[Ord('Z')] then                      // Z?
            cz := cz - 0.01;                          // Blíe
          if keys[Ord('W')] then                      // W?
            cy := cy + 0.01;                          // Nahoru
          if keys[Ord('S')] then                      // S?
            cy := cy - 0.01;                          // Dolu
          if keys[Ord('D')] then                      // D?
            cx := cx + 0.01;                          // Doprava
          if keys[Ord('A')] then                      // A?
            cx := cx - 0.01;                          // Doleva
          if (keys[Ord('1')]) and (key <> 1) and not morph then   // Klávesa 1?
            begin
            key := 1;                                             // Proti dvojnásobnému stisku
            morph := true;                                        // Zaène morfovací proces
            dest := morph1;                                       // Nastaví cílovı objekt
            end;
          if (keys[Ord('2')]) and (key <> 2) and not morph then   // Klávesa 2?
            begin
            key := 2;                                             // Proti dvojnásobnému stisku
            morph := true;                                        // Zaène morfovací proces
            dest := morph2;                                       // Nastaví cílovı objekt
            end;
          if (keys[Ord('3')]) and (key <> 3) and not morph then   // Klávesa 3?
            begin
            key := 3;                                             // Proti dvojnásobnému stisku
            morph := true;                                        // Zaène morfovací proces
            dest := morph3;                                       // Nastaví cílovı objekt
            end;
          if (keys[Ord('4')]) and (key <> 4) and not morph then   // Klávesa 4?
            begin
            key := 4;                                             // Proti dvojnásobnému stisku
            morph := true;                                        // Zaène morfovací proces
            dest := morph4;                                       // Nastaví cílovı objekt
            end;
        end;
    end;                                              // Konec smyèky while
  killGLwindow();                                     // Zavøe okno
  result:=msg.wParam;                                 // Ukonèení programu
end;

begin
  DecimalSeparator := '.';                             // Oddìlovaè desetinnıch míst podle anglickıch zvyklostí
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
  DecimalSeparator := ',';                             // Oddìlovaè desetinnıch míst zpìt podle èeskıch zvyklostí
end.

