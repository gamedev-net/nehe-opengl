program lesson29a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages, sysutils,
  OpenGL;

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

type
  TEXTURE_IMAGE = record            // Struktura obrázku
    width: integer;                 // Šíøka v pixelech
    height: integer;                // Vıška v pixelech
    format: integer;                // Barevná hloubka v bytech na pixel
    data: PGLubyte;                 // Data obrázku
    end;

  P_TEXTURE_IMAGE = ^TEXTURE_IMAGE; // Datovı typ ukazatele na obrázek

var
  h_Rc: HGLRC;		                  // Trvalı Rendering Context
  h_Dc: HDC;                        // Privátní GDI Device Context
  h_Wnd: HWND;                      // Obsahuje Handle našeho okna
  keys: array [0..255] of BOOL;	    // Pole pro ukládání vstupu z klávesnice
  Active: bool = true;              // Ponese informaci o tom, zda je okno aktivní
  FullScreen:bool = true;           // Ponese informaci o tom, zda je program ve fullscreenu
  t1, t2: P_TEXTURE_IMAGE;          // Dva obrázky
  texture: GLuint;                  // Jedna textura
  xrot: GLfloat;                    // X rotace
  yrot: GLfloat;                    // Y rotace
  zrot: GLfloat;                    // Z rotace

function AllocateTextureBuffer(w, h, f: GLint): P_TEXTURE_IMAGE;  // Alokuje pamì pro obrázek
var
  ti: P_TEXTURE_IMAGE;                                            // Ukazatel na strukturu obrázku
  c: PGLubyte;                                                    // Ukazatel na data obrázku
begin
  ti := nil;
  c := nil;
  ti := AllocMem(SizeOf(TEXTURE_IMAGE));                          // Alokace pamìti pro strukturu
  if ti <> nil then                                               // Podaøila se alokace pamìti?
    begin
    ti.width := w;                                                // Nastaví atribut šíøky
    ti.height := h;                                               // Nastaví atribut vıšky
    ti.format := f;                                               // Nastaví atribut barevné hloubky
    c := AllocMem(w*h*f);                                         // Alokace pamìti pro strukturu
    if c <> nil then                                              // Podaøila se alokace pamìti?
      ti.data := c                                                // Nastaví ukazatel na data
      else                                                        // Alokace pamìti pro data se nepodaøila
      begin
      MessageBox(h_Wnd,'Could Not Allocate Memory For A Texture Buffer','BUFFER ERROR',MB_OK or MB_ICONINFORMATION);
      FreeMem(ti);                                                // Uvolnìní pamìti struktury
      ti := nil;
      Result := nil;
      exit;
      end;
    end
    else                                                          // Alokace pamìti pro strukturu se nepodaøila
    begin
    MessageBox(h_Wnd,'Could Not Allocate An Image Structure','IMAGE STRUCTURE ERROR',MB_OK or MB_ICONINFORMATION);
    Result := nil;
    exit;
    end;
  Result := ti;                                                   // Vrátí ukazatel na dynamickou pamì
end;

procedure DeallocateTexture(t: P_TEXTURE_IMAGE);                  // Uvolní dynamicky alokovanou pamì obrázku
begin
  if t <> nil then                                                // Pokud struktura obrázku existuje
    begin
    if t.data <> nil then                                         // Pokud existují data obrázku
      FreeMem(t.data);                                            // Uvolní data obrázku
    FreeMem(t);                                                   // Uvolní strukturu obrázku
    end;
end;

function ReadTextureData(filename: string; buffer: P_TEXTURE_IMAGE): integer;   // Naète data obrázku
var
  f: file;                                                                      // Handle souboru
  i, j, k: integer;                                                             // Øídící promìnné cyklù
  done: integer;                                                                // Poèet naètenıch bytù ze souboru (návratová hodnota)
  stride: integer;                                                              // Velikost øádku
  p: PGLubyte;                                                                  // Ukazatel na aktuální byte pamìti
begin
  done := 0;
  stride := buffer.width * buffer.format;                                       // Velikost øádku
  p := nil;
  AssignFile(f,filename);                                                       // Otevøe soubor
  {$I-}
  Reset(f,1);
  {$I+}
  if IOResult = 0 then                                                          // Podaøilo se ho otevøít?
    begin
    for i := buffer.height-1 downto 0 do                                        // Od zdola nahoru po øádcích
      begin
      p := Pointer(Integer(buffer.data) + i * stride);                          // P ukazuje na poadovanı øádek
      for j := 0 to buffer.width-1 do                                           // Zleva doprava po pixelech
        begin
        for k := 0 to buffer.format-2 do                                        // Jednotlivé byty v pixelu
          begin
          BlockRead(f,p^,1);                                                    // Naète R, G a B sloku barvy
          Inc(p);
          Inc(done);
          end;
        p^ := 255;                                                              // Alfa neprùhledná (ruèní nastavení)
        Inc(p);                                                                 // Ukazatel na další byte
        end;
      end;
    CloseFile(f);                                                               // Zavøe soubor
    end
    else                                                                        // Soubor se nepodaøilo otevøít
    begin
    MessageBox(h_Wnd,'Unable To Open Image File','IMAGE ERROR',MB_OK or MB_ICONINFORMATION);
    end;
  Result := done;                                                               // Vrátí poèet naètenıch bytù
end;

procedure BuildTexture(tex: P_TEXTURE_IMAGE);                                   // Vytvoøí texturu
begin
  glGenTextures(1,texture);                                                     // Generuje texturu
  glBindTexture(GL_TEXTURE_2D,texture);                                         // Vybere texturu za aktuální
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);               // Lineární filtrování
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
  gluBuild2DMipmaps(GL_TEXTURE_2D,GL_RGB,tex.width,tex.height,GL_RGBA,GL_UNSIGNED_BYTE,tex.data); // Mipmapovaná textura
end;
                                                                                // Blitting obrázkù
procedure Blit(src, dst: P_TEXTURE_IMAGE;                                       // Zdrojovı obrázek, Cílovı obrázek
                src_xstart, src_ystart,                                         // Levı horní bod kopírované oblasti
                src_width, src_height,                                          // Šíøka a vıška kopírované oblasti
                dst_xstart, dst_ystart,                                         // Kam kopírovat (levı horní bod)
                blend, alpha: integer);                                         // Pouít blending? Hodnota alfy pøi blendingu
var
  i, j, k: integer;                                                             // Øídící promìnné cyklù
  s, d: PGLubyte;                                                               // Pomocné ukazatele na data zdroje a cíle
begin
  if alpha > 255 then alpha := 255;                                             // Je alfa mimo rozsah?
  if alpha < 0 then alpha := 0;
  if blend < 0 then blend := 0;                                                 // Je blending mimo rozsah?
  if blend > 1 then blend := 1;
  d := Pointer(Integer(dst.data) + dst_ystart * dst.width * dst.format);        // Ukazatele na první kopírovanı øádek
  s := Pointer(Integer(src.data) + src_ystart * src.width * src.format);
  for i := 0 to src_height-1 do                                                 // Øádky, ve kterıch se kopírují data
    begin
    s := Pointer(Integer(s) + src_xstart * src.format);                         // Posun na první kopírovanı pixel v øádku
    d := Pointer(Integer(d) + dst_xstart * dst.format);
    for j := 0 to src_width-1 do                                                // Pixely v øádku, které se mají kopírovat
      for k := 0 to src.format-1 do                                             // Byty v kopírovaném pixelu
        begin
        if blend <> 0 then                                                      // Je poadován blending?
          d^ := (s^ * alpha + d^ * (255 - alpha)) shr 8                         // Slouèení dvou pixelù do jednoho
          else                                                                  // Bez blendingu
          d^ := s^;                                                             // Obyèejné kopírování
        Inc(d);
        Inc(s);
        end;
    d := Pointer(Integer(d) + (dst.width - (src_width + dst_xstart)) * dst.format); // Skoèí ukazatelem na konec øádku
    s := Pointer(Integer(s) + (src.width - (src_width + src_xstart)) * src.format);                         // Posun na první kopírovanı pixel v øádku
    end;
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
  t1 := AllocateTextureBuffer(256,256,4);           // Alokace pamìti pro první obrázek
  if ReadTextureData('Data/Monitor.raw',t1) = 0 then    // Nahraje data obrázku
    begin                                               // Nic se nenahrálo
    MessageBox(h_Wnd,'Could Not Read ''Monitor.raw'' Image Data','TEXTURE ERROR',MB_OK or MB_ICONINFORMATION);
    Result := false;
    exit;
    end;
  t2 := AllocateTextureBuffer(256,256,4);           // Alokace pamìti pro druhı obrázek
  if ReadTextureData('Data/GL.raw',t2) = 0 then     // Nahraje data obrázku
    begin                                           // Nic se nenahrálo
    MessageBox(h_Wnd,'Could Not Read ''GL.raw'' Image Data','TEXTURE ERROR',MB_OK or MB_ICONINFORMATION);
    Result := false;
    exit;
    end;                                            // Blitting obrázkù
  Blit(t2,                                          // Zdrojovı obrázek
        t1,                                         // Cílovı obrázek
        127,                                        // Levı horní bod kopírované oblasti
        127,                                        // Levı horní bod kopírované oblasti
        128,                                        // Šíøka kopírované oblasti
        128,                                        // Vıška kopírované oblasti
        64,                                         // Kam kopírovat (levı horní bod)
        64,                                         // Kam kopírovat (levı horní bod)
        1,                                          // Pouít blending?
        128);                                       // Hodnota alfy pøi blendingu
  BuildTexture(t1);                                 // Vytvoøí texturu
  DeallocateTexture(t1);                            // Uvolní pamì obrázkù
  DeallocateTexture(t2);                            
  glEnable(GL_TEXTURE_2D);                          // Zapne texturování
  glShadeModel(GL_SMOOTH);			                    // Povolí jemné stínování
  glClearColor(0.0, 0.0, 0.0, 0.0);	  	            // Èerné pozadí
  glClearDepth(1.0);				                        // Nastavení hloubkového bufferu
  glEnable(GL_DEPTH_TEST);			                    // Povolí hloubkové testování
  glDepthFunc(GL_LESS); 				                    // Typ hloubkového testování
  Result:=true;                                     // Inicializace probìhla v poøádku
end;


function DrawGLScene():bool;                            // Vykreslování
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);  // Smae obrazovku a hloubkovı buffer
  glLoadIdentity();	                                    // Reset matice
  glTranslatef(0.0,0.0,-10.0);                          // Pøesun do hloubky
  glRotatef(xrot,1.0,0.0,0.0);                          // Rotace
  glRotatef(yrot,0.0,1.0,0.0);
  glRotatef(zrot,0.0,0.0,1.0);
  glBindTexture(GL_TEXTURE_2D,texture);                 // Zvolí texturu
  glBegin(GL_QUADS);                                    // Zaèátek kreslení obdélníkù
    // Èelní stìna
    glNormal3f(0.0,0.0,1.0);
    glTexCoord2f(1.0,1.0); glVertex3f( 1.0, 1.0, 1.0);
    glTexCoord2f(0.0,1.0); glVertex3f(-1.0, 1.0, 1.0);
    glTexCoord2f(0.0,0.0); glVertex3f(-1.0,-1.0, 1.0);
    glTexCoord2f(1.0,0.0); glVertex3f( 1.0,-1.0, 1.0);
    // Zadní stìna
    glNormal3f(0.0,0.0,-1.0);
    glTexCoord2f(1.0,1.0); glVertex3f(-1.0, 1.0,-1.0);
    glTexCoord2f(0.0,1.0); glVertex3f( 1.0, 1.0,-1.0);
    glTexCoord2f(0.0,0.0); glVertex3f( 1.0,-1.0,-1.0);
    glTexCoord2f(1.0,0.0); glVertex3f(-1.0,-1.0,-1.0);
    // Horní stìna
    glNormal3f(0.0,1.0,0.0);
    glTexCoord2f(1.0,1.0); glVertex3f( 1.0, 1.0,-1.0);
    glTexCoord2f(0.0,1.0); glVertex3f(-1.0, 1.0,-1.0);
    glTexCoord2f(0.0,0.0); glVertex3f(-1.0, 1.0, 1.0);
    glTexCoord2f(1.0,0.0); glVertex3f( 1.0, 1.0, 1.0);
    // Dolní stìna
    glNormal3f(0.0,-1.0,0.0);
    glTexCoord2f(0.0,0.0); glVertex3f( 1.0,-1.0, 1.0);
    glTexCoord2f(1.0,0.0); glVertex3f(-1.0,-1.0, 1.0);
    glTexCoord2f(1.0,1.0); glVertex3f(-1.0,-1.0,-1.0);
    glTexCoord2f(0.0,1.0); glVertex3f( 1.0,-1.0,-1.0);
    // Pravá stìna
    glNormal3f(1.0,0.0,0.0);
    glTexCoord2f(1.0,0.0); glVertex3f( 1.0,-1.0,-1.0);
    glTexCoord2f(1.0,1.0); glVertex3f( 1.0, 1.0,-1.0);
    glTexCoord2f(0.0,1.0); glVertex3f( 1.0, 1.0, 1.0);
    glTexCoord2f(0.0,0.0); glVertex3f( 1.0,-1.0, 1.0);
    // Levá stìna
    glNormal3f(-1.0,0.0,0.0);
    glTexCoord2f(0.0,0.0); glVertex3f(-1.0,-1.0,-1.0);
    glTexCoord2f(1.0,0.0); glVertex3f(-1.0,-1.0, 1.0);
    glTexCoord2f(1.0,1.0); glVertex3f(-1.0, 1.0, 1.0);
    glTexCoord2f(0.0,1.0); glVertex3f(-1.0, 1.0,-1.0);
  glEnd();                                              // Konec kreslení
  xrot := xrot + 0.3;                                   // Zvìtší úhly rotace
  yrot := yrot + 0.2;
  zrot := zrot + 0.4;
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
          if not Active then WaitMessage;             // Je program neaktivní? // Èekej na zprávu a zatím nic nedìlej
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
        end;
    end;                                              // Konec smyèky while
  killGLwindow();                                     // Zavøe okno
  result:=msg.wParam;                                 // Ukonèení programu
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
end.

