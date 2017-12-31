program lesson28a;

{   kód pro Delphi 7}

//******************************************************************************
// Poznámka:
// Do kódu jsem neimplementoval "fullscreen fix", protoe na mé grafické kartì
// GeForce4 Ti4800 to ádnı problém nedìlá :-))) Pokud by s tím mìl nìkdo problém
// nech si zkusí úpravu kódu jako domácí cvièení. Není to nic tekého ...
//******************************************************************************

uses
  Windows,
  Messages,
  OpenGL,sysutils,math,
  GLaux;

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

type
  Point_3D = record                                   // Struktura bodu
    x, y, z: Double;
    end;

  Bezier_patch = record                               // Struktura Bezierova povrchu
    anchors: array [0..3,0..3] of Point_3D;           // Møíka øídících bodù (4x4)
    dlBPatch: GLuint;                                 // Display list
    texture: GLuint;                                  // Textura
    end;

var
  h_Rc: HGLRC;		                  // Trvalı Rendering Context
  h_Dc: HDC;                        // Privátní GDI Device Context
  h_Wnd: HWND;                      // Obsahuje Handle našeho okna
  keys: array [0..255] of BOOL;	    // Pole pro ukládání vstupu z klávesnice
  Active: bool = true;              // Ponese informaci o tom, zda je okno aktivní
  FullScreen:bool = true;           // Ponese informaci o tom, zda je program ve fullscreenu
  mybezier: Bezier_patch;           // Bezierùv povrch
  rotz: GLfloat = 0.0;              // Rotace na ose z
  showCPoints: boolean = true;      // Flag pro zobrazení møíky mezi kontrolními body
  divs: integer = 7;                // Poèet interpolací (mnoství vykreslovanıch polygonù)

function pointAdd(p, q:  Point_3D):Point_3D;                // Sèítání dvou bodù
begin
  p.x := p.x + q.x;
  p.y := p.y + q.y;
  p.z := p.z + q.z;
  Result := p;
end;

function pointTimes(c: Double; p: Point_3D):Point_3D;       // Násobení bodu konstantou
begin
  p.x := p.x * c;
  p.y := p.y * c;
  p.z := p.z * c;
  Result := p;
end;

function makePoint(a, b, c: Double):Point_3D;               // Vytvoøení bodu ze tøí èísel
var p: Point_3D;
begin
  p.x := a;
  p.y := b;
  p.z := c;
  Result := p;
end;

function Bernstein(u: GLfloat; p: array of Point_3D):Point_3D;  // Spoèítá souøadnice bodu leícího na køivce
var a, b, c, d, r: Point_3D;                                    // Pomocné promìnné
begin
  a := pointTimes(Power(u,3),p[0]);                             // Vıpoèet podle vzorce
  b := pointTimes(3*Power(u,2)*(1-u),p[1]);
  c := pointTimes(3*Power((1-u),2)*u,p[2]);
  d := pointTimes(Power((1-u),3),p[3]);
  r := pointAdd(pointAdd(a,b),pointAdd(c,d));                   // Seètení násobkù a, b, c, d
  Result := r;                                                  // Vrácení vısledného bodu
end;

function genBezier(patch: Bezier_patch; divs: integer): GLuint; // Generuje display list Bezierova povrchu
var
  u, v: integer;                                                // Øídící promìnné
  px, py, pyold: GLfloat;                                       // Procentuální hodnoty
  drawList: GLuint;                                             // Display list
  temp: array [0..3] of Point_3D;                               // Øídící body pomocné køivky
  last: array of Point_3D;                                      // Poslední øada polygonù
begin
  drawList := glGenLists(1);                                    // Display list
  SetLength(last,divs+1);                                       // První øada polygonù
  if patch.dlBPatch <> 0 then glDeleteLists(patch.dlBPatch,1);  // Pokud existuje starı display list Smaeme ho
  temp[0] := patch.anchors[0,3];                                // První odvozená køivka (osa x)
  temp[1] := patch.anchors[1,3];
  temp[2] := patch.anchors[2,3];
  temp[3] := patch.anchors[3,3];
  for v := 0 to divs do                                         // Vytvoøí první øádek bodù
    begin
    px := v / divs;                                             // Px je procentuální hodnota v
    last[v] := Bernstein(px,temp);                              // Spoèítá bod na køivce ve vzdálenosti px
    end;
  glNewList(drawList,GL_COMPILE);                               // Novı display list
  glBindTexture(GL_TEXTURE_2D,patch.texture);                   // Zvolí texturu
  for u := 1 to divs do                                         // Prochází body na køivce
    begin
    py := u / divs;                                             // Py je procentuální hodnota u
    pyold := (u - 1) / divs;                                    // Pyold má hodnotu py pøi minulém prùchodu cyklem
    temp[0] := Bernstein(py, patch.anchors[0]);                 // Spoèítá Bezierovy body pro køivku
    temp[1] := Bernstein(py, patch.anchors[1]);
    temp[2] := Bernstein(py, patch.anchors[2]);
    temp[3] := Bernstein(py, patch.anchors[3]);
    glBegin(GL_TRIANGLE_STRIP);                                 // Zaèátek kreslení triangle stripu
      for v := 0 to divs do                                     // Prochází body na køivce
        begin
        px := v / divs;                                         // Px je procentuální hodnota v
        glTexCoord2f(pyold,px);                                 // Texturovací koordináty z minulého prùchodu
        glVertex3d(last[v].x,last[v].y,last[v].z);              // Bod z minulého prùchodu
        last[v] := Bernstein(px,temp);                          // Generuje novı bod
        glTexCoord2f(py,px);                                    // Nové texturové koordináty
        glVertex3d(last[v].x,last[v].y,last[v].z);              // Novı bod
        end;
    glEnd;                                                      // Konec triangle stripu
    end;
  glEndList;                                                    // Konec display listu
  last := nil;                                                  // Uvolní dynamické pole vertexù
  Result := drawList;                                           // Vrátí právì vytvoøenı display list
end;

procedure initBezier;                                       // Poèáteèní nastavení kontrolních bodù
begin
  mybezier.anchors[0,0] := makePoint(-0.75,-0.75,-0.5);
  mybezier.anchors[0,1] := makePoint(-0.25,-0.75, 0.0);
  mybezier.anchors[0,2] := makePoint( 0.25,-0.75, 0.0);
  mybezier.anchors[0,3] := makePoint( 0.75,-0.75,-0.5);
  mybezier.anchors[1,0] := makePoint(-0.75,-0.25,-0.75);
  mybezier.anchors[1,1] := makePoint(-0.25,-0.25, 0.5);
  mybezier.anchors[1,2] := makePoint( 0.25,-0.25, 0.5);
  mybezier.anchors[1,3] := makePoint( 0.75,-0.25,-0.75);
  mybezier.anchors[2,0] := makePoint(-0.75, 0.25, 0.0);
  mybezier.anchors[2,1] := makePoint(-0.25, 0.25,-0.5);
  mybezier.anchors[2,2] := makePoint( 0.25, 0.25,-0.5);
  mybezier.anchors[2,3] := makePoint( 0.75, 0.25, 0.0);
  mybezier.anchors[3,0] := makePoint(-0.75, 0.75,-0.5);
  mybezier.anchors[3,1] := makePoint(-0.25, 0.75,-1.0);
  mybezier.anchors[3,2] := makePoint( 0.25, 0.75,-1.0);
  mybezier.anchors[3,3] := makePoint( 0.75, 0.75,-0.5);
  mybezier.dlBPatch := 0;                                   // Display list ještì neexistuje
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

function LoadGLTextures: Bool;                              // Loading bitmapy a konverze na texturu
var TextureImage: array [0..0] of PTAUX_RGBImageRec;        // Ukládá bitmapu
    Status: Bool;                                           // Indikuje chyby
begin
  Status := false;
  ZeroMemory(@TextureImage,sizeof(TextureImage));           // Vynuluje pamì
  TextureImage[0] := LoadBMP('Data/NeHe.bmp');              // Nahraje bitmapu
  if Assigned(TextureImage[0]) then                         // Vše je bez problémù?
    begin
    Status := true;                                         // Vše je bez problémù
    glGenTextures(1,mybezier.texture);                      // Generuje texturu
    glBindTexture(GL_TEXTURE_2D,mybezier.texture);          // Typické vytváøení textury z bitmapy
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
  glEnable(GL_TEXTURE_2D);                          // Zapne mapování textur
  glShadeModel(GL_SMOOTH);			                    // Povolí jemné stínování
  glClearColor(0.0, 0.0, 0.0, 0.5);	  	            // Èerné pozadí
  glClearDepth(1.0);				                        // Nastavení hloubkového bufferu
  glEnable(GL_DEPTH_TEST);			                    // Povolí hloubkové testování
  glDepthFunc(GL_LEQUAL);				                    // Typ hloubkového testování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST); // Nejlepší perspektivní korekce
  initBezier;                                       // Inicializace kontrolních bodù
  mybezier.dlBPatch := genBezier(mybezier,divs);    // Generuje display list Bezierova povrchu
  Result:=true;                                     // Inicializace probìhla v poøádku
end;

function DrawGLScene():bool;                            // Vykreslování
var
  i, j: integer;                                        // Øídící promìnné cyklù
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);  // Smae obrazovku a hloubkovı buffer
  glLoadIdentity();	                                    // Reset matice
  glTranslatef(0.0,0.0,-4.0);                           // Pøesun do hloubky
  glRotatef(-75.0,1.0,0.0,0.0);                         // Rotace na ose x
  glRotatef(rotz,0.0,0.0,1.0);                          // Rotace na ose z
  glCallList(mybezier.dlBPatch);                        // Vykreslí display list Bezierova povrchu
  if showCPoints then                                   // Pokud je zapnuté vykreslování møíky
    begin
    glDisable(GL_TEXTURE_2D);                           // Vypne texturování
    glColor3f(1.0,0.0,0.0);                             // Èervená barva
    for i := 0 to 3 do                                  // Horizontální linky
      begin
      glBegin(GL_LINE_STRIP);                           // Kreslení linek
      for j := 0 to 3 do                                // Ètyøi linky
        glVertex3d(mybezier.anchors[i,j].x,mybezier.anchors[i,j].y,mybezier.anchors[i,j].z);
      glEnd;                                            // Konec kreslení
      end;
    for i := 0 to 3 do                                  // Vertikální linky
      begin
      glBegin(GL_LINE_STRIP);                           // Kreslení linek
      for j := 0 to 3 do                                // Ètyøi linky
        glVertex3d(mybezier.anchors[j,i].x,mybezier.anchors[j,i].y,mybezier.anchors[j,i].z);
      glEnd;                                            // Konec kreslení
      end;
    glColor3f(1.0,1.0,1.0);                             // Bílá barva
    glEnable(GL_TEXTURE_2D);                            // Zapne texturování
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
          if keys[VK_LEFT] then rotz := rotz - 0.8;             // Rotace doleva
          if keys[VK_RIGHT] then rotz := rotz + 0.8;            // Rotace doprava
          if keys[VK_UP] then                                   // Šipka nahoru
            begin
            divs := divs + 1;                                   // Menší hranatost povrchu
            mybezier.dlBPatch := genBezier(mybezier,divs);      // Aktualizace display listu
            keys[VK_UP] := false;
            end;
          if keys[VK_DOWN] and (divs > 1) then                  // Šipka dolù
            begin
            divs := divs - 1;                                   // Vìtší hranatost povrchu
            mybezier.dlBPatch := genBezier(mybezier,divs);      // Aktualizace display listu
            keys[VK_DOWN] := false;
            end;
          if keys[VK_SPACE] then                                // Mezerník
            begin
            showCPoints := not showCPoints;                     // Zobrazí/skryje linky mezi øídícími body
            keys[VK_SPACE] := false;
            end;
        end;
    end;                                              // Konec smyèky while
  killGLwindow();                                     // Zavøe okno
  result:=msg.wParam;                                 // Ukonèení programu
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
end.

