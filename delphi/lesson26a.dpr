program lesson26a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages,
  OpenGL,sysutils,
  GLaux;

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

const // Parametry svìtla
  LightAmb: array [0..3] of GLFloat = (0.7,0.7,0.7,1.0);    // Okolní
  LightDif: array [0..3] of GLFloat = (1.0,1.0,1.0,1.0);    // Rozptılené
  LightPos: array [0..3] of GLFloat = (4.0,4.0,6.0,1.0);    // Pozice

var
  h_Rc: HGLRC;		                  // Trvalı Rendering Context
  h_Dc: HDC;                        // Privátní GDI Device Context
  h_Wnd: HWND;                      // Obsahuje Handle našeho okna
  keys: array [0..255] of BOOL;	    // Pole pro ukládání vstupu z klávesnice
  Active: bool = true;              // Ponese informaci o tom, zda je okno aktivní
  FullScreen:bool = true;           // Ponese informaci o tom, zda je program ve fullscreenu
  q: GLUquadricObj;                 // Quadratic pro kreslení koule (míèe)
  xrot: GLFloat = 0;                // Rotace v ose x
  yrot: GLFloat = 0;                // Rotace v ose y
  xrotspeed: GLfloat = 0;           // Rychlost x rotace
  yrotspeed: GLfloat = 0;           // Rychlost y rotace
  zoom: GLfloat = -7.0;             // Hloubka v obrazovce
  height: GLfloat = 2.0;            // Vıška míèe nad scénou
  texture: array [0..2] of GLuint;  // 3 textury

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
var TextureImage: array [0..2] of PTAUX_RGBImageRec;        // Ukládá bitmapy
    Status: Bool;                                           // Indikuje chyby
    i: integer;                                             // Cyklus
begin
  Status := false;
  ZeroMemory(@TextureImage,sizeof(TextureImage));           // Vynuluje pamì
  TextureImage[0] := LoadBMP('Data/EnvWall.bmp');           // Nahraje bitmapu
  TextureImage[1] := LoadBMP('Data/Ball.bmp');              // Nahraje bitmapu
  TextureImage[2] := LoadBMP('Data/EnvRoll.bmp');           // Nahraje bitmapu
  if Assigned(TextureImage[0]) and Assigned(TextureImage[1])
    and Assigned(TextureImage[2]) then                      // Vše je bez problémù?
    begin
    Status := true;                                         // Vše je bez problémù
    glGenTextures(3,Texture[0]);                            // Generuje textury
    for i := 0 to 2 do
      begin
      glBindTexture(GL_TEXTURE_2D,texture[i]);                // Typické vytváøení textury z bitmapy
      glTexImage2D(GL_TEXTURE_2D,0,3,TextureImage[i].sizeX,TextureImage[i].sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage[i].data);    // Vlastní vytváøení textury
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);   // Filtrování pøi zvìtšení
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);   // Filtrování pøi zmenšení
      end;
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
  glClearColor(0.2, 0.5, 1.0, 1.0);	  	            // Svìtle modré pozadí
  glClearDepth(1.0);				                        // Nastavení hloubkového bufferu
  glClearStencil(0);                                // Nastavení mazání stencil bufferu
  glEnable(GL_DEPTH_TEST);			                    // Povolí hloubkové testování
  glDepthFunc(GL_LEQUAL);				                    // Typ hloubkového testování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST); // Nejlepší perspektivní korekce
  glEnable(GL_TEXTURE_2D);                          // Zapne mapování textur
  glLightfv(GL_LIGHT0,GL_AMBIENT,@LightAmb);        // Okolní
  glLightfv(GL_LIGHT0,GL_DIFFUSE,@LightDif);        // Rozptylové
  glLightfv(GL_LIGHT0,GL_POSITION,@LightPos);       // Pozice
  glEnable(GL_LIGHT0);                              // Povolí svìtlo 0
  glEnable(GL_LIGHTING);                            // Povolí svìtla
  q := gluNewQuadric;                               // Novı quadratic
  gluQuadricNormals(q,GL_SMOOTH);                   // Normály pro svìtlo
  gluQuadricTexture(q,GL_TRUE);                     // Texturové koordináty
  glTexGeni(GL_S,GL_TEXTURE_GEN_MODE,GL_SPHERE_MAP);// Automatické mapování textur
  glTexGeni(GL_T,GL_TEXTURE_GEN_MODE,GL_SPHERE_MAP);// Automatické mapování textur
  Result:=true;                                     // Inicializace probìhla v poøádku
end;

procedure DrawObject;                               // Vykreslí pláovı míè
begin
  glColor3f(1.0,1.0,1.0);                           // Bílá barva
  glBindTexture(GL_TEXTURE_2D,texture[1]);          // Zvolí texturu míèe
  gluSphere(q,0.35,32,16);                          // Nakreslí kouli
  glBindTexture(GL_TEXTURE_2D,texture[2]);          // Zvolí texturu svìtla
  glColor4f(1.0,1.0,1.0,0.4);                       // Bílá barva s 40% alfou
  glEnable(GL_BLEND);                               // Zapne blending
  glBlendFunc(GL_SRC_ALPHA,GL_ONE);                 // Mód blendingu
  glEnable(GL_TEXTURE_GEN_S);                       // Zapne kulové mapování
  glEnable(GL_TEXTURE_GEN_T);                       // Zapne kulové mapování
  gluSphere(q,0.35,32,16);                          // Stejná koule jako pøed chvílí
  glDisable(GL_TEXTURE_GEN_S);                      // Vypne kulové mapování
  glDisable(GL_TEXTURE_GEN_T);                      // Vypne kulové mapování
  glDisable(GL_BLEND);                              // Vepne blending
end;

procedure DrawFloor;                                // Vykreslí podlahu
begin
  glBindTexture(GL_TEXTURE_2D,texture[0]);          // Zvolí texturu podlahy
  glBegin(GL_QUADS);                                // Kreslení obdélníkù
    glNormal3f(0.0, 1.0, 0.0);                      // Normálovı vektor míøí vzhùru
    glTexCoord2f(0.0, 1.0);                         // Levı dolní bod textury
    glVertex3f(-2.0, 0.0, 2.0);                     // Levı dolní bod podlahy
    glTexCoord2f(0.0, 0.0);                         // Levı horní bod textury
    glVertex3f(-2.0, 0.0,-2.0);                     // Levı horní bod podlahy
    glTexCoord2f(1.0, 0.0);                         // Pravı horní bod textury
    glVertex3f( 2.0, 0.0,-2.0);                     // Pravı horní bod podlahy
    glTexCoord2f(1.0, 1.0);                         // Pravı dolní bod textury
    glVertex3f( 2.0, 0.0, 2.0);                     // Pravı dolní bod podlahy
  glEnd();                                          // Konec kreslení
end;

function DrawGLScene():bool;                            // Vykreslování
var
  eqr: array [0..3] of Double;                          // Pouito pro odraenı objekt
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
          or GL_STENCIL_BUFFER_BIT);                    // Smae obrazovku, hloubkovı buffer a stencil buffer
  eqr[0] := 0.0;                                        // Rovnice oøezávací plochy
  eqr[1] := -1.0;
  eqr[2] := 0.0;
  eqr[3] := 0.0;
  glLoadIdentity();	                                    // Reset matice
  glTranslatef(0.0,-0.6,zoom);                          // Zoom a vyvıšení kamery nad podlahu
  glColorMask(GL_FALSE,GL_FALSE,GL_FALSE,GL_FALSE);     // Nastaví masku barev, aby se nic nezobrazilo
  glEnable(GL_STENCIL_TEST);                            // Zapne stencil buffer pro pamìovı obraz podlahy
  glStencilFunc(GL_ALWAYS,1,1);                         // Pokadé probìhne, reference, maska
  glStencilOp(GL_KEEP,GL_KEEP,GL_REPLACE);              // Vykreslením nastavíme konkrétní bit ve stencil bufferu na 1
  glDisable(GL_DEPTH_TEST);                             // Vypne testování hloubky
  DrawFloor;                                            // Vykreslí podlahu (do stencil bufferu ne na scénu)
  glEnable(GL_DEPTH_TEST);                              // Zapne testování hloubky
  glColorMask(GL_TRUE,GL_TRUE,GL_TRUE,GL_TRUE);         // Povolí zobrazování barev
  glStencilFunc(GL_EQUAL,1,1);                          // Zobrazí se pouze pixely na jednièkách ve stencil bufferu (podlaha)
  glStencilOp(GL_KEEP,GL_KEEP,GL_KEEP);                 // Nemìnit obsah stencil bufferu
  glEnable(GL_CLIP_PLANE0);                             // Zapne oøezávací testy pro odraz
  glClipPlane(GL_CLIP_PLANE0,@eqr);                      // Rovnice oøezávací roviny
  glPushMatrix;                                         // Záloha matice
    glScalef(1.0,-1.0,1.0);                             // Zrcadlení smìru osy y
    glLightfv(GL_LIGHT0,GL_POSITION,@LightPos);         // Umístìní svìtla
    glTranslatef(0.0,height,0.0);                       // Umístìní míèe
    glRotatef(xrot,1.0,0.0,0.0);                        // Rotace na ose x
    glRotatef(yrot,0.0,1.0,0.0);                        // Rotace na ose y
    DrawObject;                                         // Vykreslí míè (odraz)
  glPopMatrix;                                          // Obnoví matici
  glDisable(GL_CLIP_PLANE0);                            // Vypne oøezávací rovinu
  glDisable(GL_STENCIL_TEST);                           // U nebudeme potøebovat stencil testy
  glLightfv(GL_LIGHT0,GL_POSITION,@LightPos);           // Umístìní svìtla
  glEnable(GL_BLEND);                                   // Zapne blending, jinak by se odraz míèe nezobrazil
  glDisable(GL_LIGHTING);                               // Kvùli blendingu vypneme svìtla
  glColor4f(1.0,1.0,1.0,0.8);                           // Bílá barva s 80% prùhledností
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);     // Funkce na bázi alfy zdroje a jedna mínus alfy cíle
  DrawFloor;                                            // Vykreslí podlahu
  glEnable(GL_LIGHTING);                                // Zapne svìtla
  glDisable(GL_BLEND);                                  // Vypne blending
  glTranslatef(0.0,height,0.0);                         // Umístìní míèe
  glRotatef(xrot,1.0,0.0,0.0);                          // Rotace na ose x
  glRotatef(yrot,0.0,1.0,0.0);                          // Rotace na ose y
  DrawObject;                                           // Vykreslí míè
  xrot := xrot + xrotspeed;                             // Zvìtší natoèení
  yrot := yrot + yrotspeed;                             // Zvìtší natoèení
  glFlush;                                              // Vyprázdní pipeline
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
      cStencilBits:= 1;                               // Stencil buffer (DÙLEITÉ)
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

procedure ProcessKeyboard;                                // Ovládání klávesnicí
begin
  if keys[VK_RIGHT] then yrotspeed := yrotspeed + 0.08;   // Šipka vpravo zvıší rychlost y rotace
  if keys[VK_LEFT] then yrotspeed := yrotspeed - 0.08;    // Šipka vlevo sníí rychlost y rotace
  if keys[VK_DOWN] then xrotspeed := xrotspeed + 0.08;    // Šipka dolù zvıší rychlost x rotace
  if keys[VK_UP] then xrotspeed := xrotspeed - 0.08;      // Šipka nahoru sníí rychlost x rotace
  if keys[Ord('A')] then zoom := zoom + 0.05;             // A pøiblíí scénu
  if keys[Ord('Z')] then zoom := zoom - 0.05;             // Z oddálí scénu
  if keys[VK_PRIOR] then height := height + 0.03;         // Page Up zvìtší vzdálenost míèe nad podlahou
  if keys[VK_NEXT] then height := height - 0.03;          // Page Down zmenší vzdálenost míèe nad podlahou
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
          ProcessKeyboard;                            // Vstup z klávesnice
        end;
    end;                                              // Konec smyèky while
  killGLwindow();                                     // Zavøe okno
  result:=msg.wParam;                                 // Ukonèení programu
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
end.

