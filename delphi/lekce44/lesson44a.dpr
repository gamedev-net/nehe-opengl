program lesson44a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages,
  OpenGL,
  SysUtils,
  Font in 'Font.pas',
  Camera in 'Camera.pas';

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;

const
  GL_BGR_EXT = $80E0;               // Opengl rozšíøení
  
var
  h_Rc: HGLRC;		                  // Trvalý Rendering Context
  h_Dc: HDC;                        // Privátní GDI Device Context
  h_Wnd: HWND;                      // Obsahuje Handle našeho okna
  keys: array [0..255] of BOOL;	    // Pole pro ukládání vstupu z klávesnice
  Active: bool = true;              // Ponese informaci o tom, zda je okno aktivní
  FullScreen:bool = true;           // Ponese informaci o tom, zda je program ve fullscreenu
  infoOn: boolean = false;          // Zobrazit výpis informací?
  gFrames: integer = 0;
  gStartTime: DWORD;                // Poèáteèní èas
  gCurrentTime: DWORD;
  gFPS: GLfloat;                    // Snímková frekvence
  gFont: glFont;                    // Font
  gCamera: glCamera;                // Kamera
  qobj: GLUquadricObj;              // Válec
  cylList: GLint;                   // Display list válce


function LoadTexture(szFileName: LPTSTR; var texid: GLuint): boolean;           // Vytvoøí texturu z bitmapového obrázku
var
  hBMP: HBITMAP;                                                                // Ukazatel na bitmapu
  BMP: BITMAP;                                                                  // Struktura bitmapy
begin
  glGenTextures(1,texid);                                                       // Vytvoøí texturu
  hBMP := LoadImage(GetModuleHandle(nil),szFileName,IMAGE_BITMAP,0,0,LR_CREATEDIBSECTION or LR_LOADFROMFILE);
  if hBMP = 0 then                                                              // Existuje bitmapa?
    begin
    Result := false;                                                            // Pokud ne, tak konec
    exit;
    end;
  GetObject(hBMP,sizeof(BMP),@BMP);                                             // Vyplní strukturu bitmapy
  glPixelStorei(GL_UNPACK_ALIGNMENT,4);							                            // Druh ukládání pixelù (Word / 4 Byty na pixel)
	glBindTexture(GL_TEXTURE_2D,texid);								                            // Zvolí aktuální texturu
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);	              // Lineální filtrování
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D,0,3,BMP.bmWidth,BMP.bmHeight,0,GL_BGR_EXT,GL_UNSIGNED_BYTE,BMP.bmBits);
	DeleteObject(hBMP);												                                    // Zruší objekt
	Result := true;													                                      // OK
end;

procedure ReSizeGLScene(Width: GLsizei; Height: GLsizei); // Zmìna velikosti a inicializace OpenGL okna
begin
  gCamera.m_WindowHeight := Height;                       // Nastaví velikost okna pro kameru
  gCamera.m_WindowWidth := Width;
  if (Height=0) then		                                  // Zabezpeèení proti dìlení nulou
     Height:=1;                                           // Nastaví výšku na jedna
  glViewport(0, 0, Width, Height);                        // Resetuje aktuální nastavení
  glMatrixMode(GL_PROJECTION);                            // Zvolí projekèní matici
  glLoadIdentity;                                         // Reset matice
  gluPerspective(45.0,Width/Height,1.0,1000.0);           // Výpoèet perspektivy
  glMatrixMode(GL_MODELVIEW);                             // Zvolí matici Modelview
  glLoadIdentity;                                         // Reset matice
end;


function InitGL:bool;	                                                          // Všechno nastavení OpenGL
var
  tex: GLuint;
begin
  tex := 0;
  glShadeModel(GL_SMOOTH);			                                                // Povolí jemné stínování
  glClearColor(0.0, 0.0, 0.0, 0.5);	  	                                        // Èerné pozadí
  glClearDepth(1.0);				                                                    // Nastavení hloubkového bufferu
  glEnable(GL_DEPTH_TEST);			                                                // Povolí hloubkové testování
  glDepthFunc(GL_LEQUAL);				                                                // Typ hloubkového testování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);                             // Nejlepší perspektivní korekce
  if LoadTexture('Art/Font.bmp',tex) then                                       // Nahraje texturu fontu
    begin
    gFont.SetFontTexture(tex);									                                // Nastaví texturu fontu
		gFont.SetWindowSize(1024,768);								                              // Velikost okna pro font
		gFont.BuildFont(1.0);                                                       // Vytvoøí font
    end
    else
    MessageBox(0,'Failed to load font texture.','Error',MB_OK);                 // Chyba
  gCamera.m_MaxHeadingRate := 1.0;								                              // Maximální hodnoty pro kameru
	gCamera.m_MaxPitchRate := 1.0;
	gCamera.m_HeadingDegrees := 0.0;
	if not LoadTexture('Art/HardGlow2.bmp',gCamera.m_GlowTexture) then            // Nahrání textur pro efekty
    begin
		MessageBox(0,'Failed to load Hard Glow texture.','Error',MB_OK);
		Result := false;
    exit;
    end;
	if not LoadTexture('Art/BigGlow3.bmp',gCamera.m_BigGlowTexture) then
    begin
		MessageBox(0,'Failed to load Big Glow texture.','Error',MB_OK);
    Result := false;
    exit;
    end;
	if not LoadTexture('Art/Halo3.bmp',gCamera.m_HaloTexture) then
    begin
		MessageBox(0,'Failed to load Halo texture.','Error',MB_OK);
    Result := false;
    exit;
    end;
	if not LoadTexture('Art/Streaks4.bmp',gCamera.m_StreakTexture) then
    begin
		MessageBox(0,'Failed to load Streaks texture.','Error',MB_OK);
    Result := false;
    exit;
    end;
	cylList := glGenLists(1);                                                     // Vytvoøí display list válce
	qobj := gluNewQuadric;
	gluQuadricDrawStyle(qobj,GLU_FILL);
	gluQuadricNormals(qobj,GLU_SMOOTH);
	glNewList(cylList,GL_COMPILE);
		glEnable(GL_COLOR_MATERIAL);
		glColor3f(0.0,0.0,1.0);
		glEnable(GL_LIGHT0);
		glEnable(GL_LIGHTING);
		glTranslatef(0.0,0.0,-2.0);
		gluCylinder(qobj,0.5,0.5,4.0,15,5);
		glDisable(GL_LIGHTING);
		glDisable(GL_LIGHT0);
		glDisable(GL_COLOR_MATERIAL);
	glEndList; 
	gStartTime := GetTickCount;										                                // Èas startu aplikace
  Result:=true;                                                                 // Inicializace probìhla v poøádku
end;
  
procedure DrawGLInfo;                                                           // Výpis informací
var
  modelMatrix: array [0..15] of GLfloat;                                        // Matice ModelView
  projMatrix: array [0..15] of GLfloat;                                         // Projekèní matice
  DiffTime: GLfloat;                                                            // Èasový rozdíl
  text: string;                                                                 // Pomocný øetìzec pro formátování textu
begin
	glGetFloatv(GL_PROJECTION_MATRIX,@projMatrix);				                        // Naète data projekèní matice
	glGetFloatv(GL_MODELVIEW_MATRIX,@modelMatrix);				                        // Naète data matice modelview
	// Výpis pozice kamery
	glColor4f(1.0,1.0,1.0,1.0);
	text := Format('m_Position............. = %.02f, %.02f, %.02f',[gCamera.m_Position.x,gCamera.m_Position.y,gCamera.m_Position.z]);
	gFont.glPrintf(10,720,1,text);
	// Výpis smìru kamery
	text := Format('m_DirectionVector...... = %.02f, %.02f, %.02f',[gCamera.m_DirectionVector.i,gCamera.m_DirectionVector.j,gCamera.m_DirectionVector.k]);
	gFont.glPrintf(10,700,1,text);
	// Výpis polohy svìtla
	text := Format('m_LightSourcePos....... = %.02f, %.02f, %.02f',[gCamera.m_LightSourcePos.x,gCamera.m_LightSourcePos.y,gCamera.m_LightSourcePos.z]);
	gFont.glPrintf(10,680,1,text);
	// Výpis prùseèíku
	text := Format('ptIntersect............ = %.02f, %.02f, %.02f',[gCamera.ptIntersect.x,gCamera.ptIntersect.y,gCamera.ptIntersect.x]);
	gFont.glPrintf(10,660,1,text);
	// Výpis vektoru svìtlo - kamera
	text := Format('vLightSourceToCamera... = %.02f, %.02f, %.02f',[gCamera.vLightSourceToCamera.i,gCamera.vLightSourceToCamera.j,gCamera.vLightSourceToCamera.k]);
	gFont.glPrintf(10,640,1,text);
	// Výpis vektoru svìtlo - prùseèík
	text := Format('vLightSourceToIntersect = %.02f, %.02f, %.02f',[gCamera.vLightSourceToIntersect.i,gCamera.vLightSourceToIntersect.j,gCamera.vLightSourceToIntersect.k]);
	gFont.glPrintf(10,620,1,text);
	// Matice ModelView
	text := 'GL_MODELVIEW_MATRIX';
	gFont.glPrintf(10,580,1,text);
	// 1. øádek
	text := Format('%.02f, %.02f, %.02f, %.02f',[modelMatrix[0],modelMatrix[1],modelMatrix[2],modelMatrix[3]]);
	gFont.glPrintf(10,560,1,text);
	// 2. øádek
	text := Format('%.02f, %.02f, %.02f, %.02f',[modelMatrix[4],modelMatrix[5],modelMatrix[6],modelMatrix[7]]);
	gFont.glPrintf(10,540,1,text);
	// 3. øádek
	text := Format('%.02f, %.02f, %.02f, %.02f',[modelMatrix[8],modelMatrix[9],modelMatrix[10],modelMatrix[11]]);
	gFont.glPrintf(10,520,1,text);
	// 4. øádek
	text := Format('%.02f, %.02f, %.02f, %.02f',[modelMatrix[12],modelMatrix[13],modelMatrix[14],modelMatrix[15]]);
	gFont.glPrintf(10,500,1,text);
	// Projekèní matice
	text := 'GL_PROJECTION_MATRIX';
	gFont.glPrintf(10,460,1,text);
	// 1. øádek
	text := Format('%.02f, %.02f, %.02f, %.02f',[projMatrix[0],projMatrix[1],projMatrix[2],projMatrix[3]]);
	gFont.glPrintf(10,440,1,text);
	// 2. øádek
	text := Format('%.02f, %.02f, %.02f, %.02f',[projMatrix[4],projMatrix[5],projMatrix[6],projMatrix[7]]);
	gFont.glPrintf(10,420,1,text);
	// 3. øádek
	text := Format('%.02f, %.02f, %.03f, %.03f',[projMatrix[8],projMatrix[9],projMatrix[10],projMatrix[11]]);
	gFont.glPrintf(10,400,1,text);
	// 4. øádek
	text := Format('%.02f, %.02f, %.03f, %.03f',[projMatrix[12],projMatrix[13],projMatrix[14],projMatrix[15]]);
	gFont.glPrintf(10,380,1,text);
	// Oøezávací roviny
	gFont.glPrintf(10,320,1,'FRUSTUM CLIPPING PLANES');
	// Pravá rovina
	text := Format('%.02f, %.02f, %.02f, %.02f',[gCamera.m_Frustum[0,0],gCamera.m_Frustum[0,1],gCamera.m_Frustum[0,2],gCamera.m_Frustum[0,3]]);
	gFont.glPrintf(10,300,1,text);
	// Levá rovina
	text := Format('%.02f, %.02f, %.02f, %.02f',[gCamera.m_Frustum[1,0],gCamera.m_Frustum[1,1],gCamera.m_Frustum[1,2],gCamera.m_Frustum[1,3]]);
	gFont.glPrintf(10,280,1,text);
	// Spodní rovina
	text := Format('%.02f, %.02f, %.02f, %.02f',[gCamera.m_Frustum[2,0],gCamera.m_Frustum[2,1],gCamera.m_Frustum[2,2],gCamera.m_Frustum[2,3]]);
	gFont.glPrintf(10,260,1,text);
	// Horní rovina
	text := Format('%.02f, %.02f, %.02f, %.02f',[gCamera.m_Frustum[3,0],gCamera.m_Frustum[3,1],gCamera.m_Frustum[3,2],gCamera.m_Frustum[3,3]]);
	gFont.glPrintf(10,240,1,text);
	// Zadní rovina
	text := Format('%.02f, %.02f, %.02f, %.02f',[gCamera.m_Frustum[4,0],gCamera.m_Frustum[4,1],gCamera.m_Frustum[4,2],gCamera.m_Frustum[4,3]]);
	gFont.glPrintf(10,220,1,text);
	// Pøední rovina
	text := Format('%.02f, %.02f, %.02f, %.02f',[gCamera.m_Frustum[5,0],gCamera.m_Frustum[5,1],gCamera.m_Frustum[5,2],gCamera.m_Frustum[5,3]]);
	gFont.glPrintf(10,200,1,text);
	if gFrames >= 100 then											                                  // Aktualizace FPS
    begin
		gCurrentTime := GetTickCount;							                                  // Aktuální èas
		DiffTime := gCurrentTime - gStartTime;			                                // Èasový rozdíl
		gFPS := (gFrames / DiffTime) * 1000.0;					                            // Výpoèet FPS
		gStartTime := gCurrentTime;								                                  // Uložení aktuálního èasu
		gFrames := 1;											                                          // Èítaè snímkù
	  end
	  else
		Inc(gFrames);												                                        // Zvýší èítaè
	// Výpis FPS
	text := Format('FPS %.02f',[gFPS]);
	gFont.glPrintf(10,160,1,text);
end;

procedure CheckKeys;
begin
  if keys[Ord('W')] then										// Stisk W?
		gCamera.ChangePitch(-0.2);
	if keys[Ord('S')] then										// Stisk S?
		gCamera.ChangePitch(0.2);
	if keys[Ord('D')] then										// Stisk D?
		gCamera.ChangeHeading(0.2);
	if keys[Ord('A')] then										// Stisk A?
		gCamera.ChangeHeading(-0.2);
	if keys[Ord('Z')] then										// Stisk Z?
		gCamera.m_ForwardVelocity := 0.01;
	if keys[Ord('C')] then										// Stisk C?
		gCamera.m_ForwardVelocity := -0.01;
	if keys[Ord('X')] then										// Stisk X?
		gCamera.m_ForwardVelocity := 0.0;
	if keys[Ord('1')] then										// Stisk 1?
		infoOn := true;
	if keys[Ord('2')] then										// Stisk 2?
		infoOn := false;											
end;

function DrawGLScene():bool;                                                    // Vykreslování
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                          // Smaže obrazovku a hloubkový buffer
  glLoadIdentity; 	                                                            // Reset matice
  gCamera.m_LightSourcePos.z := gCamera.m_Position.z - 50.0;                    // Svìtlo proti kameøe
  glPushMatrix;                                                                 // Vykreslení válce
  glLoadIdentity;
	glTranslatef(0.0,0.0,-20.0);
	glRotatef(GetTickCount / 50.0,0.3,0.0,0.0);
	glRotatef(GetTickCount / 50.0,0.0,0.5,0.0);
	glCallList(cylList);
	glPopMatrix;
	gCamera.SetPrespective;										                                    // Nastaví pohled na scénu
	gCamera.RenderLensFlare;										                                  // Vykreslí èoèkové efekty
	gCamera.UpdateFrustumFaster;									                                // Aktualizace oøezávacích rovin
	if infoOn then											                                          // Máme vykreslovat informace?
		DrawGLInfo;
	CheckKeys;                                                                    // Ošetøení stisknutých kláves
  Result := true;                                                               // Vykreslení probìhlo v poøádku
end;


function WndProc(hWnd: HWND;                            // Handle okna
                 message: UINT;                         // Zpráva pro okno
                 wParam: WPARAM;                        // Doplòkové informace
                 lParam: LPARAM):                       // Doplòkové informace
                                  LRESULT; stdcall;
begin
  if message=WM_SYSCOMMAND then                         // Systémový pøíkaz
    begin
      case wParam of                                    // Typ systémového pøíkazu
        SC_SCREENSAVE,SC_MONITORPOWER:                  // Pokus o zapnutí šetøièe obrazovky, Pokus o pøechod do úsporného režimu?
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
    	ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));     // LoWord=Šíøka, HiWord=Výška
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
  dwExStyle:dword;                // Rozšíøený styl okna
  dwStyle:dword;                  // Styl okna
  pfd: pixelformatdescriptor;     // Nastavení formátu pixelù
  dmScreenSettings: Devmode;      // Mód zaøízení
  h_Instance:hinst;               // Instance okna
  WindowRect: TRect;              // Obdélník okna
begin
  WindowRect.Left := 0;                               // Nastaví levý okraj na nulu
  WindowRect.Top := 0;                                // Nastaví horní okraj na nulu
  WindowRect.Right := width;                          // Nastaví pravý okraj na zadanou hodnotu
  WindowRect.Bottom := height;                        // Nastaví spodní okraj na zadanou hodnotu
  h_instance:=GetModuleHandle(nil);                   // Získá instanci okna
  FullScreen:=FullScreenflag;                         // Nastaví promìnnou fullscreen na správnou hodnotu
  with wc do
    begin
      style:=CS_HREDRAW or CS_VREDRAW or CS_OWNDC;    // Pøekreslení pøi zmìnì velikosti a vlastní DC
      lpfnWndProc:=@WndProc;                          // Definuje proceduru okna
      cbClsExtra:=0;                                  // Žádná extra data
      cbWndExtra:=0;                                  // Žádná extra data
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
	        dmPelsHeight := height;                     // Výška okna
          dmBitsPerPel := bits;                       // Barevná hloubka
          dmFields     := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
        end;
      // Pokusí se použít právì definované nastavení
      if (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN))<>DISP_CHANGE_SUCCESSFUL THEN
        Begin
          // Nejde-li fullscreen, mùže uživatel spustit program v oknì nebo ho opustit
          if MessageBox(0,'This FullScreen Mode Is Not Supported. Use Windowed Mode Instead?'
                                             ,'NeHe GL',MB_YESNO or MB_ICONEXCLAMATION)= IDYES then
                FullScreen:=false                     // Bìh v oknì
          else
            begin
              // Zobrazí uživateli zprávu, že program bude ukonèen
              MessageBox(0,'Program Will Now Close.','Error',MB_OK or MB_ICONERROR);
              Result:=false;                          // Vrátí FALSE
              exit;
            end;
          end;
    end;
  if FullScreen then                                  // Jsme stále ve fullscreenu?
    begin
      dwExStyle:=WS_EX_APPWINDOW;                     // Rozšíøený styl okna
      dwStyle:=WS_POPUP or WS_CLIPSIBLINGS or WS_CLIPCHILDREN; // Styl okna
      Showcursor(false);                              // Skryje kurzor
    end
  else
    begin
      dwExStyle:=WS_EX_APPWINDOW or WS_EX_WINDOWEDGE;   // Rozšíøený styl okna
      dwStyle:=WS_OVERLAPPEDWINDOW or WS_CLIPSIBLINGS or WS_CLIPCHILDREN; // Styl okna
    end;
  AdjustWindowRectEx(WindowRect,dwStyle,false,dwExStyle); // Pøizpùsobení velikosti okna
  // Vytvoøení okna
  H_wnd:=CreateWindowEx(dwExStyle,                    // Rozšíøený styl
                               'OpenGl',              // Jméno tøídy
                               Title,                 // Titulek
                               dwStyle,               // Definovaný styl
                               0,0,                   // Pozice
                               WindowRect.Right-WindowRect.Left,  // Výpoèet šíøky
                               WindowRect.Bottom-WindowRect.Top,  // Výpoèet výšky
                               0,                     // Žádné rodièovské okno
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
      cAlphaBits:= 0;                                 // Žádný alpha buffer
      cAlphaShift:= 0;                                // Ignorován Shift bit
      cAccumBits:= 0;                                 // Žádný akumulaèní buffer
      cAccumRedBits:= 0;                              // Akumulaèní bity ignorovány
      cAccumGreenBits:= 0;
      cAccumBlueBits:= 0;
      cAccumAlphaBits:= 0;
      cDepthBits:= 16;                                // 16-bitový hloubkový buffer (Z-Buffer)
      cStencilBits:= 0;                               // Žádný Stencil Buffer
      cAuxBuffers:= 0;                                // Žádný Auxiliary Buffer
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
  gCamera := glCamera.Create;
  gFont := glFont.Create;
  // Dotaz na uživatele pro fullscreen/okno
  if MessageBox(0,'Would You Like To Run In FullScreen Mode?','Start FullScreen',
                             MB_YESNO or MB_ICONQUESTION)=IDNO then
    FullScreen:=false                                 // Bìh v oknì
  else
    FullScreen:=true;                                 // Fullscreen
  if not CreateGLWindow('NeHe''s OpenGL Framework',640,480,32,FullScreen) then // Vytvoøení OpenGL okna
    begin
      Result := 0;                                    // Konec programu pøi chybì
      exit;
    end;
  while not done do                                   // Hlavní cyklus programu
    begin
      if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then  // Pøišla zpráva?
        begin
          if msg.message=WM_QUIT then                 // Obdrželi jsme zprávu pro ukonèení?
            done:=true                                // Konec programu
          else
            begin
	          TranslateMessage(msg);                    // Pøeloží zprávu
	          DispatchMessage(msg);                     // Odešle zprávu
	        end;
        end
      else      // Pokud nedošla žádná zpráva
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
        end;
    end;                                              // Konec smyèky while
  gluDeleteQuadric(qobj);                             // Smaže objekt válce
  glDeleteLists(cylList,1);                           // Smaže display list
  gCamera.Free;
  gFont.Free;
  killGLwindow();                                     // Zavøe okno
  result:=msg.wParam;                                 // Ukonèení programu
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
end.

