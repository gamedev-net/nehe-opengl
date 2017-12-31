program lesson35a;

{   kód pro Delphi 7}

uses
  Windows,
  SysUtils,
  Messages,
  OpenGL,
  mplayer,
  vfw,
  NeHeGL in 'NeHeGL.pas';

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;
procedure glDeleteTextures(n: GLsizei; textures: PGLuint); stdcall; external 'opengl32';
procedure glCopyTexImage2D(target: GLenum; level: GLint; internalFormat: GLenum; x, y: GLint; width, height: GLsizei; border: GLint); stdcall; external 'opengl32';
procedure glTexSubImage2D(target: GLenum; level, xoffset, yoffset: GLint; width, height: GLsizei; format, atype: GLenum; const pixels: Pointer); stdcall; external 'opengl32';

var
  g_window: PGL_Window;                                 // Okno
  g_keys: PKeys;                                        // Klávesy
  angle: GLfloat;                                       // Úhel rotace objektu
  next: integer;                                        // Pro animaci
  frame: integer = 0;                                   // Aktuální snímek videa
  effect: integer;                                      // Zobrazený objekt
  env: boolean = true;                                  // Automaticky generovat texturové koordináty?
  bg: boolean = true;                                   // Zobrazovat pozadí?
  sp: boolean;                                          // Stisknut mezerník?
  ep: boolean;                                          // Stisknuto E?
  bp: boolean;                                          // Stisknuto B?
  psi: TAVIStreamInfo;                                  // Informace o datovém proudu videa
  pavi: IAVIStream;                                     // Handle proudu
  pgf: IGetFrame;                                       // Ukazatel na objekt GetFrame
  bmih: BITMAPINFOHEADER;                               // Hlavièka pro DrawDibDraw dekódování
  lastframe: integer;                                   // Poslední snímek proudu
  width: integer;                                       // Šíøka videa
  height: integer;                                      // Výška videa
  pdata: PGLubyte;                                      // Ukazatel na data textury
  mpf: integer;                                         // Doba zobrazení jednoho snímku (Milliseconds Per Frame)
  quadratic: GLUquadricObj;                             // Objekt quadraticu
  hdd: HDRAWDIB;                                        // Handle DIBu
  h_bitmap: HBITMAP;                                    // Handle bitmapy závislé na zaøízení
  h_dc: HDC;                                            // Kontext zaøízení
  data: Pointer = nil;                                  // Ukazatel na bitmapu o zmìnìné velikosti

procedure flipIt(buffer: Pointer);                                              // Prohodí èervenou a modrou složku pixelù v obrázku
{asm                                                                            // Asm kód mi nechodí korektnì, okno se pøi animaci neustále zavírá a znovu otvírá...
  mov ecx, 256*256                                                              // Zjistil jsem, že mi nìjakým zpùsobem zmìní hodnotu lokální promìnné isMessagePumpActive v proceduøe WinMain
  mov ebx, buffer                                                               // Kdyby nìkdo vìdìl proè, dejte mi prosím vìdìt. Pro mì je to záhadou.
@@loop :
  mov al,[ebx+0]
  mov ah,[ebx+2]
  mov [ebx+2],al
  mov [ebx+0],ah
  add ebx,3
  dec ecx
  jnz @@loop  }
var                                                                             // Klasika - jako pøi naèítání TGA textur
  i: integer;
  B, R: PGLubyte;
  temp: GLubyte;
begin
  for i := 0 to 256 * 256 - 1 do                                                // Prochází data obrázku
    begin
    B := Pointer(Integer(buffer) + i * 3);                                      // Ukazatel na B
    R := Pointer(Integer(buffer) + i * 3+2);                                    // Ukazatel na R
    temp := B^;                                                                 // B uložíme do pomocné promìnné
    B^ := R^;                                                                   // R je na správném místì
    R^ := temp;                                                                 // B je na správném místì
    end;
end;

procedure OpenAVI(szFile: LPCSTR);                                              // Otevøe AVI soubor
var
  title: PAnsiChar;                                                             // Pro vypsání textu do titulku okna
  bmi: BITMAPINFO;
begin
  AVIFileInit;                                                                  // Pøipraví knihovnu AVIFile na použití
  if AVIStreamOpenFromFile(pavi,szFile,streamtypeVIDEO,0,OF_READ,nil) <> 0 then // Otevøe AVI proud
    MessageBox(HWND_DESKTOP,'Failed To Open The AVI Stream','Error',MB_OK or MB_ICONEXCLAMATION); // Chybová zpráva
  AVIStreamInfo(pavi,psi,sizeof(psi));                                          // Naète informace o proudu
  width := psi.rcFrame.Right - psi.rcFrame.Left;                                // Výpoèet šíøky
  height := psi.rcFrame.Bottom - psi.rcFrame.Top;                               // Výpoèet výšky
  lastframe := AVIStreamLength(pavi);                                           // Poslední snímek proudu
  mpf := AVIStreamSampleToTime(pavi,lastframe) div lastframe;                   // Poèet milisekund na jeden snímek
  with bmih do
    begin
    biSize := sizeof(BITMAPINFOHEADER);                                         // Velikost struktury
    biPlanes := 1;                                                              // BiPlanes
    biBitCount := 24;                                                           // Poèet bitù na pixel
    biWidth := 256;                                                             // Šíøka bitmapy
    biHeight := 256;                                                            // Výška bitmapy
    biCompression := BI_RGB;                                                    // RGB mód
    end;
  bmi.bmiHeader := bmih;
  h_bitmap := CreateDIBSection(h_dc,bmi,DIB_RGB_COLORS,data,0,0);
  SelectObject(h_dc,h_bitmap);                                                  // Zvolí bitmapu do kontextu zaøízení
  pgf := AVIStreamGetFrameOpen(pavi,nil);                                       // Vytvoøí PGETFRAME použitím požadovaného módu
  if pgf = nil then                                                             // Neúspìch?
    MessageBox(HWND_DESKTOP,'Failed To Open The AVI Frame','Error',MB_OK or MB_ICONEXCLAMATION);
  title := PAnsiChar(Format('NeHe''s AVI Player: Width: %d, Height: %d, Frames: %d',[width,height,lastframe])); // Informace o videu (šíøka, výška, poèet snímkù)
  SetWindowText(g_window.hWnd,title);                                           // Modifikace titulku okna
end;

procedure GrabAVIFrame(frame: integer);                                               // Grabuje požadovaný snímek z proudu
var
  lpbi: PBitmapInfoHeader;                                                            // Hlavièka bitmapy
begin
  lpbi := AVIStreamGetFrame(pgf,frame);                                               // Grabuje data z AVI proudu
  pdata := Pointer(Integer(lpbi) + lpbi.biSize + lpbi.biClrUsed * sizeof(RGBQUAD));   // Ukazatel na data
  DrawDibDraw(hdd,h_dc,0,0,256,256,lpbi,pdata,0,0,width,height,0);                    // Konvertování obrázku na požadovaný formát
  flipIt(data);                                                                       // Prohodí R a B složku pixelù
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 256, 256, GL_RGB, GL_UNSIGNED_BYTE, data);  // Aktualizace textury
end;
 
procedure CloseAVI;                                                             // Zavøení AVI souboru
begin
  DeleteObject(h_bitmap);                                                       // Smaže bitmapu
  DrawDibClose(hdd);                                                            // Zavøe DIB
  //AVIStreamGetFrameClose(pgf);                                                  // Dealokace GetFrame zdroje - pøi použití hodí chybu, nevím proè
  //AVIStreamRelease(pavi);                                                       // Uvolnìní proudu - pøi použití hodí chybu, nevím proè
  AVIFileExit;                                                                  // Uvolnìní souboru
end;

function Initialize(window: PGL_Window; key: PKeys): boolean;	                  // Inicializace OpenGL
begin
  g_window := window;
  g_keys := key;
  h_dc := CreateCompatibleDC(0);                                                // Kontext zaøízení
  angle := 0.0;                                                                 // Na poèátku nulový úhel
  hdd := DrawDibOpen;                                                           // Kontext zaøízení DIBu
  glClearColor(0.0, 0.0, 0.0, 0.5);	  	                                        // Èerné pozadí
  glClearDepth(1.0);                                                            // Nastavení hloubkového bufferu
  glDepthFunc(GL_LEQUAL);                                                       // Typ testù hloubky
  glEnable(GL_DEPTH_TEST);			                                                // Povolí hloubkové testování
  glShadeModel(GL_SMOOTH);                                                      // Jemné stínování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);                             // Perspektivní korekce
  quadratic := gluNewQuadric;                                                   // Vytvoøí objekt quadraticu
  gluQuadricNormals(quadratic,GLU_SMOOTH);                                      // Normály
  gluQuadricTexture(quadratic,GL_TRUE);                                         // Texturové koordináty
  glEnable(GL_TEXTURE_2D);                                                      // Zapne texturování
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);              // Filtry textur
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
  glTexGeni(GL_S,GL_TEXTURE_GEN_MODE,GL_SPHERE_MAP);                            // Automatické generování koordinátù
  glTexGeni(GL_T,GL_TEXTURE_GEN_MODE,GL_SPHERE_MAP);
  OpenAVI('data/face2.avi');                                                    // Otevøení AVI souboru
  glTexImage2D(GL_TEXTURE_2D,0,GL_RGB,256,256,0,GL_RGB,GL_UNSIGNED_BYTE,data);  // Vytvoøení textury
  Result:=true;                                                                 // Inicializace probìhla v poøádku
end;

procedure Deinitialize;                                                         // Uvolnìní prostøedkù
begin
  CloseAVI;                                                                     // Zavøe AVI
end;

procedure Update(milliseconds: DWORD);                                // Aktualizace pohybù ve scénì a stisk kláves
begin
  if g_keys.keyDown[VK_ESCAPE] then                                   // Klávesa ESC?
    TerminateApplication(g_window^);                                  // Ukonèení programu
  if g_keys.keyDown[VK_F1] then                                       // Klávesa F1?
    ToggleFullscreen(g_window^);                                      // Pøepnutí fullscreen/okno
  if g_keys.keyDown[Ord(' ')] and not sp then                         // Mezerník
    begin
    sp := true;
    Inc(effect);                                                      // Následující objekt v øadì
    if effect > 3 then effect := 0;                                   // Pøeteèení?
    end;
  if  not g_keys.keyDown[Ord(' ')] then                               // Uvolnìní mezerníku
    sp := false;
  if g_keys.keyDown[Ord('B')] and not bp then                         // Klávesa B
    begin
    bp := true;
    bg := not bg;                                                     // Nastaví flag pro zobrazování pozadí
    end;
  if not g_keys.keyDown[Ord('B')] then                                // Uvolnìní B
    bp := false;
  if g_keys.keyDown[Ord('E')] and not ep then                         // Klávesa E
    begin
    ep := true;
    env := not env;                                                   // Nastaví flag pro automatické generování texturových koordinátù
    end;
  if not g_keys.keyDown[Ord('E')] then                                // Uvolnìní E
    ep := false;
  angle := angle + milliseconds / 60.0;                               // Aktualizace úhlu natoèení
  Inc(next,milliseconds);                                             // Zvìtšení next o uplynulý èas
  frame := next div mpf;                                              // Výpoèet aktuálního snímku
  if frame >= lastframe then                                          // Pøeteèení snímkù?
    begin
    frame := 0;                                                       // Pøetoèí video na zaèátek
    next := 0;                                                        // Nulování èasu
    end;
end;

procedure Draw;                                                       // Vykreslení scény
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                // Smaže obrazovku a hloubkový buffer
  GrabAVIFrame(frame);                                                // Nagrabuje požadovaný snímek videa
  if bg then                                                          // Zobrazuje se pozadí?
    begin
    glLoadIdentity;	                                                  // Reset matice
    glBegin(GL_QUADS);                                                // Vykreslování obdélníkù
      glTexCoord2f(1.0,1.0); glVertex3f( 11.0, 8.3,-20.0);
      glTexCoord2f(0.0,1.0); glVertex3f(-11.0, 8.3,-20.0);
      glTexCoord2f(0.0,0.0); glVertex3f(-11.0,-8.3,-20.0);
      glTexCoord2f(1.0,0.0); glVertex3f( 11.0,-8.3,-20.0);
    glEnd;
    end;
  glLoadIdentity;                                                     // Reset matice
  glTranslatef(0.0,0.0,-10.0);                                        // Posun do scény
  if env then                                                         // Zapnuto generování souøadnic textur?
    begin
    glEnable(GL_TEXTURE_GEN_S);
    glEnable(GL_TEXTURE_GEN_T);
    end;
  glRotatef(angle*2.3,1.0,0.0,0.0);                                   // Rotace
  glRotatef(angle*1.8,0.0,1.0,0.0);
  glTranslatef(0.0,0.0,2.0);                                          // Pøesun na novou pozici
  case effect of                                                      // Vìtvení podle efektu
    0: begin                                                          // Krychle
       glRotatef(angle*1.3,1.0,0.0,0.0);                              // Rotace
       glRotatef(angle*1.1,0.0,1.0,0.0);
       glRotatef(angle*1.2,0.0,0.0,1.0);
       glBegin(GL_QUADS);                                             // Kreslení obdélníkù
        // Èelní stìna
        glNormal3f(0.0,0.0,0.5);
        glTexCoord2f(0.0,0.0); glVertex3f(-1.0,-1.0,1.0);
        glTexCoord2f(1.0,0.0); glVertex3f( 1.0,-1.0,1.0);
        glTexCoord2f(1.0,1.0); glVertex3f( 1.0, 1.0,1.0);
        glTexCoord2f(0.0,1.0); glVertex3f(-1.0, 1.0,1.0);
        // Zadní stìna
        glNormal3f(0.0,0.0,-0.5);
        glTexCoord2f(1.0,0.0); glVertex3f(-1.0,-1.0,-1.0);
        glTexCoord2f(1.0,1.0); glVertex3f(-1.0, 1.0,-1.0);
        glTexCoord2f(0.0,1.0); glVertex3f( 1.0, 1.0,-1.0);
        glTexCoord2f(0.0,0.0); glVertex3f( 1.0,-1.0,-1.0);
        // Horní stìna
        glNormal3f(0.0,0.5,0.0);
        glTexCoord2f(0.0,1.0); glVertex3f(-1.0,1.0,-1.0);
        glTexCoord2f(0.0,0.0); glVertex3f(-1.0,1.0, 1.0);
        glTexCoord2f(1.0,0.0); glVertex3f( 1.0,1.0, 1.0);
        glTexCoord2f(1.0,1.0); glVertex3f( 1.0,1.0,-1.0);
        // Spodní stìna
        glNormal3f(0.0,-0.5,0.0);
        glTexCoord2f(1.0,1.0); glVertex3f(-1.0,-1.0,-1.0);
        glTexCoord2f(0.0,1.0); glVertex3f( 1.0,-1.0,-1.0);
        glTexCoord2f(0.0,0.0); glVertex3f( 1.0,-1.0, 1.0);
        glTexCoord2f(1.0,0.0); glVertex3f(-1.0,-1.0, 1.0);
        // Pravá stìna
        glNormal3f(0.5,0.0,0.0);
        glTexCoord2f(1.0,0.0); glVertex3f(1.0,-1.0,-1.0);
        glTexCoord2f(1.0,1.0); glVertex3f(1.0, 1.0,-1.0);
        glTexCoord2f(0.0,1.0); glVertex3f(1.0, 1.0, 1.0);
        glTexCoord2f(0.0,0.0); glVertex3f(1.0,-1.0, 1.0);
        // Levá stìna
        glNormal3f(-0.5,0.0,0.0);
        glTexCoord2f(0.0,0.0); glVertex3f(-1.0,-1.0,-1.0);
        glTexCoord2f(1.0,0.0); glVertex3f(-1.0,-1.0, 1.0);
        glTexCoord2f(1.0,1.0); glVertex3f(-1.0, 1.0, 1.0);
        glTexCoord2f(0.0,1.0); glVertex3f(-1.0, 1.0,-1.0);
       glEnd();
       end;
    1: begin                                                          // Koule
       glRotatef(angle*1.3,1.0,0.0,0.0);                              // Rotace
       glRotatef(angle*1.1,0.0,1.0,0.0);
       glRotatef(angle*1.2,0.0,0.0,1.0);
       gluSphere(quadratic,1.3,20,20);                                // Vykreslení koule
       end;
    2: begin                                                          // Válec
       glRotatef(angle*1.3,1.0,0.0,0.0);                              // Rotace
       glRotatef(angle*1.1,0.0,1.0,0.0);
       glRotatef(angle*1.2,0.0,0.0,1.0);
       glTranslatef(0.0,0.0,-1.5);                                    // Vycentrování
       gluCylinder(quadratic,1.0,1.0,3.0,32,32);                      // Vykreslení válce
       end;
    end;
  if env then                                                         // Zapnuto generování souøadnic textur?
    begin
    glDisable(GL_TEXTURE_GEN_S);
    glDisable(GL_TEXTURE_GEN_T);
    end;
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
    init.title := 'NeHe''s New GL Framework';
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


