program lesson19a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages,
  OpenGL, sysutils,
  GLaux;

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

type
  particles = record          // Vytvoøí stukturu pro èástici
    active: bool;             // Aktivní?
    life: glfloat;            // ivot
    fade: glfloat;            // Rychlost stárnutí
    r, g, b: glfloat;         // Sloky barvy
    x, y, z: glfloat;         // Pozice
    xi, yi, zi: glfloat;      // Smìr a rychlost
    xg, yg, zg: glfloat;      // Gravitace
    end;

const
  MAX_PARTICLES = 1000;      // Poèet vytváøenıch èástic

var
  h_Rc: HGLRC;		                  // Trvalı Rendering Context
  h_Dc: HDC;                        // Privátní GDI Device Context
  h_Wnd: HWND;                      // Obsahuje Handle našeho okna
  keys: array [0..255] of BOOL;	    // Pole pro ukládání vstupu z klávesnice
  Active: bool = true;              // Ponese informaci o tom, zda je okno aktivní
  FullScreen:bool = true;           // Ponese informaci o tom, zda je program ve fullscreenu
  rainbow: bool = true;             // Duhovı efekt?
  sp: bool;                         // Stisknutı mezerník?
  rp: bool;                         // Stisknutı enter?
  slowdown: GLfloat = 2.0;          // Zpomalení èástic
  xspeed, yspeed: GLfloat;          // Základní rychlost na osách
  zoom: GLfloat = -40.0;            // Zoom
  loop: gluint;                     // Øídící promìnná cyklù
  col: gluint;                      // Vybraná barva
  delay: gluint;                    // Zpodìní pro duhovı efekt
  texture: array [0..0] of gluint;  // Ukládá texturu
  particle: array [0..MAX_PARTICLES-1] of particles;    // Pole èástic
  colors: array [0..11,0..2] of glfloat = ((1.0,0.5,0.5),(1.0,0.75,0.5),(1.0,1.0,0.5),(0.75,1.0,0.5), // Barevná paleta
                                           (0.5,1.0,0.5),(0.5,1.0,0.75),(0.5,1.0,1.0),(0.5,0.75,1.0),
                                           (0.5,0.5,1.0),(0.75,0.5,1.0),(1.0,0.5,1.0),(1.0,0.5,0.75));

function LoadBMP(FileName: pchar):PTAUX_RGBImageRec;        // Nahraje bitmapu
begin
  if Filename = '' then                                     // Byla pøedána cesta k souboru?
    begin
    Result := nil;                                          // Pokud ne, konec
    exit;
    end;
  if not FileExists(Filename) then                          // Existuje soubor?
    begin
    Result := nil;                                          // Pokud ne, konec
    exit;
    end;
  Result := auxDIBImageLoadA(FileName);                     // Naète bitmapu a vrátí na ni ukazatel
end;

function LoadGLTextures: Bool;                              // Loading bitmapy a konverze na texturu
var TextureImage: array [0..0] of PTAUX_RGBImageRec;        // Ukládá bitmapu
    Status: Bool;                                           // Indikuje chyby
begin
  Status := false;
  ZeroMemory(@TextureImage,sizeof(TextureImage));           // Vynuluje pamì
  TextureImage[0] := LoadBMP('Data/Particle.bmp');          // Nahraje bitmapu
  if Assigned(TextureImage[0]) then                         // Vše je bez problémù?
    begin
    Status := true;                                         // Vše je bez problémù
    glGenTextures(1,Texture[0]);                            // Generuje texturu
    glBindTexture(GL_TEXTURE_2D,texture[0]);                // Typické vytváøení textury z bitmapy
    glTexImage2D(GL_TEXTURE_2D,0,3,TextureImage[0].sizeX,TextureImage[0].sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage[0].data);    // Vlastní vytváøení textury
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);   // Filtrování pøi zvìtšení
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);   // Filtrování pøi zmenšení
    end;
  Result := Status;                                         // Oznámí pøípadné chyby
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
begin
  if not LoadGLTextures then                        // Nahraje texturu
    begin
    Result := false;
    exit;
    end;
  glShadeModel(GL_SMOOTH);			                    // Povolí jemné stínování
  glClearColor(0.0, 0.0, 0.0, 0.0);	  	            // Èerné pozadí
  glClearDepth(1.0);				                        // Nastavení hloubkového bufferu
  glDisable(GL_DEPTH_TEST);                         // Vypne hloubkové testování
  glEnable(GL_BLEND);                               // Zapne blending
  glBlendFunc(GL_SRC_ALPHA,GL_ONE);                 // Typ blendingu
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST); // Perspektiva
  glHint(GL_POINT_SMOOTH_HINT,GL_NICEST);           // Jemnost bodù
  glEnable(GL_TEXTURE_2D);                          // Zapne mapování textur
  glBindTexture(GL_TEXTURE_2D,texture[0]);          // Vybere texturu
  for loop:=0 to MAX_PARTICLES-1 do                 // Inicializace èástic
    begin
    particle[loop].active := true;                                  // Aktivace
    particle[loop].life := 1.0;                                     // Oivení
    particle[loop].fade := Random(100)/1000 + 0.003;                // Rychlost stárnutí
    particle[loop].r := colors[Trunc(loop*(12/MAX_PARTICLES)),0];   // Èervená
    particle[loop].g := colors[Trunc(loop*(12/MAX_PARTICLES)),1];   // Zelená
    particle[loop].b := colors[Trunc(loop*(12/MAX_PARTICLES)),2];   // Modrá
    particle[loop].xi := (random(50)-26.0)*10.0;                    // Rychlost a smìr pohybu na ose x
    particle[loop].yi := (random(50)-25.0)*10.0;                    // Rychlost a smìr pohybu na ose y
    particle[loop].zi := (random(50)-25.0)*10.0;                    // Rychlost a smìr pohybu na ose z
    particle[loop].xg := 0.0;                                       // Gravitace na ose x
    particle[loop].yg := -0.8;                                      // Gravitace na ose y
    particle[loop].zg := 0.0;                                       // Gravitace na ose z
    end;
  Result:=true;                                     // Inicializace probìhla v poøádku
end;

function DrawGLScene():bool;                            // Vykreslování
var x,y,z: glfloat;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);  // Smae obrazovku a hloubkovı buffer
  glLoadIdentity();	                                    // Reset matice
  for loop:=0 to MAX_PARTICLES-1 do                     // Cyklus prochází kadou èástici
    begin
    if particle[loop].active then                       // Pokud je èástice aktivní
      begin
      x := particle[loop].x;                            // x pozice
      y := particle[loop].y;                            // y pozice
      z := particle[loop].z+zoom;                       // z pozice + zoom
      // Barva èástice
      glColor4f(particle[loop].r,particle[loop].g,particle[loop].b,particle[loop].life);
      glBegin(GL_TRIANGLE_STRIP);                       // Vytvoøí obdélník pomocí triangle strip
        glTexCoord2d(1,1); glVertex3f(x+0.5,y+0.5,z);   // Horní pravı
        glTexCoord2d(0,1); glVertex3f(x-0.5,y+0.5,z);   // Horní levı
        glTexCoord2d(1,0); glVertex3f(x+0.5,y-0.5,z);   // Dolní pravı
        glTexCoord2d(0,0); glVertex3f(x-0.5,y-0.5,z);   // Dolní levı
      glEnd;                                            // Ukonèí triangle strip
      particle[loop].x := particle[loop].x + particle[loop].xi/(slowdown*1000);   // Pohyb na ose x
      particle[loop].y := particle[loop].y + particle[loop].yi/(slowdown*1000);   // Pohyb na ose y
      particle[loop].z := particle[loop].z + particle[loop].zi/(slowdown*1000);   // Pohyb na ose z
      particle[loop].xi := particle[loop].xi + particle[loop].xg;                 // Gravitaèní pùsobení na ose x
      particle[loop].yi := particle[loop].yi + particle[loop].yg;                 // Gravitaèní pùsobení na ose y
      particle[loop].zi := particle[loop].zi + particle[loop].zg;                 // Gravitaèní pùsobení na ose z
      particle[loop].life := particle[loop].life - particle[loop].fade;           // Sníí ivot o stárnutí
      if (particle[loop].life < 0.0) then                         // Pokud zemøela
      begin
        particle[loop].life := 1.0;                               // Novı ivot
        particle[loop].fade := (random(100)/1000.0) + 0.003;      // Náhodné stárnutí
        particle[loop].x := 0.0;                                  // Vycentrování doprostøed obrazovky
        particle[loop].y := 0.0;                                  // Vycentrování doprostøed obrazovky
        particle[loop].z := 0.0;                                  // Vycentrování doprostøed obrazovky
        particle[loop].xi := xspeed + (random(60) - 32.0);        // Nová rychlost a smìr
        particle[loop].yi := yspeed + (random(60) - 30.0);        // Nová rychlost a smìr
        particle[loop].zi := (random(60) - 30.0);                 // Nová rychlost a smìr
        particle[loop].r := colors[col, 0];                       // Vybere barvu z palety
        particle[loop].g := colors[col, 1];                       // Vybere barvu z palety
        particle[loop].b := colors[col, 2];                       // Vybere barvu z palety
      end;
      // Pokud je stisknuta 8 a y gravitace je menší ne 1.5
      if (keys[VK_NUMPAD8] AND (particle[loop].yg < 1.5)) then particle[loop].yg := particle[loop].yg + 0.01;
      // Pokud je stisknuta 2 a y gravitace je menší ne -1.5
      if (keys[VK_NUMPAD2] AND (particle[loop].yg > -1.5)) then particle[loop].yg := particle[loop].yg - 0.01;
      // Pokud je stisknuta 6 a x gravitace je menší ne 1.5
      if (keys[VK_NUMPAD6] AND (particle[loop].xg < 1.5)) then particle[loop].xg := particle[loop].xg + 0.01;
      // Pokud je stisknuta 4 a x gravitace je menší ne -1.5
      if (keys[VK_NUMPAD4] AND (particle[loop].xg > -1.5)) then particle[loop].xg := particle[loop].xg - 0.01;
      if (keys[VK_TAB]) then                                      // Zpùsobí vıbuch
      begin
        particle[loop].x := 0.0;                                  // Vycentrování na støed obrazovky
        particle[loop].y := 0.0;                                  // Vycentrování na støed obrazovky
        particle[loop].z := 0.0;                                  // Vycentrování na støed obrazovky
        particle[loop].xi := (random(50)-26.0)*10.0;              // Náhodná rychlost
        particle[loop].yi := (random(50)-25.0)*10.0;              // Náhodná rychlost
        particle[loop].zi := (random(50)-25.0)*10.0;              // Náhodná rychlost
      end;
      end;
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
  if FullScreen then slowdown := 1.0;                 // Zrychlit ve fullscreenu
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
          if (keys[VK_ADD] and (slowdown > 1.0)) then slowdown := slowdown - 0.01;		  // Urychlení èástic
          if (keys[VK_SUBTRACT] and (slowdown < 4.0)) then slowdown := slowdown + 0.01;	// Zpomalení èástic
          if (keys[VK_PRIOR]) then zoom := zoom + 0.1;                                  // Pøiblíení pohledu
          if (keys[VK_NEXT]) then zoom := zoom - 0.1;                                   // Oddálení pohledu
          if (keys[VK_RETURN] and not(rp)) then                                         // Stisk enteru
            begin
            rp := true;                                                                 // Nastaví pøíznak
            rainbow := not(rainbow);                                                    // Zapne/vypne duhovı efekt
            end;
          if (not(keys[VK_RETURN])) then rp := false;                                   // Po uvolnìní vypne pøíznak
          if ((keys[ord(' ')] and not(sp)) or (rainbow and (delay > 25))) then          // Mezerník nebo duhovı efekt
            begin
            if (keys[ord(' ')]) then rainbow := false;                                  // Pokud je stisknut vypne se duhovı mód
            sp := true;                                                                 // Oznámí programu, e byl stisknut mezerník
            delay := 0;                                                                 // Resetuje zpodìní duhovıch barev
            col := col + 1;                                                             // Zmìní barvu èástice
            if (col > 11) then col := 0;                                                // Proti pøeteèení pole
            end;
          if (not(keys[ord(' ')])) then sp := false;                                    // Uvolnìní mezerníku
          if (keys[VK_UP] and (yspeed < 200)) then yspeed := yspeed + 1.0;              // Šipka nahoru
          if (keys[VK_DOWN] and (yspeed > -200)) then yspeed := yspeed - 1.0;           // Šipka dolù
          if (keys[VK_RIGHT] and (xspeed < 200)) then xspeed := xspeed + 1.0;           // Šipka doprava
          if (keys[VK_LEFT] and (xspeed > -200)) then xspeed := xspeed - 1.0;           // Šipka doleva
          delay := delay + 1;                                                           // Inkrementace zpodìní duhového efektu
        end;
    end;                                              // Konec smyèky while
  killGLwindow();                                     // Zavøe okno
  result:=msg.wParam;                                 // Ukonèení programu
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
end.

