program lesson16a;

{   kÛd pro Delphi 7}

uses
  Windows,
  Messages,
  OpenGL, sysutils,
  GLaux;

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

var
  h_Rc: HGLRC;		                  // Trval˝ Rendering Context
  h_Dc: HDC;                        // Priv·tnÌ GDI Device Context
  h_Wnd: HWND;                      // Obsahuje Handle naöeho okna
  keys: array [0..255] of BOOL;	    // Pole pro ukl·d·nÌ vstupu z kl·vesnice
  Active: bool = true;              // Ponese informaci o tom, zda je okno aktivnÌ
  FullScreen:bool = true;           // Ponese informaci o tom, zda je program ve fullscreenu
  Light: bool;                      // SvÏtlo ON/OFF
  lp: bool;                         // Stisknuto L?
  fp: bool;                         // Stisknuto F?
  gp: bool;                         // G stisknuto?
  xrot: glfloat;                    // X Rotace
  yrot: glfloat;                    // Y Rotace
  xspeed: glfloat;                  // Rychlost x rotace
  yspeed: glfloat;                  // Rychlost y rotace
  z: glfloat = -5;                  // Hloubka v obrazovce
  LightAmbient: array [0..3] of GLfloat = ( 0.5, 0.5, 0.5, 1.0 );       // OkolnÌ svÏtlo
  LightDiffuse: array [0..3] of GLfloat = ( 1.0, 1.0, 1.0, 1.0 );       // P¯ÌmÈ svÏtlo
  LightPosition: array [0..3] of GLfloat = ( 0.0, 0.0, 2.0, 1.0 );      // Pozice svÏtla
  filter: gluint;                                                       // Specifikuje pouûÌvan˝ texturov˝ filtr
  fogmode: array [0..2] of gluint = (GL_EXP,GL_EXP2,GL_LINEAR);         // T¯i typy mlhy
  fogcolor: array [0..3] of GLfloat = (0.5,0.5,0.5,1.0);                // Barva mlhy
  fogfilter:gluint = 0;                                                 // Kter· mlha se pouûÌv·
  texture: array [0..2] of GLuint;                                      // Ukl·d· t¯i textury

function LoadBMP(FileName: pchar):PTAUX_RGBImageRec;        // Nahraje bitmapu
begin
  if Filename = '' then                                     // Byla p¯ed·na cesta k souboru?
    begin
    Result := nil;                                          // Pokud ne, konec
    exit;
    end;
  if not FileExists(Filename) then                          // Existuje soubor?
    begin
    Result := nil;                                          // Pokud ne, konec
    exit;
    end;
  Result := auxDIBImageLoadA(FileName);                     // NaËte bitmapu a vr·tÌ na ni ukazatel
end;

function LoadGLTextures: Bool;                                        // Loading bitmapy a konverze na texturu
var TextureImage: PTAUX_RGBImageRec;                                  // Ukl·d· bitmapu
    Status: Bool;                                                     // Indikuje chyby
begin
  Status := false;
  ZeroMemory(TextureImage,sizeof(TextureImage));                      // Vynuluje pamÏù
  TextureImage := LoadBMP('Data/Crate.bmp');                          // Nahraje bitmapu
  if Assigned(TextureImage) then
    begin
    Status := true;                                                   // Vöe je bez problÈm˘
    glGenTextures(3,texture[0]);                                      // Generuje t¯i textury
    // Vytvo¯Ì neline·rnÏ filtrovanou texturu
    glBindTexture(GL_TEXTURE_2D,texture[0]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D,0,3,TextureImage.sizeX,TextureImage.sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage.data);
    // Vytvo¯Ì line·rnÏ filtrovanou texturu
    glBindTexture(GL_TEXTURE_2D,texture[1]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D,0,3,TextureImage.sizeX,TextureImage.sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage.data);
    // Vytvo¯Ì mipmapovanou texturu
    glBindTexture(GL_TEXTURE_2D,texture[2]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
    gluBuild2DMipmaps(GL_TEXTURE_2D,3,TextureImage.sizeX,TextureImage.sizeY,GL_RGB,GL_UNSIGNED_BYTE,TextureImage.data);
    end;
  Result := Status;                                                   // Ozn·mÌ p¯ÌpadnÈ chyby
end;

procedure ReSizeGLScene(Width: GLsizei; Height: GLsizei); // ZmÏna velikosti a inicializace OpenGL okna
begin
  if (Height=0) then		                                  // ZabezpeËenÌ proti dÏlenÌ nulou
     Height:=1;                                           // NastavÌ v˝öku na jedna
  glViewport(0, 0, Width, Height);                        // Resetuje aktu·lnÌ nastavenÌ
  glMatrixMode(GL_PROJECTION);                            // ZvolÌ projekËnÌ matici
  glLoadIdentity();                                       // Reset matice
  gluPerspective(45.0,Width/Height,0.1,100.0);            // V˝poËet perspektivy
  glMatrixMode(GL_MODELVIEW);                             // ZvolÌ matici Modelview
  glLoadIdentity;                                         // Reset matice
end;


function InitGL:bool;	                              // Vöechno nastavenÌ OpenGL
begin
  if not LoadGLTextures then                        // Nahraje texturu
    begin
    Result := false;
    exit;
    end;
  glEnable(GL_TEXTURE_2D);                          // Zapne mapov·nÌ textur
  glShadeModel(GL_SMOOTH);			                    // PovolÌ jemnÈ stÌnov·nÌ
  glClearColor(0.5, 0.5, 0.5, 1.0);	  	            // »ernÈ pozadÌ
  glClearDepth(1.0);				                        // NastavenÌ hloubkovÈho bufferu
  glEnable(GL_DEPTH_TEST);			                    // PovolÌ hloubkovÈ testov·nÌ
  glDepthFunc(GL_LEQUAL);				                    // Typ hloubkovÈho testov·nÌ
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST); // NejlepöÌ perspektivnÌ korekce
  glLightfv(GL_LIGHT1, GL_AMBIENT, @LightAmbient);  // NastavenÌ okolnÌho svÏtla
	glLightfv(GL_LIGHT1, GL_DIFFUSE, @LightDiffuse);  // NastavenÌ p¯ÌmÈho svÏtla
	glLightfv(GL_LIGHT1, GL_POSITION,@LightPosition); // NastavenÌ pozice svÏtla
	glEnable(GL_LIGHT1);                              // Zapne svÏtlo
  glFogi(GL_FOG_MODE,fogmode[fogfilter]);           // MÛd mlhy
  glFogfv(GL_FOG_COLOR,@fogcolor);                  // Barva mlhy
  glFogf(GL_FOG_DENSITY,0.35);                      // Hustota mlhy
  glHint(GL_FOG_HINT,GL_DONT_CARE);                 // Kvalita mlhy
  glFogf(GL_FOG_START,1.0);                         // ZaË·tek mlhy - v hloubce (osa z)
  glFogf(GL_FOG_END,5.0);                           // Konec mlhy - v hloubce (osa z)
  glEnable(GL_FOG);                                 // Zapne mlhu
  Result:=true;                                     // Inicializace probÏhla v po¯·dku
end;


function DrawGLScene():bool;                            // Vykreslov·nÌ
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);  // Smaûe obrazovku a hloubkov˝ buffer
  glLoadIdentity();	                                    // Reset matice
  glTranslatef(0.0,0.0,z);                              // PoË·tek ss do hloubky z
	glRotatef(xrot,1.0,0.0,0.0);                          // Rotace kolem x
	glRotatef(yrot,0.0,1.0,0.0);                          // Rotace kolem y
  glBindTexture(GL_TEXTURE_2D, texture[filter]);        // ZvolÌ texturu
  glBegin(GL_QUADS);
		// P¯ednÌ stÏna
		glNormal3f( 0.0, 0.0, 1.0);                         // Norm·la
		glTexCoord2f(0.0, 0.0); glVertex3f(-1.0, -1.0,  1.0);
		glTexCoord2f(1.0, 0.0); glVertex3f( 1.0, -1.0,  1.0);
		glTexCoord2f(1.0, 1.0); glVertex3f( 1.0,  1.0,  1.0);
		glTexCoord2f(0.0, 1.0); glVertex3f(-1.0,  1.0,  1.0);
		// ZadnÌ stÏna
		glNormal3f( 0.0, 0.0,-1.0);                         // Norm·la
		glTexCoord2f(1.0, 0.0); glVertex3f(-1.0, -1.0, -1.0);
		glTexCoord2f(1.0, 1.0); glVertex3f(-1.0,  1.0, -1.0);
		glTexCoord2f(0.0, 1.0); glVertex3f( 1.0,  1.0, -1.0);
		glTexCoord2f(0.0, 0.0); glVertex3f( 1.0, -1.0, -1.0);
		// HornÌ stÏna
		glNormal3f( 0.0, 1.0, 0.0);                         // Norm·la
		glTexCoord2f(0.0, 1.0); glVertex3f(-1.0,  1.0, -1.0);
		glTexCoord2f(0.0, 0.0); glVertex3f(-1.0,  1.0,  1.0);
		glTexCoord2f(1.0, 0.0); glVertex3f( 1.0,  1.0,  1.0);
		glTexCoord2f(1.0, 1.0); glVertex3f( 1.0,  1.0, -1.0);
		// SpodnÌ stÏna
		glNormal3f( 0.0,-1.0, 0.0);                         // Norm·la
		glTexCoord2f(1.0, 1.0); glVertex3f(-1.0, -1.0, -1.0);
		glTexCoord2f(0.0, 1.0); glVertex3f( 1.0, -1.0, -1.0);
		glTexCoord2f(0.0, 0.0); glVertex3f( 1.0, -1.0,  1.0);
		glTexCoord2f(1.0, 0.0); glVertex3f(-1.0, -1.0,  1.0);
		// Prav· stÏna
		glNormal3f( 1.0, 0.0, 0.0);                         // Norm·la
		glTexCoord2f(1.0, 0.0); glVertex3f( 1.0, -1.0, -1.0);
		glTexCoord2f(1.0, 1.0); glVertex3f( 1.0,  1.0, -1.0);
		glTexCoord2f(0.0, 1.0); glVertex3f( 1.0,  1.0,  1.0);
		glTexCoord2f(0.0, 0.0); glVertex3f( 1.0, -1.0,  1.0);
		// Lev· stÏna
		glNormal3f(-1.0, 0.0, 0.0);                         // Norm·la
		glTexCoord2f(0.0, 0.0); glVertex3f(-1.0, -1.0, -1.0);
		glTexCoord2f(1.0, 0.0); glVertex3f(-1.0, -1.0,  1.0);
		glTexCoord2f(1.0, 1.0); glVertex3f(-1.0,  1.0,  1.0);
		glTexCoord2f(0.0, 1.0); glVertex3f(-1.0,  1.0, -1.0);
	glEnd();
	xrot := xrot + xspeed;
	yrot := yrot + yspeed;
  Result := true;                                       // VykreslenÌ probÏhlo v po¯·dku
end;


function WndProc(hWnd: HWND;                            // Handle okna
                 message: UINT;                         // Zpr·va pro okno
                 wParam: WPARAM;                        // DoplÚkovÈ informace
                 lParam: LPARAM):                       // DoplÚkovÈ informace
                                  LRESULT; stdcall;
begin
  if message=WM_SYSCOMMAND then                         // SystÈmov˝ p¯Ìkaz
    begin
      case wParam of                                    // Typ systÈmovÈho p¯Ìkazu
        SC_SCREENSAVE,SC_MONITORPOWER:                  // Pokus o zapnutÌ öet¯iËe obrazovky, Pokus o p¯echod do ˙spornÈho reûimu?
          begin
            result:=0;                                  // Zabr·nÌ obojÌmu
            exit;
          end;
      end;
    end;
  case message of                                       // VÏtvenÌ podle p¯ÌchozÌ zpr·vy
    WM_ACTIVATE:                                        // ZmÏna aktivity okna
      begin
        if (Hiword(wParam)=0) then                      // Zkontroluje zda nenÌ minimalizovanÈ
          active:=true                                  // Program je aktivnÌ
        else
          active:=false;                                // Program nenÌ aktivnÌ
        Result:=0;                                      // N·vrat do hlavnÌho cyklu programu
      end;
    WM_CLOSE:                                           // Povel k ukonËenÌ programu
      Begin
        PostQuitMessage(0);                             // Poöle zpr·vu o ukonËenÌ
        result:=0                                       // N·vrat do hlavnÌho cyklu programu
      end;
    WM_KEYDOWN:                                         // Stisk kl·vesy
      begin
        keys[wParam] := TRUE;                           // Ozn·mÌ to programu
        result:=0;                                      // N·vrat do hlavnÌho cyklu programu
      end;
    WM_KEYUP:                                           // UvolnÏnÌ kl·vesy
      begin
    	keys[wParam] := FALSE;                            // Ozn·mÌ to programu
        result:=0;                                      // N·vrat do hlavnÌho cyklu programu
      end;
    WM_SIZe:                                            // ZmÏna velikosti okna
      begin
    	ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));     // LoWord=äÌ¯ka, HiWord=V˝öka
        result:=0;                                      // N·vrat do hlavnÌho cyklu programu
      end
    else
      // P¯ed·nÌ ostatnÌch zpr·v systÈmu
      begin
      	Result := DefWindowProc(hWnd, message, wParam, lParam);
      end;
    end;
end;


procedure KillGLWindow;                                 // ZavÌr·nÌ okna
begin
  if FullScreen then                                    // Jsme ve fullscreenu?
    begin
      ChangeDisplaySettings(devmode(nil^),0);           // P¯epnutÌ do systÈmu
      showcursor(true);                                 // ZobrazÌ kurzor myöi
    end;
  if h_rc<> 0 then                                      // M·me rendering kontext?
    begin
      if (not wglMakeCurrent(h_Dc,0)) then              // Jsme schopni oddÏlit kontexty?
        MessageBox(0,'Release of DC and RC failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
      if (not wglDeleteContext(h_Rc)) then              // Jsme schopni smazat RC?
        begin
          MessageBox(0,'Release of Rendering Context failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
          h_Rc:=0;                                      // NastavÌ hRC na 0
        end;
    end;
  if (h_Dc=1) and (releaseDC(h_Wnd,h_Dc)<>0) then       // Jsme schopni uvolnit DC
    begin
      MessageBox(0,'Release of Device Context failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
      h_Dc:=0;                                          // NastavÌ hDC na 0
    end;
  if (h_Wnd<>0) and (not destroywindow(h_Wnd))then      // Jsme schopni odstranit okno?
    begin
      MessageBox(0,'Could not release hWnd.',' Shutdown Error',MB_OK or MB_ICONERROR);
      h_Wnd:=0;                                         // NastavÌ hWnd na 0
    end;
  if (not UnregisterClass('OpenGL',hInstance)) then     // Jsme schopni odregistrovat t¯Ìdu okna?
    begin
      MessageBox(0,'Could Not Unregister Class.','SHUTDOWN ERROR',MB_OK or MB_ICONINFORMATION);
    end;
end;


function CreateGlWindow(title:Pchar; width,height,bits:integer;FullScreenflag:bool):boolean stdcall;
var
  Pixelformat: GLuint;            // Ukl·d· form·t pixel˘
  wc:TWndclass;                   // Struktura Windows Class
  dwExStyle:dword;                // RozöÌ¯en˝ styl okna
  dwStyle:dword;                  // Styl okna
  pfd: pixelformatdescriptor;     // NastavenÌ form·tu pixel˘
  dmScreenSettings: Devmode;      // MÛd za¯ÌzenÌ
  h_Instance:hinst;               // Instance okna
  WindowRect: TRect;              // ObdÈlnÌk okna
begin
  WindowRect.Left := 0;                               // NastavÌ lev˝ okraj na nulu
  WindowRect.Top := 0;                                // NastavÌ hornÌ okraj na nulu
  WindowRect.Right := width;                          // NastavÌ prav˝ okraj na zadanou hodnotu
  WindowRect.Bottom := height;                        // NastavÌ spodnÌ okraj na zadanou hodnotu
  h_instance:=GetModuleHandle(nil);                   // ZÌsk· instanci okna
  FullScreen:=FullScreenflag;                         // NastavÌ promÏnnou fullscreen na spr·vnou hodnotu
  with wc do
    begin
      style:=CS_HREDRAW or CS_VREDRAW or CS_OWNDC;    // P¯ekreslenÌ p¯i zmÏnÏ velikosti a vlastnÌ DC
      lpfnWndProc:=@WndProc;                          // Definuje proceduru okna
      cbClsExtra:=0;                                  // é·dn· extra data
      cbWndExtra:=0;                                  // é·dn· extra data
      hInstance:=h_Instance;                          // Instance
      hIcon:=LoadIcon(0,IDI_WINLOGO);                 // StandardnÌ ikona
      hCursor:=LoadCursor(0,IDC_ARROW);               // StandardnÌ kurzor myöi
      hbrBackground:=0;                               // PozadÌ nenÌ nutnÈ
      lpszMenuName:=nil;                              // Nechceme menu
      lpszClassName:='OpenGl';                        // JmÈno t¯Ìdy okna
    end;
  if  RegisterClass(wc)=0 then                        // Registruje t¯Ìdu okna
    begin
      MessageBox(0,'Failed To Register The Window Class.','Error',MB_OK or MB_ICONERROR);
      Result:=false;                                  // P¯i chybÏ vr·tÌ false
      exit;
    end;
  if FullScreen then                                  // Budeme ve fullscreenu?
    begin
      ZeroMemory( @dmScreenSettings, sizeof(dmScreenSettings) );  // Vynulov·nÌ pamÏti
      with dmScreensettings do
        begin
          dmSize := sizeof(dmScreenSettings);         // Velikost struktury Devmode
          dmPelsWidth  := width;	                    // äÌ¯ka okna
	        dmPelsHeight := height;                     // V˝öka okna
          dmBitsPerPel := bits;                       // Barevn· hloubka
          dmFields     := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
        end;
      // PokusÌ se pouûÌt pr·vÏ definovanÈ nastavenÌ
      if (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN))<>DISP_CHANGE_SUCCESSFUL THEN
        Begin
          // Nejde-li fullscreen, m˘ûe uûivatel spustit program v oknÏ nebo ho opustit
          if MessageBox(0,'This FullScreen Mode Is Not Supported. Use Windowed Mode Instead?'
                                             ,'NeHe GL',MB_YESNO or MB_ICONEXCLAMATION)= IDYES then
                FullScreen:=false                     // BÏh v oknÏ
          else
            begin
              // ZobrazÌ uûivateli zpr·vu, ûe program bude ukonËen
              MessageBox(0,'Program Will Now Close.','Error',MB_OK or MB_ICONERROR);
              Result:=false;                          // Vr·tÌ FALSE
              exit;
            end;
          end;
    end;
  if FullScreen then                                  // Jsme st·le ve fullscreenu?
    begin
      dwExStyle:=WS_EX_APPWINDOW;                     // RozöÌ¯en˝ styl okna
      dwStyle:=WS_POPUP or WS_CLIPSIBLINGS or WS_CLIPCHILDREN; // Styl okna
      Showcursor(false);                              // Skryje kurzor
    end
  else
    begin
      dwExStyle:=WS_EX_APPWINDOW or WS_EX_WINDOWEDGE;   // RozöÌ¯en˝ styl okna
      dwStyle:=WS_OVERLAPPEDWINDOW or WS_CLIPSIBLINGS or WS_CLIPCHILDREN; // Styl okna
    end;
  AdjustWindowRectEx(WindowRect,dwStyle,false,dwExStyle); // P¯izp˘sobenÌ velikosti okna
  // Vytvo¯enÌ okna
  H_wnd:=CreateWindowEx(dwExStyle,                    // RozöÌ¯en˝ styl
                               'OpenGl',              // JmÈno t¯Ìdy
                               Title,                 // Titulek
                               dwStyle,               // Definovan˝ styl
                               0,0,                   // Pozice
                               WindowRect.Right-WindowRect.Left,  // V˝poËet öÌ¯ky
                               WindowRect.Bottom-WindowRect.Top,  // V˝poËet v˝öky
                               0,                     // é·dnÈ rodiËovskÈ okno
                               0,                     // Bez menu
                               hinstance,             // Instance
                               nil);                  // Nep¯edat nic do WM_CREATE
  if h_Wnd=0 then                                     // Pokud se okno nepoda¯ilo vytvo¯it
    begin
      KillGlWindow();                                 // ZruöÌ okno
      MessageBox(0,'Window creation error.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // Vr·tÌ chybu
      exit;
    end;
  with pfd do                                         // Ozn·mÌme Windows jak chceme vöe nastavit
    begin
      nSize:= SizeOf( PIXELFORMATDESCRIPTOR );        // Velikost struktury
      nVersion:= 1;                                   // »Ìslo verze
      dwFlags:= PFD_DRAW_TO_WINDOW                    // Podpora okna
        or PFD_SUPPORT_OPENGL                         // Podpora OpenGL
        or PFD_DOUBLEBUFFER;                          // Podpora Double Bufferingu
      iPixelType:= PFD_TYPE_RGBA;                     // RGBA Format
      cColorBits:= bits;                              // ZvolÌ barevnou hloubku
      cRedBits:= 0;                                   // Bity barev ignorov·ny
      cRedShift:= 0;
      cGreenBits:= 0;
      cBlueBits:= 0;
      cBlueShift:= 0;
      cAlphaBits:= 0;                                 // é·dn˝ alpha buffer
      cAlphaShift:= 0;                                // Ignorov·n Shift bit
      cAccumBits:= 0;                                 // é·dn˝ akumulaËnÌ buffer
      cAccumRedBits:= 0;                              // AkumulaËnÌ bity ignorov·ny
      cAccumGreenBits:= 0;
      cAccumBlueBits:= 0;
      cAccumAlphaBits:= 0;
      cDepthBits:= 16;                                // 16-bitov˝ hloubkov˝ buffer (Z-Buffer)
      cStencilBits:= 0;                               // é·dn˝ Stencil Buffer
      cAuxBuffers:= 0;                                // é·dn˝ Auxiliary Buffer
      iLayerType:= PFD_MAIN_PLANE;                    // HlavnÌ vykreslovacÌ vrstva
      bReserved:= 0;                                  // Rezervov·no
      dwLayerMask:= 0;                                // Maska vrstvy ignorov·na
      dwVisibleMask:= 0;
      dwDamageMask:= 0;
    end;
  h_Dc := GetDC(h_Wnd);                               // ZkusÌ p¯ipojit kontext za¯ÌzenÌ
  if h_Dc=0 then                                      // Poda¯ilo se p¯ipojit kontext za¯ÌzenÌ?
    begin
      KillGLWindow();                                 // Zav¯e okno
      MessageBox(0,'Cant''t create a GL device context.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // UkonËÌ program
      exit;
    end;
  PixelFormat := ChoosePixelFormat(h_Dc, @pfd);       // ZkusÌ najÌt Pixel Format
  if (PixelFormat=0) then                             // Poda¯ilo se najÌt Pixel Format?
    begin
      KillGLWindow();                                 // Zav¯e okno
      MessageBox(0,'Cant''t Find A Suitable PixelFormat.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // UkonËÌ program
      exit;
    end;
  if (not SetPixelFormat(h_Dc,PixelFormat,@pfd)) then  // Poda¯ilo se nastavit Pixel Format?
    begin
      KillGLWindow();                                 // Zav¯e okno
      MessageBox(0,'Cant''t set PixelFormat.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // UkonËÌ program
      exit;
    end;
  h_Rc := wglCreateContext(h_Dc);                     // Poda¯ilo se vytvo¯it Rendering Context?
  if (h_Rc=0) then
    begin
      KillGLWindow();                                 // Zav¯e okno
      MessageBox(0,'Cant''t create a GL rendering context.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // UkonËÌ program
      exit;
    end;
  if (not wglMakeCurrent(h_Dc, h_Rc)) then            // Poda¯ilo se aktivovat Rendering Context?
    begin
      KillGLWindow();                                 // Zav¯e okno
      MessageBox(0,'Cant''t activate the GL rendering context.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // UkonËÌ program
      exit;
    end;
  ShowWindow(h_Wnd,SW_SHOW);                          // ZobrazenÌ okna
  SetForegroundWindow(h_Wnd);                         // Do pop¯edÌ
  SetFOcus(h_Wnd);                                    // ZamÏ¯Ì fokus
  ReSizeGLScene(width,height);                        // NastavenÌ perspektivy OpenGL scÈny
  if (not InitGl()) then                              // Inicializace okna
    begin
      KillGLWindow();                                 // Zav¯e okno
      MessageBox(0,'initialization failed.','Error',MB_OK or MB_ICONEXCLAMATION);
      Result:=false;                                  // UkonËÌ program
      exit;
    end;
  Result:=true;                                       // Vöe probÏhlo v po¯·dku
end;


function WinMain(hInstance: HINST;                    // Instance
		 hPrevInstance: HINST;                            // P¯edchozÌ instance
		 lpCmdLine: PChar;                                // Parametry p¯ÌkazovÈ ¯·dky
		 nCmdShow: integer):                              // Stav zobrazenÌ okna
                        integer; stdcall;
var
  msg: TMsg;                                          // Struktura zpr·v systÈmu
  done: Bool;                                         // PromÏnn· pro ukonËenÌ programu

begin
  done:=false;
  // Dotaz na uûivatele pro fullscreen/okno
  if MessageBox(0,'Would You Like To Run In FullScreen Mode?','Start FullScreen',
                             MB_YESNO or MB_ICONQUESTION)=IDNO then
    FullScreen:=false                                 // BÏh v oknÏ
  else
    FullScreen:=true;                                 // Fullscreen
  if not CreateGLWindow('NeHe''s OpenGL Framework',640,480,16,FullScreen) then // Vytvo¯enÌ OpenGL okna
    begin
      Result := 0;                                    // Konec programu p¯i chybÏ
      exit;
    end;
  while not done do                                   // HlavnÌ cyklus programu
    begin
      if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then  // P¯iöla zpr·va?
        begin
          if msg.message=WM_QUIT then                 // Obdrûeli jsme zpr·vu pro ukonËenÌ?
            done:=true                                // Konec programu
          else
            begin
	          TranslateMessage(msg);                    // P¯eloûÌ zpr·vu
	          DispatchMessage(msg);                     // Odeöle zpr·vu
	        end;
        end
      else      // Pokud nedoöla û·dn· zpr·va
        begin
          // Je program aktivnÌ, ale nelze kreslit? Byl stisknut ESC?
          if (active and not(DrawGLScene()) or keys[VK_ESCAPE]) then
            done:=true                                // UkonËÌme program
          else                                        // P¯ekreslenÌ scÈny
            SwapBuffers(h_Dc);                        // ProhozenÌ buffer˘ (Double Buffering)
          if keys[VK_F1] then                         // Byla stisknuta kl·vesa F1?
            begin
            Keys[VK_F1] := false;                     // OznaË ji jako nestisknutou
            KillGLWindow();                           // ZruöÌ okno
            FullScreen := not FullScreen;             // Negace fullscreen
            // Znovuvytvo¯enÌ okna
            if not CreateGLWindow('NeHe''s OpenGL Framework',640,480,16,fullscreen) then
              Result := 0;                            // Konec programu pokud nebylo vytvo¯eno
            end;
          if (keys[ord('L')] and not lp) then         // Kl·vesa L - svÏtlo
            begin
            lp := true;
            light := not light;
            if not light then glDisable(GL_LIGHTING)  // Vypne svÏtlo
              else glEnable(GL_LIGHTING);             // Zapne svÏtlo
            end;
          if not keys[ord('L')] then lp := false;
          if (keys[ord('F')] and not fp) then         // Kl·vesa F - zmÏna texturovÈho filtru
            begin
            fp := true;
            filter := filter + 1;
            if filter > 2 then filter := 0;
            end;
          if not keys[ord('F')] then fp := false;     // UvolnÏnÌ F
          if keys[VK_PRIOR] then z := z - 0.02;       // Kl·vesa Page Up - zv˝öÌ zano¯enÌ do obrazovky
          if keys[VK_NEXT] then z := z + 0.02;        // Kl·vesa Page Down - snÌûÌ zano¯enÌ do obrazovky
          if (keys[VK_UP]) then xspeed:=xspeed-0.01;  // äipka nahoru
		      if (keys[VK_DOWN]) then xspeed:=xspeed+0.01;// äipka dolu
		      if (keys[VK_RIGHT]) then yspeed:=yspeed+0.01; // äipka vpravo
		      if (keys[VK_LEFT]) then yspeed:=yspeed-0.01;  // äipka vlevo
          if (keys[ord('G')] and not gp) then         // Je stisknuto 'G'?
            begin
            gp := true;
            fogfilter := fogfilter + 1;               // Inkrementace fogfilter
            if fogfilter > 2 then fogfilter := 0;     // HlÌd· p¯eteËenÌ
            glFogi(GL_FOG_MODE,fogmode[fogfilter]);   // NastavenÌ mÛdu mlhy
            end;
          if not keys[ord('G')] then gp := false;     // Bylo uvolnÏno 'G'?
        end;
    end;                                              // Konec smyËky while
  killGLwindow();                                     // Zav¯e okno
  result:=msg.wParam;                                 // UkonËenÌ programu
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
end.

