program lesson36a;

{   kód pro Delphi 7}

uses
  Windows,
  SysUtils,
  Messages,
  OpenGL,
  NeHeGL in 'NeHeGL.pas';

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;
procedure glDeleteTextures(n: GLsizei; textures: PGLuint); stdcall; external 'opengl32';
procedure glCopyTexImage2D(target: GLenum; level: GLint; internalFormat: GLenum; x, y: GLint; width, height: GLsizei; border: GLint); stdcall; external 'opengl32';

type
  TPoints = array [0..3,0..2] of GLfloat;               // Pole bodù

const                                                   // Svìtla
  global_ambient: array [0..3] of GLfloat = (0.2,0.2,0.2,1.0);
  light0pos: array [0..3] of GLfloat = (0.0,5.0,10.0,1.0);
	light0ambient: array [0..3] of GLfloat = (0.2,0.2,0.2,1.0);
	light0diffuse: array [0..3] of GLfloat = (0.3,0.3,0.3,1.0);
	light0specular: array [0..3] of GLfloat = (0.8,0.8,0.8,1.0);
	lmodel_ambient: array [0..3] of GLfloat = (0.2,0.2,0.2,1.0);
  glfMaterialColor: array [0..3] of GLfloat = (0.4,0.2,0.8,1.0);
  specular: array [0..3] of GLfloat = (1.0,1.0,1.0,1.0);

var
  g_window: PGL_Window;                                 // Okno
  g_keys: PKeys;                                        // Klávesy
  angle: GLfloat;                                       // Úhel rotace spirály
  vertexes: array [0..3,0..2] of GLfloat;               // Ètyøi body o tøech souøadnicích
  normal: array [0..2] of GLfloat;                      // Data normálového vektoru
  BlurTexture: GLuint;                                  // Textura


function EmptyTexture: GLuint;                                                  // Vytvoøí prázdnou texturu
var
  txtnumber: GLuint;                                                            // ID textury
  data: PGLuint;                                                                // Ukazatel na data obrázku
begin
  data := AllocMem(128*128*4*sizeof(GLuint));                                   // Alokace pamìti
  glGenTextures(1,txtnumber);                                                   // Jedna textura
  glBindTexture(GL_TEXTURE_2D,txtnumber);                                       // Zvolí texturu
  glTexImage2D(GL_TEXTURE_2D,0,4,128,128,0,GL_RGBA,GL_UNSIGNED_BYTE,data);      // Vytvoøení textury
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);               // Lineární filtrování pro zmenšení i zvìtšení
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
  FreeMem(data);                                                                // Uvolnìní pamìti
  Result := txtnumber;                                                          // Vrátí ID textury
end;

procedure ReduceToUnit(var vector: array of GLfloat);                           // Výpoèet normalizovaného vektoru (jednotková délka)
var
  length: GLfloat;                                                              // Délka vektoru
begin
  length := sqrt(sqr(vector[0]) + sqr(vector[1]) + sqr(vector[2]));             // Výpoèet souèasné délky vektoru
  if length = 0 then length := 1;                                               // Prevence dìlení nulou
  vector[0] := vector[0] / length;                                              // Vydìlení jednotlivých složek délkou
  vector[1] := vector[1] / length;
  vector[2] := vector[2] / length;
end;

procedure calcNormal(v: TPoints; var output: array of GLfloat);                 // Výpoèet normálového vektoru polygonu
const
  x = 0;                                                                        // Pomocné indexy do pole
  y = 1;
  z = 2;
var
  v1, v2: array [0..2] of GLfloat;                                              // Vektor 1 a vektor 2 (x,y,z)
begin
  v1[x] := v[0,x] - v[1,x];                                                     // Výpoèet vektoru z 1. bodu do 0. bodu
  v1[y] := v[0,y] - v[1,y];
  v1[z] := v[0,z] - v[1,z];
  v2[x] := v[1,x] - v[2,x];                                                     // Výpoèet vektoru z 2. bodu do 1. bodu
  v2[y] := v[1,y] - v[2,y];
  v2[z] := v[1,z] - v[2,z];
  // Výsledkem vektorového souèinu dvou vektorù je tøetí vektor, který je k nim kolmý
  output[x] := v1[y]*v2[z] - v1[z]*v2[y];
  output[y] := v1[z]*v2[x] - v1[x]*v2[z];
  output[z] := v1[x]*v2[y] - v1[y]*v2[x];
  ReduceToUnit(output);                                                         // Normalizace výsledného vektoru
end;

procedure ProcessHelix;                                                         // Vykreslí spirálu
var
  x, y, z: GLfloat;                                                             // Souøadnice x, y, z
  phi, theta, u, v: GLfloat;                                                    // Úhly
  r: GLfloat;                                                                   // Polomìr závitu
  twists: integer;                                                              // Závity
begin
  twists := 5;                                                                  // Pìt závitù
  glLoadIdentity;                                                               // Reset matice
  gluLookAt(0,5,50,0,0,0,0,1,0);                                                // Pozice oèí (0,5,50), støed scény (0,0,0), UP vektor na ose y
  glPushMatrix;                                                                 // Uložení matice
  glTranslatef(0,0,-50);                                                        // Padesát jednotek do scény
  glRotatef(angle/2.0,1,0,0);                                                   // Rotace na ose x
  glRotatef(angle/3.0,0,1,0);                                                   // Rotace na ose y
  glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE,@glfMaterialColor);     // Nastavení materiálù
  glMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR,@specular);
  r := 1.5;                                                                     // Polomìr
  phi := 0;
  theta := 0;
  glBegin(GL_QUADS);                                                            // Kreslení obdélníkù
  while phi <= 360 do                                                           // 360 stupòù v kroku po 20 stupních
    begin
    while theta <= 360*twists do                                                // 360 stupòù* poèet závitù po 20 stupních
      begin
      v := phi / 180.0 * 3.142;                                                 // Úhel prvního bodu (0)
      u := theta / 180.0 * 3.142;                                               // Úhel prvního bodu (0)
      x := (cos(u) * (2.0 + cos(v))) * r;                                       // Pozice x, y, z prvního bodu
      y := (sin(u) * (2.0 + cos(v))) * r;
      z := ((u - (2.0 * 3.142)) + sin(v)) * r;
      vertexes[0,0] := x;                                                       // Kopírování prvního bodu do pole
      vertexes[0,1] := y;
      vertexes[0,2] := z;
      v := phi / 180.0 * 3.142;                                                 // Úhel druhého bodu (0)
      u := (theta + 20) / 180.0 * 3.142;                                        // Úhel druhého bodu (20)
      x := (cos(u) * (2.0 + cos(v))) * r;                                       // Pozice x, y, z druhého bodu
      y := (sin(u) * (2.0 + cos(v))) * r;
      z := ((u - (2.0 * 3.142)) + sin(v)) * r;
      vertexes[1,0] := x;                                                       // Kopírování druhého bodu do pole
      vertexes[1,1] := y;
      vertexes[1,2] := z;
      v := (phi + 20) / 180.0 * 3.142;                                          // Úhel tøetího bodu (20)
      u := (theta + 20) / 180.0 * 3.142;                                        // Úhel tøetího bodu (20)
      x := (cos(u) * (2.0 + cos(v))) * r;                                       // Pozice x, y, z tøetího bodu
      y := (sin(u) * (2.0 + cos(v))) * r;
      z := ((u - (2.0 * 3.142)) + sin(v)) * r;
      vertexes[2,0] := x;                                                       // Kopírování tøetího bodu do pole
      vertexes[2,1] := y;
      vertexes[2,2] := z;
      v := (phi + 20) / 180.0 * 3.142;                                          // Úhel ètvrtého bodu (20)
      u := theta / 180.0 * 3.142;                                               // Úhel ètvrtého bodu (0)
      x := (cos(u) * (2.0 + cos(v))) * r;                                       // Pozice x, y, z ètvrtého bodu
      y := (sin(u) * (2.0 + cos(v))) * r;
      z := ((u - (2.0 * 3.142)) + sin(v)) * r;
      vertexes[3,0] := x;                                                       // Kopírování ètvrtého bodu do pole
      vertexes[3,1] := y;
      vertexes[3,2] := z;
      calcNormal(TPoints(vertexes),normal);                                     // Výpoèet normály obdélníku
      glNormal3f(normal[0],normal[1],normal[2]);                                // Poslání normály OpenGL
      // Rendering obdélníku
      glVertex3f(vertexes[0,0],vertexes[0,1],vertexes[0,2]);
      glVertex3f(vertexes[1,0],vertexes[1,1],vertexes[1,2]);
      glVertex3f(vertexes[2,0],vertexes[2,1],vertexes[2,2]);
      glVertex3f(vertexes[3,0],vertexes[3,1],vertexes[3,2]);
      theta := theta + 20.0;
      end;
    theta := 0;
    phi := phi + 20.0;
    end;
  glEnd;                                                                        // Konec kreslení
  glPopMatrix;                                                                  // Obnovení matice
end;

procedure ViewOrtho;                          // Nastavuje pravoúhlou projekci
begin
  glMatrixMode(GL_PROJECTION);                // Projekèní matice
  glPushMatrix;                               // Uložení matice
  glLoadIdentity;                             // Reset matice
  glOrtho(0,640,480,0,-1,1);                  // Nastavení pravoúhlé projekce
  glMatrixMode(GL_MODELVIEW);                 // Modelview matice
  glPushMatrix;                               // Uložení matice
  glLoadIdentity;                             // Reset matice
end;

procedure ViewPerspective;                    // Obnovení perspektivního módu
begin
  glMatrixMode(GL_PROJECTION);                // Projekèní matice
  glPopMatrix;                                // Obnovení matice
  glMatrixMode(GL_MODELVIEW);                 // Modelview matice
  glPopMatrix;                                // Obnovení matice
end;

procedure RenderToTexture;                                                      // Rendering do textury
begin
  glViewport(0,0,128,128);                                                      // Nastavení viewportu (odpovídá velikosti textury)
  ProcessHelix;                                                                 // Rendering spirály
  glBindTexture(GL_TEXTURE_2D,BlurTexture);                                     // Zvolí texturu
  glCopyTexImage2D(GL_TEXTURE_2D,0,GL_LUMINANCE,0,0,128,128,0);                 // Zkopíruje viewport do textury (od 0, 0 do 128, 128, bez okraje)
  glClearColor(0.0,0.0,0.5,0.5);                                                // Støednì modrá barva pozadí
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                          // Smaže obrazovku a hloubkový buffer
  glViewport(0,0,640,480);                                                      // Obnovení viewportu
end;

procedure DrawBlur(times: integer; inc: GLfloat);                     // Vykreslí rozmazaný obrázek
var
  spost: GLfloat;                                                     // Offset
  alphainc: GLfloat;                                                  // Rychlost blednutí pro alfa blending
  alpha: GLfloat;                                                     // Alpha
  num: integer;                                                       // Cyklus
begin
  spost := 0.0;                                                       // Poèáteèní offset souøadnic na textuøe
  alpha := 0.2;                                                       // Poèáteèní hodnota alfy
  glDisable(GL_TEXTURE_GEN_S);                                        // Vypne automatické generování texturových koordinátù
  glDisable(GL_TEXTURE_GEN_T);
  glEnable(GL_TEXTURE_2D);                                            // Zapne mapování textur
  glDisable(GL_DEPTH_TEST);                                           // Vypne testování hloubky
  glBlendFunc(GL_SRC_ALPHA,GL_ONE);                                   // Mód blendingu
  glEnable(GL_BLEND);                                                 // Zapne blending
  glBindTexture(GL_TEXTURE_2D,BlurTexture);                           // Zvolí texturu
  ViewOrtho;                                                          // Pøepne do pravoúhlé projekce
  alphainc := alpha / times;                                          // Hodnota zmìny alfy pøi jednom kroku
  glBegin(GL_QUADS);                                                  // Kreslení obdélníkù
  for num := 0 to times - 1 do                                        // Poèet krokù renderování skvrn
    begin
    glColor4f(1.0,1.0,1.0,alpha);                                     // Nastavení hodnoty alfy
    glTexCoord2f(0 + spost,1 - spost);                                // Texturové koordináty (0, 1)
    glVertex2f(0,0);                                                  // První vertex (0, 0)
    glTexCoord2f(0 + spost,0 + spost);                                // Texturové koordináty (0, 0)
    glVertex2f(0,480);                                                // Druhý vertex (0, 480)
    glTexCoord2f(1 - spost,0 + spost);                                // Texturové koordináty (1, 0)
    glVertex2f(640,480);                                              // Tøetí vertex (640, 480)
    glTexCoord2f(1 - spost,1 - spost);                                // Texturové koordináty (1, 1)
    glVertex2f(640,0);                                                // Ètvrtý vertex (640, 0)
    spost := spost + inc;                                             // Postupné zvyšování skvrn (zoomování do støedu textury)
    alpha := alpha - alphainc;                                        // Postupné snižování alfy (blednutí obrázku)
    end;
  glEnd;                                                              // Konec kreslení
  ViewPerspective;                                                    // Obnovení perspektivy
  glEnable(GL_DEPTH_TEST);                                            // Zapne testování hloubky
  glDisable(GL_TEXTURE_2D);                                           // Vypne mapování textur
  glDisable(GL_BLEND);                                                // Vypne blending
  glBindTexture(GL_TEXTURE_2D,0);                                     // Zrušení vybrané textury
end;

function Initialize(window: PGL_Window; key: PKeys): boolean;	        // Inicializace OpenGL
begin
  g_window := window;
  g_keys := key;
  angle := 0.0;
  BlurTexture := EmptyTexture;                                        // Prázdná textura
  glViewport(0,0,window.init.width,window.init.height);               // Okno
  glMatrixMode(GL_PROJECTION);                                        // Projekèní matice
  glLoadIdentity;                                                     // Reset
  gluPerspective(50,window.init.width / window.init.height,5,2000);   // Nastavení perspektivy
  glMatrixMode(GL_MODELVIEW);                                         // Modelová matice
	glLoadIdentity;                                                     // Reset
  glEnable(GL_DEPTH_TEST);			                                      // Povolí hloubkové testování
  glLightModelfv(GL_LIGHT_MODEL_AMBIENT,@lmodel_ambient);		          // Nastavení svìtel
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT,@global_ambient);
	glLightfv(GL_LIGHT0,GL_POSITION,@light0pos);
	glLightfv(GL_LIGHT0,GL_AMBIENT,@light0ambient);
	glLightfv(GL_LIGHT0,GL_DIFFUSE,@light0diffuse);
	glLightfv(GL_LIGHT0,GL_SPECULAR,@light0specular);
	glEnable(GL_LIGHTING);										                          // Zapne svìtla
	glEnable(GL_LIGHT0);
  glShadeModel(GL_SMOOTH);
  glMateriali(GL_FRONT,GL_SHININESS,128);
  glClearColor(0.0, 0.0, 0.0, 0.5);	  	                              // Èerné pozadí
  Result:=true;                                                       // Inicializace probìhla v poøádku
end;

procedure Deinitialize;                                               // Uvolnìní prostøedkù
begin
  glDeleteTextures(1,@BlurTexture);                                   // Smazání textur
end;

procedure Update(milliseconds: DWORD);                                // Aktualizace pohybù ve scénì a stisk kláves
begin
  if g_keys.keyDown[VK_ESCAPE] then                                   // Klávesa ESC?
    TerminateApplication(g_window^);                                  // Ukonèení programu
  if g_keys.keyDown[VK_F1] then                                       // Klávesa F1?
    ToggleFullscreen(g_window^);                                      // Pøepnutí fullscreen/okno
  angle := angle + milliseconds / 5.0;
end;

procedure Draw;                                                       // Vykreslení scény
begin
  glClearColor(0.0,0.0,0.0,0.5);                                      // Èerné pozadí
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                // Smaže obrazovku a hloubkový buffer
  glLoadIdentity;	                                                    // Reset matice
  RenderToTexture;                                                    // Rendering do textury
  ProcessHelix;                                                       // Rendering spirály
  DrawBlur(25,0.02);                                                  // Rendering blur efektu
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
    init.title := 'rIO And NeHe''s RadialBlur Tutorial.';
    init.width := 640;
    init.height := 480;
    init.bitsPerPixel := 32;
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

