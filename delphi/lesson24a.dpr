program lesson24a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages, sysutils,
  OpenGL;

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

type
  TextureImage = record             // Struktura textury
    imageData: ^GLubyte;            // Data obrázku
    bpp: GLuint;                    // Barevná hloubka obrázku
    width: GLuint;                  // Šíøka obrázku
    height: GLuint;                 // Vıška obrázku
    textID: GLuint;                 // Vytvoøená textura
    end;

var
  h_Rc: HGLRC;		                  // Trvalı Rendering Context
  h_Dc: HDC;                        // Privátní GDI Device Context
  h_Wnd: HWND;                      // Obsahuje Handle našeho okna
  keys: array [0..255] of BOOL;	    // Pole pro ukládání vstupu z klávesnice
  Active: bool = true;              // Ponese informaci o tom, zda je okno aktivní
  FullScreen:bool = true;           // Ponese informaci o tom, zda je program ve fullscreenu
  Scroll: integer;                  // Pro rolování okna
  MaxTokens: integer;               // Poèet podporovanıch rozšíøení
  Base: GLuint;                     // Základní display list fontu
  swidth, sheight: integer;         // Šíøka, Vıška oøezané oblasti
  textures: array [0..0] of TextureImage; // Jedna textura

function LoadTGA(var texture: TextureImage; filename: string): bool;
type
  TData = array [0..255] of GLubyte;
var
  TGAheader: array [0..11] of GLbyte;             // Nekomprimovaná TGA hlavièka { 0,0,2,0,0,0,0,0,0,0,0,0 }
  TGAcompare: array [0..11] of GLbyte;            // Pro porovnání TGA hlavièky
  Header: array [0..5] of GLbyte;                 // Prvních 6 uiteènıch bytù z hlavièky
  BytesPerPixel: GLuint;                          // Poèet bytù na pixel pouitı v TGA souboru
  ImageSize: GLuint;                              // Ukládá velikost obrázku pøi alokování RAM
  temp: GLuint;                                   // Pomocná promìnná
  TypeMode: GLuint;                               // GL mód
  f: file;                                        // Soubor TGA
  precteno: Gluint;                               // Poèet pøeètenıch bytu
  i: integer;                                     // Cyklus
  B, R: PGluint;                                  // Ukazatel na prohazované sloky barev
begin
  ZeroMemory(@TGAheader,sizeof(TGAheader));       // Nulování prvkù pole
  TGAheader[2] := 2;                              // Tøetí prvek hlavièky je 2 - viz deklarace
  TypeMode := GL_RGBA;                            // Implicitním GL módem je RGBA (32 BPP)
  if not FileExists(filename) then                // Existuje soubor?
    begin
    Result := false;                                                  // Konec funkce
    exit;
    end;
  AssignFile(f,filename);                                             // Pøiøazení souboru
  Reset(f,1);                                                         // Otevøe TGA soubor
  BlockRead(f,TGAcompare,Sizeof(TGAcompare),precteno);                // Naète hlavièku
  if (precteno <> Sizeof(TGAcompare)) or                              // Podaøilo se naèíst 12 bytù?
    (not CompareMem(@TGAcompare,@TGAHeader,sizeof(TGAheader))) then   // Mají potøebné hodnoty?
    begin
    Result := false;                                                  // Konec funkce
    CloseFile(f);                                                     // Zavøe soubor
    exit;
    end;
  BlockRead(f,Header,Sizeof(Header),precteno);                        // Pokud ano, naète dalších šest bytù
  if precteno <> sizeof(Header) then                                  // Podaøilo se naèíst 6 bytù?
    begin
    Result := false;                                                  // Konec funkce
    CloseFile(f);                                                     // Zavøe soubor
    exit;
    end;
  texture.width := Header[1] * 256 + Header[0];                       // Získá šíøku obrázku
  texture.height := Header[3] * 256 + Header[2];                      // Získá vıšku obrázku
  if (texture.width <= 0) or (texture.height <= 0)                    // Platná šíøka? Platná vıška?
    or ((Header[4] <> 24) and (Header[4] <> 32)) then                 // Platná barevná hloubka?
    begin
    Result := false;                                                  // Konec funkce
    CloseFile(f);                                                     // Zavøe soubor
    exit;
    end;
  texture.bpp := Header[4];                                           // Bity na pixel (24 nebo 32)
  BytesPerPixel := texture.bpp div 8;                                 // Byty na pixel
  ImageSize := texture.width * texture.height * BytesPerPixel;        // Velikost pamìti pro data obrázku
  texture.imageData := AllocMem(ImageSize);                           // Alokace pamìti pro data obrázku
  if texture.imageData = nil then                                     // Podaøilo se pamì alokovat?
    begin
    Result := false;                                                  // Konec funkce
    CloseFile(f);                                                     // Zavøe soubor
    exit;
    end;
  BlockRead(f,texture.imageData^,ImageSize,precteno);                 // Kopírování dat
  if precteno <> ImageSize then                                       // Podaøilo se kopírování dat?
    begin
    Result := false;                                                  // Konec funkce
    FreeMem(texture.imageData);                                       // Uvolní pamì
    CloseFile(f);                                                     // Zavøe soubor
    exit;
    end;
  for i := 0 to (texture.width * texture.height) - 1 do               // Prochází data obrázku
    begin
    B := Pointer(Integer(texture.imageData) + i * BytesPerPixel);     // Ukazatel na B
    R := Pointer(Integer(texture.imageData) + i * BytesPerPixel+2);   // Ukazatel na R
    temp := B^;                                                       // B uloíme do pomocné promìnné
    B^ := R^;                                                         // R je na správném místì
    R^ := temp;                                                       // B je na správném místì
    end;
  CloseFile(f);                                                       // Zavøe soubor
  glGenTextures(1,texture.textID);                                    // Generuje texturu
  glBindTexture(GL_TEXTURE_2D, texture.textID);                       // Zvolí texturu
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);   // Lineární filtrování
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);   // Lineární filtrování
  if texture.bpp = 24 then TypeMode := GL_RGB;                        // Je obrázek 24 bitovı? Nastaví typ na GL_RGB
  glTexImage2D(GL_TEXTURE_2D, 0, TypeMode, texture.width, texture.height, 0, TypeMode, GL_UNSIGNED_BYTE, texture.imageData);// Vytvoøí texturu
  FreeMem(texture.imageData);                                         // Uvolní pamì
  Result := true;
end;

procedure ReSizeGLScene(Width: GLsizei; Height: GLsizei); // Zmìna velikosti a inicializace OpenGL okna
begin
  swidth := Width;                                        // Šíøka okna
  sheight := Height;                                      // Vıška okna
  if (Height=0) then		                                  // Zabezpeèení proti dìlení nulou
     Height:=1;                                           // Nastaví vıšku na jedna
  glViewport(0, 0, Width, Height);                        // Resetuje aktuální nastavení
  glMatrixMode(GL_PROJECTION);                            // Zvolí projekèní matici
  glLoadIdentity();                                       // Reset matice
  glOrtho(0.0,640,480,0.0,-1.0,1.0);                      // Pravoúhlá projekce 640x480, [0; 0] vlevo nahoøe
  glMatrixMode(GL_MODELVIEW);                             // Zvolí matici Modelview
  glLoadIdentity;                                         // Reset matice
end;

procedure BuildFont;                                      // Vytvoøení display listù fontu
var
  cx, cy: GLfloat;                                        // Koordináty x, y
  loop: integer;
begin
  base := glGenLists(256);                                // 256 display listù
  glBindTexture(GL_TEXTURE_2D,textures[0].textID);        // Vıbìr textury
  for loop:=0 to 255 do                                   // Vytváøí 256 display listù
    begin
    cx := (loop mod 16) / 16;                             // X pozice aktuálního znaku
    cy := (loop div 16) /16;                              // Y pozice aktuálního znaku
    glNewList(base + loop,GL_COMPILE);                    // Vytvoøení display listu
      glBegin(GL_QUADS);                                  // Pro kadı znak jeden obdélník
        glTexCoord2f(cx,1-cy-0.0625);glVertex2i(0,16);
        glTexCoord2f(cx+0.0625,1-cy-0.0625);glVertex2i(16,16);
        glTexCoord2f(cx+0.0625,1-cy-0.001);glVertex2i(16,0);
        glTexCoord2f(cx,1-cy-0.001);glVertex2i(0,0);
      glEnd;
      glTranslated(14,0,0);                               // Pøesun na pravou stranu znaku
    glEndList;                                            // Konec kreslení display listu
    end;
end;

procedure KillFont;                                       // Uvolní pamì fontu
begin
  glDeleteLists(base,256);                                // Smae 256 display listù
end;

procedure glPrint(x,y: GLint;text: string;sada: integer); // Provádí vıpis textu
begin
  if text = '' then exit;
  if sada>1 then sada:=1;
  glEnable(GL_TEXTURE_2D);                                // Zapne texturové mapování
  glLoadIdentity;                                         // Reset matice
  glTranslated(x,y,0);                                    // Pøesun na poadovanou pozici
  glListBase(base-32+(128*sada));                         // Zvolí znakovou sadu
  glScalef(1.0,2.0,1.0);                                  // Zmìna mìøítka
  glCallLists(length(text),GL_UNSIGNED_BYTE,Pchar(text)); // Vıpis textu na monitor
  glDisable(GL_TEXTURE_2D);                               // Vypne texturové mapování
end;

function InitGL:bool;	                              // Všechno nastavení OpenGL
begin
  if not LoadTGA(textures[0],'Data/Font.TGA') then  // Nahraje texturu fontu z TGA obrázku
    begin
    Result := false;
    exit;
    end;
  BuildFont;                                        // Sestaví font
  glShadeModel(GL_SMOOTH);			                    // Povolí jemné stínování
  glClearColor(0.0, 0.0, 0.0, 0.5);	  	            // Èerné pozadí
  glClearDepth(1.0);				                        // Nastavení hloubkového bufferu
  glBindTexture(GL_TEXTURE_2D,textures[0].textID);  // Zvolí texturu
  Result:=true;                                     // Inicializace probìhla v poøádku
end;


function DrawGLScene():bool;                            // Vykreslování
var
  token: string;                                        // Ukládá jedno rozšíøení
  cnt: integer;                                         // Èítaè rozšíøení
  texts: string;                                        // Všechna rozšíøení
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);  // Smae obrazovku a hloubkovı buffer
  glColor3f(1.0,0.5,0.5);                               // Èervená barva
  glPrint(50,16,'RENDERER',1);                          // Vıpis nadpisu pro grafickou kartu
  glPrint(80,48,'VENDOR',1);                            // Vıpis nadpisu pro vırobce
  glPrint(66,80,'VERSION',1);                           // Vıpis nadpisu pro verzi
  glColor3f(1.0,0.7,0.4);                               // Oranová barva
  glPrint(200,16,glGetString(GL_RENDERER),1);           // Vıpis typu grafické karty
  glPrint(200,48,glGetString(GL_VENDOR),1);             // Vıpis vırobce
  glPrint(200,80,glGetString(GL_VERSION),1);            // Vıpis verze
  glColor3f(0.5,0.5,1.0);                               // Modrá barva
  glPrint(192,432,'NeHe Productions',1);                // Vıpis NeHe Productions
  glLoadIdentity();	                                    // Reset matice
  glColor3f(1.0,1.0,1.0);                               // Bílá barva
  glBegin(GL_LINE_STRIP);                               // Zaèátek kreslení linek
    glVertex2d(639,417);                                // 1
    glVertex2d(0,417);                                  // 2
    glVertex2d(0,480);                                  // 3
    glVertex2d(639,480);                                // 4
    glVertex2d(639,128);                                // 5
  glEnd();                                              // Konec kreslení
  glBegin(GL_LINE_STRIP);                               // Zaèátek kreslení linek
    glVertex2d(0,128);                                  // 6
    glVertex2d(639,128);                                // 7
    glVertex2d(639,1);                                  // 8
    glVertex2d(0,1);                                    // 9
    glVertex2d(0,417);                                  // 10
  glEnd();                                              // Konec kreslení
  glScissor(1,Round(0.135416*sheight),swidth-2,Round(0.597916*sheight));  // Definování oøezávací oblasti
  glEnable(GL_SCISSOR_TEST);                            // Povolí oøezávací testy
  texts := glGetString(GL_EXTENSIONS);                  // Zkopíruje seznam rozšíøení do text
  token := copy(texts,1,Pos(' ',texts));                // Získá první podøetìzec
  Delete(texts,1,Pos(' ',texts));                       // Smae první podøetìzec
  while token <> '' do                                  // Prochází podporovaná rozšíøení
    begin
    Inc(cnt);                                           // Inkrementuje èítaè
    if cnt > MaxTokens then MaxTokens := cnt;           // Je maximum menší ne hodnota èítaèe? // Aktualizace maxima
    glColor3f(0.5,1.0,0.5);                             // Zelená barva
    glPrint(0,96+(cnt*32)-Scroll,IntToStr(cnt),0);      // Poøadí aktuálního rozšíøení
    glColor3f(1.0,1.0,0.5);                             // lutá barva
    glPrint(50,96+(cnt*32)-Scroll,token,0);             // Vypíše jedno rozšíøení
    token := copy(texts,1,Pos(' ',texts));              // Najde další rozšíøení
    Delete(texts,1,Pos(' ',texts));                     // Smae další rozšíøení
    end;
  glDisable(GL_SCISSOR_TEST);                           // Vypne oøezávací testy
  glFlush;                                              // Vyprázdní renderovací pipeline
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
  KillFont;                                             // Smae font
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
          if (keys[VK_UP] and (scroll > 0)) then      // Šipka nahoru?
            scroll := scroll - 2;                     // Posune text nahoru
          if (keys[VK_DOWN] and (scroll < 32*(maxtokens-9))) then   // Šipka dolù?
            scroll := scroll + 2;                                   // Posune text dolù
        end;
    end;                                              // Konec smyèky while
  killGLwindow();                                     // Zavøe okno
  result:=msg.wParam;                                 // Ukonèení programu
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
end.

