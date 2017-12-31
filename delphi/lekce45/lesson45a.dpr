program lesson45a;

{   kÛd pro Delphi 7}

uses
  Windows,
  glaux,
  GL,
  Messages,
  SysUtils,
  OpenGL,
  NeHeGL in 'NeHeGL.pas';

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;
procedure glDeleteTextures(n: GLsizei; textures: PGLuint); stdcall; external 'opengl32';


type
  PFNGLBINDBUFFERARBPROC = procedure(target: GLenum; buffer: GLuint); stdcall;  // FunkËnÌ prototypy
  PFNGLDELETEBUFFERSARBPROC = procedure(n :GLsizei; const buffers: PGLuint); stdcall;
  PFNGLGENBUFFERSARBPROC = procedure(n :GLsizei; buffers: PGLuint); stdcall;
  PFNGLBUFFERDATAARBPROC = procedure(target: GLenum; size: integer; const data: pointer; usage: GLenum); stdcall;

  CVert = record
    x, y, z: GLfloat;
    end;

  CVec = CVert;

  CTexCoord = record
    u, v: GLfloat;
    end;

  CMesh = class
    public
      m_nVertexCount: integer;
      m_pVertices: array of CVert;
      m_pTexCoords: array of CTexCoord;
      m_nTextureId: GLuint;
      m_nVBOVertices: GLuint;
      m_nVBOTexCoords: GLuint;
      m_pTextureImage: PTAUX_RGBImageRec;
      constructor Create;
      destructor Destroy; override;
      function LoadHeightmap(szPath: PAnsiChar; flHeightScale, flResolution: GLfloat): boolean;
      function PtHeight(nX, nY: integer): GLfloat;
      procedure BuildVBOs;
    end;

const
  MESH_RESOLUTION = 4.0;                                        // PoËet pixel˘ na vertex
  MESH_HEIGHTSCALE = 1.0;                                       // MÏ¯Ìtko vyv˝öenÌ
  NO_VBOS = false;                                              // VypÌn· VBO
  GL_ARRAY_BUFFER_ARB = $8892;                                  // SymbolickÈ konstanty pot¯ebnÈ pro rozöÌ¯enÌ VBO
  GL_STATIC_DRAW_ARB = $88E4;

var
  g_window: PGL_Window;                                         // Okno
  g_keys: PKeys;                                                // Kl·vesy
  glGenBuffersARB: PFNGLGENBUFFERSARBPROC = nil;                // Generov·nÌ VBO jmÈna
  glBindBufferARB: PFNGLBINDBUFFERARBPROC = nil;                // ZvolenÌ VBO bufferu
  glBufferDataARB: PFNGLBUFFERDATAARBPROC = nil;                // Nahr·v·nÌ dat VBO
  glDeleteBuffersARB: PFNGLDELETEBUFFERSARBPROC = nil;          // Maz·nÌ VBO
  g_fVBOSupported: boolean = false;
  g_pMesh: CMesh = nil;
  g_flYRot: GLfloat = 0.0;
  g_nFPS: integer = 0;
  g_nFrames: integer = 0;
  g_dwLastFPS: DWORD = 0;
  



function IsExtensionSupported(szTargetExtension: string): boolean;              // Je rozöÌ¯enÌ podporov·no?                                 // Je rozöÌ¯enÌ EXT_fog_coord podporov·no?
var
  pszExtensions: string;
  pszWhere: integer;
begin
  pszWhere := Pos(' ',szTargetExtension);                                       // JmÈno by nemÏlo mÌt mezery
  if (pszWhere <> 0) or (szTargetExtension = '') then
    begin
    Result := false;                                                            // Nepodporov·no
    exit;
    end;
  pszExtensions := glGetString(GL_EXTENSIONS);                                  // ÿetÏzec s n·zvy rozöÌ¯enÌ
  if Pos(szTargetExtension,pszExtensions) = 0 then                              // NenÌ podporov·no?
    begin
    Result := false;
    exit;
    end;
  Result := true;                                                               // OK
end;

function Initialize(window: PGL_Window; key: PKeys): boolean;	                  // Inicializace OpenGL
begin
  g_window := window;                                                           // Okno
  g_keys := key;                                                                // Kl·vesnice
  g_pMesh := CMesh.Create;                                                      // Instance v˝ökovÈ mapy
  if not g_pMesh.LoadHeightmap('terrain.bmp',MESH_HEIGHTSCALE,MESH_RESOLUTION) then // Nahr·nÌ
    begin
    MessageBox(0,'Error Loading Heightmap','Error',MB_OK);
    Result := false;
    exit;
    end;
  if not NO_VBOS then
    begin
    g_fVBOSupported := IsExtensionSupported('GL_ARB_vertex_buffer_object');     // Test podpory VBO
    if g_fVBOSupported then                                                     // Je rozöÌ¯enÌ podporov·no?
      begin
      // Ukazatele na GL funkce
      glGenBuffersARB := wglGetProcAddress('glGenBuffersARB');
      glBindBufferARB := wglGetProcAddress('glBindBufferARB');
      glBufferDataARB := wglGetProcAddress('glBufferDataARB');
      glDeleteBuffersARB := wglGetProcAddress('glDeleteBuffersARB');
      g_pMesh.BuildVBOs;                                                        // Poslat data vertex˘ do pamÏti grafickÈ karty
      end;
    end
    else
    g_fVBOSupported := false;                                                   // Bez VBO
  // KlasickÈ nastavenÌ OpenGL
  glClearColor(0.0,0.0,0.0,0.5);
  glClearDepth(1.0);
  glDepthFunc(GL_LEQUAL);
  glEnable(GL_DEPTH_TEST);
  glShadeModel(GL_SMOOTH);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);
  glEnable(GL_TEXTURE_2D);
  glColor4f(1.0,1.0,1.0,1.0);
  Result := true;                                                               // OK
end;

procedure Deinitialize;                                                         // Deinicializace
begin
  if g_pMesh <> nil then
    begin
    glDeleteTextures(1,@g_pMesh.m_nTextureId);                                  // Smaûe texturu
    g_pMesh.Free;
    end;
  g_pMesh := nil;
end;

procedure Update(milliseconds: DWORD);                                // Aktualizace pohyb˘ ve scÈnÏ a stisk kl·ves
begin
  g_flYRot := g_flYRot + (milliseconds / 1000.0 * 25.0);	
  if g_keys.keyDown[VK_ESCAPE] then                                   // Kl·vesa ESC?
    TerminateApplication(g_window^);                                  // UkonËenÌ programu
  if g_keys.keyDown[VK_F1] then                                       // Kl·vesa F1?
    ToggleFullscreen(g_window^);                                      // P¯epnutÌ fullscreen/okno
end;

procedure Draw;                                                       // VykreslenÌ scÈny
var
  szTitle: string;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                // Smaûe obrazovku a hloubkov˝ buffer
  glLoadIdentity;	                                                    // Reset matice
  // ZÌsk·nÌ FPS
  if GetTickCount - g_dwLastFPS >= 1000 then                          // UbÏhla sekunda?
    begin
    g_dwLastFPS := GetTickCount;                                      // Aktualizace Ëasu pro dalöÌ mÏ¯enÌ
    g_nFPS := g_nFrames;                                              // UloûenÌ FPS
    g_nFrames := 0;                                                   // Reset ËÌtaËe
    szTitle := Format('Lesson 45: NeHe & Paul Frazee''s VBO Tut - %f Triangles, %d FPS',[g_pMesh.m_nVertexCount / 3,g_nFPS]);
    if g_fVBOSupported then                                           // PouûÌv·/nepouûÌv· VBO
      szTitle := szTitle + ', Using VBOs'
      else
      szTitle := szTitle + ', Not Using VBOs';
    SetWindowText(g_window.hWnd,PAnsiChar(szTitle));                  // NastavÌ titulek
    end;
  Inc(g_nFrames);                                                     // Inkrementace ËÌtaËe FPS
  glTranslatef(0.0,-220.0,0.0);                                       // P¯esun nad terÈn
  glRotatef(10.0,1.0,0.0,0.0);                                        // NaklonÏnÌ kamery
  glRotatef(g_flYRot,0.0,1.0,0.0);                                    // Rotace kamery
  glEnableClientState(GL_VERTEX_ARRAY);                               // Zapne vertex arrays
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);                        // Zapne texture coord arrays
  if g_fVBOSupported then                                             // Podporuje grafick· karta VBO?
    begin
    glBindBufferARB(GL_ARRAY_BUFFER_ARB,g_pMesh.m_nVBOVertices);
    glVertexPointer(3,GL_FLOAT,0,nil);                                // P¯edat NULL
    glBindBufferARB(GL_ARRAY_BUFFER_ARB,g_pMesh.m_nVBOTexCoords);
    glTexCoordPointer(2,GL_FLOAT,0,nil);                              // P¯edat NULL
    end
    else                                                              // ObyËejnÈ vertex arrays
    begin
    glVertexPointer(3,GL_FLOAT,0,g_pMesh.m_pVertices);                // Ukazatel na data vertex˘
    glTexCoordPointer(2,GL_FLOAT,0,g_pMesh.m_pTexCoords);             // Ukazatel na texturovÈ koordin·ty
    end;
  glDrawArrays(GL_TRIANGLES,0,g_pMesh.m_nVertexCount);                // VykreslenÌ vertex˘
  glDisableClientState(GL_VERTEX_ARRAY);                              // Vypne vertex arrays
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);                       // Vypne texture coord arrays
	glFlush;                                                            // Vypr·zdnÌ OpenGL renderovacÌ pipeline
end;

function WindowProc(hWnd: HWND;                                       // Handle okna
                 uMsg: UINT;                                          // Zpr·va pro okno
                 wParam: WPARAM;                                      // DoplÚkovÈ informace
                 lParam: LPARAM):                                     // DoplÚkovÈ informace
                                  LRESULT; stdcall;
var
  window: ^GL_Window;
  creation: ^CREATESTRUCT;
begin
  if uMsg = WM_SYSCOMMAND then                                        // SystÈmov˝ p¯Ìkaz
      case wParam of                                                  // Typ systÈmovÈho p¯Ìkazu
        SC_SCREENSAVE,SC_MONITORPOWER:                                // Pokus o zapnutÌ öet¯iËe obrazovky, Pokus o p¯echod do ˙spornÈho reûimu?
          begin
            Result := 0;                                              // Zabr·nÌ obojÌmu
            exit;
          end;
      end;
  window := Pointer(GetWindowLong(hWnd,GWL_USERDATA));
  case uMsg of                                                        // VÏtvenÌ podle p¯ÌchozÌ zpr·vy
    WM_CREATE:
      begin
      creation := Pointer(lParam);
      window := Pointer(creation.lpCreateParams);
      SetWindowLong(hWnd,GWL_USERDATA,Integer(window));
      Result := 0;
      end;
    WM_CLOSE:                                                         // Povel k ukonËenÌ programu
      begin
      TerminateApplication(window^);                                  // Poöle zpr·vu o ukonËenÌ
      Result := 0                                                     // N·vrat do hlavnÌho cyklu programu
      end;
    WM_SIZE:                                                          // ZmÏna velikosti okna
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
          ReshapeGL(LOWORD(lParam),HIWORD(lParam));                 // LoWord=äÌ¯ka, HiWord=V˝öka
          Result := 0;                                              // N·vrat do hlavnÌho cyklu programu
          end;
      end;
     // Result := 0;
      end;
    WM_KEYDOWN:                                                     // Stisk kl·vesy
      begin
      if (wParam >= 0) and (wParam <= 255) then
        begin
        window^.keys^.keyDown[wParam] := true;                      // Ozn·mÌ to programu
        Result := 0;
        end;
      //Result := 0;                                                // N·vrat do hlavnÌho cyklu programu
      end;
    WM_KEYUP:                                                       // UvolnÏnÌ kl·vesy
      begin
      if (wParam >= 0) and (wParam <= 255) then
        begin
    	  window^.keys^.keyDown[wParam] := false;                     // Ozn·mÌ to programu
        Result := 0;                                                // N·vrat do hlavnÌho cyklu programu
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
      // P¯ed·nÌ ostatnÌch zpr·v systÈmu
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
    style := CS_HREDRAW or CS_VREDRAW or CS_OWNDC;                  // P¯ekreslenÌ p¯i zmÏnÏ velikosti a vlastnÌ DC
    lpfnWndProc := @WindowProc;                                     // Definuje proceduru okna
    hInstance := application.hInstance;                             // Instance
    hbrBackground := COLOR_APPWORKSPACE;                            // PozadÌ nenÌ nutnÈ
    hCursor := LoadCursor(0,IDC_ARROW);                             // StandardnÌ kurzor myöi
    lpszClassName := PChar(application.className);                  // JmÈno t¯Ìdy okna
    end;
  if RegisterClassEx(windowClass) = 0 then                          // Registruje t¯Ìdu okna
    begin
    MessageBox(HWND_DESKTOP,'RegisterClassEx Failed!','Error',MB_OK or MB_ICONEXCLAMATION);
    Result := false;                                                // P¯i chybÏ vr·tÌ false
    exit;
    end;
  Result := true;
end;

function WinMain(hInstance: HINST;                                  // Instance
		 hPrevInstance: HINST;                                          // P¯edchozÌ instance
		 lpCmdLine: PChar;                                              // Parametry p¯ÌkazovÈ ¯·dky
		 nCmdShow: integer):                                            // Stav zobrazenÌ okna
                        integer; stdcall;
var
  app: Application;
  window: GL_Window;
  key: Keys;
  isMessagePumpActive: boolean;
  msg: TMsg;                                                        // Struktura zpr·v systÈmu
  tickCount: DWORD;
begin
  app.className := 'OpenGL';
  app.hInstance := hInstance;
  ZeroMemory(@window,Sizeof(window));
  with window do
    begin
    keys := @key;
    init.application := @app;
    init.title := 'Lesson 45: NeHe & Paul Frazee''s VBO Tut';
    init.width := 640;
    init.height := 480;
    init.bitsPerPixel := 16;
    init.isFullScreen := true;
    end;
  ZeroMemory(@key,Sizeof(key));
  // Dotaz na uûivatele pro fullscreen/okno
  if MessageBox(HWND_DESKTOP,'Would You Like To Run In FullScreen Mode?','Start FullScreen',
                MB_YESNO or MB_ICONQUESTION) = IDNO then
    window.init.isFullScreen := false;                                 // BÏh v oknÏ
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
          if PeekMessage(msg,0,0,0,PM_REMOVE) then                  // P¯iöla zpr·va?
            if msg.message <> WM_QUIT then                          // Obdrûeli jsme zpr·vu pro ukonËenÌ?
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

{ CMesh }

procedure CMesh.BuildVBOs;                                                      // Vytvo¯enÌ VBO
begin
  // VBO pro vertexy
  glGenBuffersARB(1,@m_nVBOVertices);                                           // ZÌsk·nÌ jmÈna (ID)
  glBindBufferARB(GL_ARRAY_BUFFER_ARB,m_nVBOVertices);                          // ZvolenÌ bufferu
  glBufferDataARB(GL_ARRAY_BUFFER_ARB,m_nVertexCount * 3 * sizeof(glfloat),m_pVertices,GL_STATIC_DRAW_ARB);
  // VBO pro texturovÈ koordin·ty
  glGenBuffersARB(1,@m_nVBOTexCoords);                                          // ZÌsk·nÌ jmÈna (ID)
  glBindBufferARB(GL_ARRAY_BUFFER_ARB,m_nVBOTexCoords);                         // ZvolenÌ bufferu
  glBufferDataARB(GL_ARRAY_BUFFER_ARB,m_nVertexCount * 2 * sizeof(glfloat),m_pTexCoords,GL_STATIC_DRAW_ARB);
  // Data v RAM uû jsou zbyteËn·
  SetLength(m_pVertices,0);
  SetLength(m_pTexCoords,0);
  m_pVertices := nil;
  m_pTexCoords := nil;
end;

constructor CMesh.Create;                                                       // Konstruktor
begin
  m_pTextureImage := nil;                                                       // Inicializace
	m_pVertices := nil;
	m_pTexCoords := nil;
	m_nVertexCount := 0;
	m_nVBOVertices := 0;
  m_nVBOTexCoords := 0;
  m_nTextureId := 0;
end;

destructor CMesh.Destroy;                                                       // Destruktor
var
  nBuffers: array [0..1] of GLuint;
begin
  // ZruöÌ VBO
	if g_fVBOSupported then
	  begin
		nBuffers[0] := m_nVBOVertices;
    nBuffers[1] := m_nVBOTexCoords;
		glDeleteBuffersARB(2,@nBuffers);						                                // UvolnÌ pamÏù
	  end;
	// Smaûe data
	if m_pVertices <> nil then											                              // UvolnÌ data Vertex˘
 		SetLength(m_pVertices,0);
	m_pVertices := nil;
	if m_pTexCoords <> nil then											                              // UvolnÌ data texturov˝ch koordin·t˘
 		SetLength(m_pTexCoords,0);
	m_pTexCoords := nil;
  inherited;
end;

function CMesh.LoadHeightmap(szPath: PAnsiChar; flHeightScale,
  flResolution: GLfloat): boolean;
var
  nX, nZ, nTri, nIndex: integer;                                                // PomocnÈ
  flX, flZ: GLfloat;
begin
  if not FileExists(szPath) then
    begin
    Result := false;
    exit;
    end;
  m_pTextureImage := auxDIBImageLoadA(szPath);                                  // Nahraje obr·zek
  // Generov·nÌ pole vertex˘
  m_nVertexCount := Trunc((m_pTextureImage.sizeX * m_pTextureImage.sizeY * 6) / (flResolution * flResolution));
  SetLength(m_pVertices,m_nVertexCount);                                        // Alokace pamÏti
  SetLength(m_pTexCoords,m_nVertexCount);
  nZ := 0;
  nIndex := 0;
  while nZ < m_pTextureImage.sizeY do
    begin
    nX := 0;
    while nX < m_pTextureImage.sizeX do
      begin
      for nTri := 0 to 5 do
        begin
        // V˝poËet x a z pozice bodu
        if (nTri = 1) or (nTri = 2) or (nTri = 5) then
          flX := nX + flResolution
          else
          flX := nX;
        if (nTri = 2) or (nTri = 4) or (nTri = 5) then
          flZ := nZ + flResolution
          else
          flZ := nZ;
        // NastavenÌ vertexu v poli
        m_pVertices[nIndex].x := flX - (m_pTextureImage.sizeX / 2);
        m_pVertices[nIndex].y := PtHeight(Trunc(flX),Trunc(flZ)) * flHeightScale;
        m_pVertices[nIndex].z := flZ - (m_pTextureImage.sizeY / 2);
        // NastavenÌ texturov˝ch koordin·t˘ v poli
        m_pTexCoords[nIndex].u := flX / m_pTextureImage.sizeX;
        m_pTexCoords[nIndex].v := flZ / m_pTextureImage.sizeY;
        Inc(nIndex);                                                            // Inkrementace indexu
        end;
      nX := nX + Trunc(flResolution);
      end;
    nZ := nZ + Trunc(flResolution);
    end;
  glGenTextures(1,m_nTextureId);                                                // OpenGL ID
  glBindTexture(GL_TEXTURE_2D,m_nTextureId);                                    // ZvolÌ texturu
  glTexImage2D(GL_TEXTURE_2D,0,3,m_pTextureImage.sizeX,m_pTextureImage.sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,m_pTextureImage.data); // Nahraje texturu do OpenGL
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);               // Line·rnÌ filtrov·nÌ
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
  Result := true;
end;

function CMesh.PtHeight(nX, nY: integer): GLfloat;                              // V˝öka na indexu
var
  nPos: integer;
  flR, flG, flB: GLubyte;
  tmp: PGLubyte;
begin
  // V˝poËet pozice v poli, oöet¯enÌ p¯eteËenÌ
  nPos := ((nX mod m_pTextureImage.sizeX) + ((nY mod m_pTextureImage.sizeY) * m_pTextureImage.sizeX)) * 3;
  tmp := Pointer(Integer(m_pTextureImage.data) + nPos);                         // Grabov·nÌ sloûek barvy
  flR := tmp^;
  tmp := Pointer(Integer(m_pTextureImage.data) + nPos + 1);
  flG := tmp^;
  tmp := Pointer(Integer(m_pTextureImage.data) + nPos + 2);
  flB := tmp^;
  Result := (0.299 * flR + 0.587 * flG + 0.114 * flB);                          // V˝poËet luminance
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );                  // Start programu
end.

