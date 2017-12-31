program lesson10a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages,
  OpenGL, sysutils,
  GLaux;

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

type
  vertex = record                       // Struktura bodu
    x,y,z: GLfloat;                     // Souøadnice v prostoru
    u,v: GLfloat;                       // Texturové koordináty
    end;
  triangle = record                     // Struktura trojúhelníku
    vertex: array [0..3] of vertex;     // Pole tøí bodù
    end;
  sector = record                       // Struktura sektoru
    numtriangles: integer;              // Poèet trojúhelníkù v sektoru
    triangle: array of triangle;        // Ukazatel na dynamické pole trojúhelníkù
    end;

const
  piover180 = 0.0174532925;             // Zjednoduší pøevod mezi stupni a radiány
  worldfile = 'world.txt';              // Soubor s informacemi o svìtì

var
  h_Rc: HGLRC;		                  // Trvalı Rendering Context
  h_Dc: HDC;                        // Privátní GDI Device Context
  h_Wnd: HWND;                      // Obsahuje Handle našeho okna
  keys: array [0..255] of BOOL;	    // Pole pro ukládání vstupu z klávesnice
  Active: bool = true;              // Ponese informaci o tom, zda je okno aktivní
  FullScreen:bool = true;           // Ponese informaci o tom, zda je program ve fullscreenu
  blend: bool;                      // Blending ON/OFF
  bp: bool;                         // B stisknuto? (blending)
  fp: bool;                         // F stisknuto? (texturové filtry)
  heading: GLfloat;                 // Pomocná pro pøepoèítávání xpos a zpos pøi pohybu
  xpos: GLfloat;                    // Urèuje x-ové souøadnice na podlaze
  zpos: GLfloat;                    // Urèuje z-ové souøadnice na podlaze
  yrot: GLfloat;                    // Y rotace (natoèení scény doleva/doprava - smìr pohledu)
  walkbias: GLfloat = 0;            // Houpání scény pøi pohybu (simulace krokù)
  walkbiasangle: GLfloat = 0;       // Pomocná pro vypoèítání walkbias
  lookupdown: GLfloat = 0;          // Urèuje úhel natoèení pohledu nahoru/dolù
  filter: GLuint;                   // Pouitı texturovı filtr
  texture: array [0..2] of GLuint;  // Ukládá textury
  sector1: sector;                  // Bude obsahovat všechna data 3D svìta

procedure ReadStr(var f: textfile; var s: string);        // Naète jeden pouitelnı øádek ze souboru
begin
  readln(f,s);                                            // Naèti øádek
  while ((copy(s, 1, 1) = '/') or (length(s) = 0)) do     // Pokud není pouitelnı naèti další
    readln(f,s);
end;

procedure SetupWorld;                                     // Naèti 3D svìt ze souboru
var
  x,y,z,u,v: GLfloat;                                     // body v prostoru a koordináty textur
  numtriangles: integer;                                  // Poèet trojúhelníkù
  filein: textfile;                                       // Ukazatel na soubor
  oneline: string;                                        // Znakovı buffer
  loop,vert: integer;                                     // cykly
begin
  //*************************************************************************************************
  //                                 UPOZORNÌNÍ!!!!!!!!
  // Soubor world.txt není stejnı jako u originálního tutoriálu. Upravil jsem jeho strukturu
  // z dùvodu snazšího naèítání dat.
  //*************************************************************************************************
  AssignFile(filein,worldfile);
  Reset(filein);                                          // Otevøení souboru pro ètení
  Readstr(filein,oneline);                                // Naètení prvního pouitelného øádku
  Delete(oneline,1,11);
  numtriangles := StrToIntDef(oneline,0);                 // Vyjmeme poèet trojúhelníkù
  SetLength(sector1.triangle,numtriangles);               // Alokace potøebné pamìti
  sector1.numtriangles := numtriangles;                   // Uloení poètu trojúhelníkù
  for loop := 0 to numtriangles - 1 do                    // Prochází trojúhelníky
    for vert := 0 to 2 do                                 // Prochází vrcholy trojúhelníkù
      begin
      Readstr(filein,oneline);                            // Naète øádek
      x := StrToFloat(Copy(oneline,1,4));                 // Naètení do pomocnıch promìnnıch
      y := StrToFloat(Copy(oneline,5,4));
      z := StrToFloat(Copy(oneline,9,4));
      u := StrToFloat(Copy(oneline,13,4));
      v := StrToFloat(Copy(oneline,17,4));
      sector1.triangle[loop].vertex[vert].x := x;         // Inicializuje jednotlivé poloky struktury
      sector1.triangle[loop].vertex[vert].y := y;
      sector1.triangle[loop].vertex[vert].z := z;
      sector1.triangle[loop].vertex[vert].u := u;
      sector1.triangle[loop].vertex[vert].v := v;
      end;
  CloseFile(filein);                                      // Zavøe soubor
end;

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

function LoadGLTextures: Bool;                                        // Loading bitmapy a konverze na texturu
var TextureImage: PTAUX_RGBImageRec;                                  // Ukládá bitmapu
    Status: Bool;                                                     // Indikuje chyby
begin
  Status := false;
  ZeroMemory(TextureImage,sizeof(TextureImage));                      // Vynuluje pamì
  TextureImage := LoadBMP('Data/mud.bmp');                            // Nahraje bitmapu
  if Assigned(TextureImage) then
    begin
    Status := true;                                                   // Vše je bez problémù
    glGenTextures(3,texture[0]);                                      // Generuje tøi textury
    // Vytvoøí nelineárnì filtrovanou texturu
    glBindTexture(GL_TEXTURE_2D,texture[0]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D,0,3,TextureImage.sizeX,TextureImage.sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage.data);
    // Vytvoøí lineárnì filtrovanou texturu
    glBindTexture(GL_TEXTURE_2D,texture[1]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D,0,3,TextureImage.sizeX,TextureImage.sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage.data);
    // Vytvoøí mipmapovanou texturu
    glBindTexture(GL_TEXTURE_2D,texture[2]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
    gluBuild2DMipmaps(GL_TEXTURE_2D,3,TextureImage.sizeX,TextureImage.sizeY,GL_RGB,GL_UNSIGNED_BYTE,TextureImage.data);
    end;
  Result := Status;                                                   // Oznámí pøípadné chyby
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
  decimalseparator := '.';                          // Nastaví oddìlovaè desetinnıch míst podle anglickıch zvyklostí - nutné pro správné naèítání koordinátù ze souboru
  if not LoadGLTextures then                        // Nahraje texturu
    begin
    Result := false;
    exit;
    end;
  glEnable(GL_TEXTURE_2D);                          // Zapne mapování textur
  glShadeModel(GL_SMOOTH);			                    // Povolí jemné stínování
  glBlendFunc(GL_SRC_ALPHA,GL_ONE);                 // Nastavení blendingu pro prùhlednost
  glClearColor(0.0, 0.0, 0.0, 0.0);	  	            // Èerné pozadí
  glClearDepth(1.0);				                        // Nastavení hloubkového bufferu
  glEnable(GL_DEPTH_TEST);			                    // Povolí hloubkové testování
  glDepthFunc(GL_LESS);				                      // Typ hloubkového testování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST); // Nejlepší perspektivní korekce
  SetupWorld;                                       // Loading 3D svìta
  Result:=true;                                     // Inicializace probìhla v poøádku
end;


function DrawGLScene():bool;                            // Vykreslování
var
  x_m, y_m, z_m, u_m, v_m: GLfloat;                     // Pomocné souøadnice a koordináty textury
  xtrans, ztrans, ytrans: GLfloat;                      // Pro pohyb na ose
  sceneroty: GLfloat;                                   // Úhel smìru pohledu
  numtriangles: integer;                                // Poèet trojúhelníkù
  loop_m: integer;                                      // Cyklus
begin
  xtrans := -xpos;
  ztrans := -zpos;
  ytrans := -walkbias-0.25;
  sceneroty := 360 - yrot;
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);  // Smae obrazovku a hloubkovı buffer
  glLoadIdentity();	                                    // Reset matice
  glRotatef(lookupdown, 1.0,0.0,0.0);                   // Rotace na ose x - pohled nahoru/dolù
  glRotatef(sceneroty, 0.0,1.0,0.0);                    // Rotace na ose y - otoèení doleva/doprava
  glTranslatef(xtrans, ytrans, ztrans);                 // Posun na pozici ve scénì
  glBindTexture(GL_TEXTURE_2D, texture[filter]);        // Vıbìr textury podle filtru
  numtriangles := sector1.numtriangles;                 // Poèet trojúhelníkù - pro pøehlednost
  for loop_m := 0 to numtriangles - 1 do                // Projde a vykreslí všechny trojúhelníky
  begin
    glBegin(GL_TRIANGLES);                              // Zaèátek kreslení trojúhelníkù
      glNormal3f( 0.0, 0.0, 1.0);                       // Normála ukazuje dopøedu - svìtlo
      x_m := sector1.triangle[loop_m].vertex[0].x;      // První vrchol
      y_m := sector1.triangle[loop_m].vertex[0].y;
      z_m := sector1.triangle[loop_m].vertex[0].z;
      u_m := sector1.triangle[loop_m].vertex[0].u;
      v_m := sector1.triangle[loop_m].vertex[0].v;
      glTexCoord2f(u_m,v_m); glVertex3f(x_m,y_m,z_m);   // Vykreslení

      x_m := sector1.triangle[loop_m].vertex[1].x;      // Druhı vrchol
      y_m := sector1.triangle[loop_m].vertex[1].y;
      z_m := sector1.triangle[loop_m].vertex[1].z;
      u_m := sector1.triangle[loop_m].vertex[1].u;
      v_m := sector1.triangle[loop_m].vertex[1].v;
      glTexCoord2f(u_m,v_m); glVertex3f(x_m,y_m,z_m);   // Vykreslení

      x_m := sector1.triangle[loop_m].vertex[2].x;      // Tøetí vrchol
      y_m := sector1.triangle[loop_m].vertex[2].y;
      z_m := sector1.triangle[loop_m].vertex[2].z;
      u_m := sector1.triangle[loop_m].vertex[2].u;
      v_m := sector1.triangle[loop_m].vertex[2].v;
      glTexCoord2f(u_m,v_m); glVertex3f(x_m,y_m,z_m);   // Vykreslení
    glEnd();                                            // Konec kreslení trojúhelníkù
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
  decimalseparator := ',';                              // Nastaví zpìt oddìlovaè desetinnıch míst podle našich zvyklostí
  sector1.triangle := nil;                              // Uvolnìní pole trojúhelníkù
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
          if (keys[ord('B')] and not bp) then
            begin
            bp := TRUE;
            blend := not(blend);
            if (blend) then
              begin
              glEnable(GL_BLEND);			                // Klávesa B - zapne/vypne blending
              glBlendFunc(GL_SRC_ALPHA,GL_ONE);
              glDisable(GL_DEPTH_TEST);
              end
              else
              begin
              glDisable(GL_BLEND);
              glEnable(GL_DEPTH_TEST);
              end;
            end;
          if (not keys[ord('B')]) then bp := False;
          if (keys[ord('F')] and not fp) then         // Klávesa F - cyklování mezi texturovımi filtry
            begin
            fp := True;
            Filter := Filter + 1;
            if (Filter > 2) then Filter := 0;
            end;
          if (not keys[ord('F')]) then fp:=FALSE;
          if (keys[VK_UP]) then                                     // Šipka nahoru - pohyb dopøedu
            begin
            xpos := xpos - sin(heading*piover180) * 0.05;           // Pohyb na ose x
            zpos := zpos - cos(heading*piover180) * 0.05;           // Pohyb na ose z
            if (walkbiasangle >= 359.0) then walkbiasangle := 0.0
              else walkbiasangle := walkbiasangle + 10;
            walkbias := sin(walkbiasangle * piover180)/20.0;        // Simulace krokù
            end;
          if (keys[VK_DOWN]) then                                   // Šipka dolù - pohyb dozadu
            begin
            xpos := xpos + sin(heading*piover180) * 0.05;           // Pohyb na ose x
            zpos := zpos + cos(heading*piover180) * 0.05;           // Pohyb na ose z
            if (walkbiasangle <= 1.0) then walkbiasangle := 359.0
              else walkbiasangle := walkbiasangle - 10;
            walkbias := sin(walkbiasangle * piover180)/20.0;        // Simulace krokù
            end;
          if (keys[VK_RIGHT]) then                                  // Šipka doprava
            begin
            heading := heading - 1.0;                               // Natoèení scény
            yrot := heading;
            end;
          if (keys[VK_LEFT]) then                                   // Šipka doleva
            begin
            heading := heading + 1.0;                               // Natoèení scény
            yrot := heading;
            end;
          if (keys[VK_PRIOR]) then lookupdown := lookupdown - 1.0;  // Page Up
          if (keys[VK_NEXT]) then lookupdown := lookupdown + 1.0;   // Page Down
        end;
    end;                                              // Konec smyèky while
  killGLwindow();                                     // Zavøe okno
  result:=msg.wParam;                                 // Ukonèení programu
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
end.

