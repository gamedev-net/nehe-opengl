program lesson37a;

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

type
  MATRIX = record                                           // Ukládá OpenGL matici
    Data: array [0..15] of GLfloat;                         // Matice ve formátu OpenGL
    end;

  VECTOR = record                                           // Struktura vektoru
    X, Y, Z: GLfloat;                                       // Sloky vektoru
    end;

  VERTEX = record                                           // Struktura vertexu
    Nor: VECTOR;                                            // Normála vertexu
    Pos: VECTOR;                                            // Pozice vertexu
    end;

  POLYGON = record                                          // Struktura polygonu
    Verts: array [0..2] of VERTEX;                          // Pole tøí vertexù
    end;

var
  g_window: PGL_Window;                                     // Okno
  g_keys: PKeys;                                            // Klávesy
  outlineDraw: boolean = true;                              // Flag pro vykreslování obrysu
  outlineSmooth: boolean = false;                           // Flag pro vyhlazování èar
  outlineColor: array [0..2] of GLfloat = (0.0,0.0,0.0);    // Barva èar
  outlineWidth: GLfloat = 3.0;                              // Tlouška èar
  lightAngle: VECTOR;                                       // Smìr svìtla
  lightRotate: boolean = false;                             // Flag oznamující zda rotujeme svìtlem
  modelAngle: GLfloat = 0.0;                                // Úhel natoèení objektu na ose y
  modelRotate: boolean = false;                             // Flag na otáèení modelem
  polyData: array of POLYGON;                               // Data polygonù
  polyNum: integer = 0;                                     // Poèet polygonù
  shaderTexture: GLuint;                                    // Místo pro jednu texturu


function ReadMesh: boolean;                                                     // Naète obsah souboru model.txt
var
  vstup: file;
  precteno: integer;
begin
  AssignFile(vstup,'Data\model.txt');
  {$I-}
  Reset(vstup,1);                                                               // Otevøe soubor
  {$I+}
  if IOResult <> 0 then                                                         // Kontrola chyby otevøení
    begin
    Result := false;
    exit;
    end;
  BlockRead(vstup,polyNum,sizeof(integer),precteno);                            // Naète hlavièku souboru (poèet vertexù)
  SetLength(polyData,polyNum);                                                  // Alokace pamìti
  BlockRead(vstup,polyData[0],polyNum * sizeof(POLYGON),precteno);              // Naète všechna data
  CloseFile(vstup);                                                             // Zavøe soubor
  Result := true;                                                               // Loading objektu úspìšnı
end;

function DotProduct(V1, V2: VECTOR): GLfloat;                                   // Spoèítá odchylku dvou vektorù
begin
  Result := V1.X * V2.X + V1.Y * V2.Y + V1.Z * V2.Z;                            // Vrátí úhel
end;

function Magnitude(V: VECTOR): GLfloat;                                         // Spoèítá délku vektoru
begin
  Result := sqrt(sqr(V.X) + sqr(V.Y) + sqr(V.Z));                               // Vrátí délku vektoru
end;

procedure Normalize(var V: VECTOR);                                             // Vytvoøí jednotkovı vektor
var
  M: GLfloat;                                                                   // Délka vektoru
begin
  M := Magnitude(V);                                                            // Spoèítá aktuální délku vektoru
  if M <> 0 then                                                                // Proti dìlení nulou
    begin
    V.X := V.X / M;                                                             // Normalizování jednotlivıch sloek
    V.Y := V.Y / M;
    V.Z := V.Z / M;
    end;
end;

procedure RotateVector(M: MATRIX; V: VECTOR; var D: VECTOR);                    // Rotace vektoru podle zadané matice
begin
  D.X := (M.Data[0] * V.X) + (M.Data[4] * V.Y) + (M.Data[8] * V.Z);             // Otoèení na x
  D.Y := (M.Data[1] * V.X) + (M.Data[5] * V.Y) + (M.Data[9] * V.Z);             // Otoèení na y
  D.Z := (M.Data[2] * V.X) + (M.Data[6] * V.Y) + (M.Data[10] * V.Z);            // Otoèení na z
end;

function Initialize(window: PGL_Window; key: PKeys): boolean;	                  // Inicializace OpenGL
var
  i: integer;                                                                   // Øídící promìnná cyklù
  line: string;                                                                 // Pole znakù
  shaderData: array [0..31,0..2] of GLfloat;                                    // Pole 96 shader hodnot
  vstup: Textfile;                                                              // Ukazatel na soubor
begin
  g_window := window;
  g_keys := key;
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);                             // Perspektivní korekce
  glClearColor(0.7,0.7,0.7,0.0);                                                // Svìtle šedé pozadí
  glClearDepth(1.0);                                                            // Nastavení hloubkového bufferu
  glEnable(GL_DEPTH_TEST);			                                                // Povolí hloubkové testování
  glDepthFunc(GL_LESS);                                                         // Typ testování hloubky
  glShadeModel(GL_SMOOTH);                                                      // Jemné stínování
  glDisable(GL_LINE_SMOOTH);                                                    // Vypne vyhlazování èar
  glEnable(GL_CULL_FACE);                                                       // Zapne face culling (oøezávání stìn)
  glDisable(GL_LIGHTING);                                                       // Vypne svìtla
  AssignFile(vstup,'Data\shader.txt');
  {$I-}
  Reset(vstup);                                                                 // Otevøení shader souboru
  {$I+}
  if IOResult = 0 then                                                          // Kontrola, zda je soubor otevøen
    begin
    for i := 0 to 31 do                                                         // Projde všech 32 hodnot ve stupních šedi
      begin
      if Eof(vstup) then break;                                                 // Kontrola konce souboru
      Readln(vstup,line);                                                       // Získání aktuálního øádku
      shaderData[i,0] := StrToFloat(line);                                      // Zkopíruje danou hodnotu do všech sloek barvy
      shaderData[i,1] := shaderData[i,0];
      shaderData[i,2] := shaderData[i,0];
      end;
    CloseFile(vstup);                                                           // Zavøe soubor
    end
    else
    begin
    Result := false;                                                            // Neúspìch
    exit;
    end;
  glGenTextures(1,shaderTexture);                                               // Získání ID textury
  glBindTexture(GL_TEXTURE_1D,shaderTexture);                                   // Pøiøazení textury; od teï je 1D texturou
  // Nikdy nepouívejte bi-/trilinearní filtrování!
  glTexParameteri(GL_TEXTURE_1D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
  glTexParameteri(GL_TEXTURE_1D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
  glTexImage1D(GL_TEXTURE_1D,0,GL_RGB,32,0,GL_RGB,GL_FLOAT,@shaderData);        // Upload dat
  lightAngle.X := 0.0;                                                          // Nastavení smìru x
  lightAngle.Y := 0.0;                                                          // Nastavení smìru y
  lightAngle.Z := 1.0;                                                          // Nastavení smìru z
  Normalize(lightAngle);                                                        // Normalizování vektoru svìtla
  Result := ReadMesh;                                                           // Vrátí návratovou hodnotu funkce ReadMesh()
end;

procedure Deinitialize;                                                         // Deinicializace
begin
  glDeleteTextures(1,@shaderTexture);                                           // Smae shader texturu
  SetLength(polyData,0);                                                        // Uvolní data polygonù
end;

procedure Update(milliseconds: DWORD);                                // Aktualizace pohybù ve scénì a stisk kláves
begin
  if g_keys.keyDown[VK_ESCAPE] then                                   // Klávesa ESC?
    TerminateApplication(g_window^);                                  // Ukonèení programu
  if g_keys.keyDown[VK_F1] then                                       // Klávesa F1?
    ToggleFullscreen(g_window^);                                      // Pøepnutí fullscreen/okno
  if g_keys.keyDown[Ord(' ')] then                                    // Mezerník
    begin
    modelRotate := not modelRotate;                                   // Zapne/vypne rotaci objektu
    g_keys.keyDown[Ord(' ')] := FALSE;
    end;
  if g_keys.keyDown [Ord('1')] then                                   // Klávesa èísla 1
    begin
    outlineDraw := not outlineDraw;                                   // Zapne/vypne vykreslování obrysu
    g_keys.keyDown[Ord('1')] := FALSE;
    end;
  if g_keys.keyDown[Ord('2')] then                                    // Klávesa èíslo 2
    begin
    outlineSmooth := not outlineSmooth;                               // Zapne/vypne anti-aliasing
    g_keys.keyDown[Ord('2')] := FALSE;
    end;
  if g_keys.keyDown[VK_UP] then                                       // Šipka nahoru
    begin
    outlineWidth := outlineWidth + 1.0;                               // Zvìtší tloušku èáry
    g_keys.keyDown[VK_UP] := FALSE;
    end;
  if g_keys.keyDown[VK_DOWN] then                                     // Šipka dolù
    begin
    outlineWidth := outlineWidth - 1.0;                               // Zmenší tloušku èáry
    g_keys.keyDown[VK_DOWN] := FALSE;
    end;
  if modelRotate then                                                 // Je rotace zapnutá
    modelAngle := modelAngle + milliseconds / 10.0;                   // Aktualizace úhlu natoèení v závislosti na FPS
end;

procedure Draw;                                                       // Vykreslení scény
var
  i, j: integer;                                                      // Øídící promìnné cyklù
  TmpShade: GLfloat;                                                  // Doèasná hodnota stínu
  TmpMatrix: MATRIX;                                                  // Doèasná MATRIX struktura
  TmpVector, TmpNormal: VECTOR;                                       // Doèasné VECTOR struktury
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                // Smae obrazovku a hloubkovı buffer
  glLoadIdentity;	                                                    // Reset matice
  if outlineSmooth then                                               // Chce uivatel vyhlazené èáry?
    begin
    glHint(GL_LINE_SMOOTH_HINT,GL_NICEST);                            // Pouije nejkvalitnìjší vıpoèty
    glEnable(GL_LINE_SMOOTH);                                         // Zapne anti-aliasing
    end
    else
    glDisable(GL_LINE_SMOOTH);                                        // Vypne anti-aliasing
  glTranslatef(0.0,0.0,-2.0);                                         // Posun do hloubky
  glRotatef(modelAngle,0.0,1.0,0.0);                                  // Rotace objektem na ose y
  glGetFloatv(GL_MODELVIEW_MATRIX,@TmpMatrix.Data);                   // Získání matice
  // Kód Cel-Shadingu
  glEnable(GL_TEXTURE_1D);                                            // Zapne 1D texturování
  glBindTexture(GL_TEXTURE_1D,shaderTexture);                         // Zvolí texturu
  glColor3f(1.0,1.0,1.0);                                             // Nastavení barvy modelu (bílá)
  glBegin(GL_TRIANGLES);                                              // Zaèátek kreslení trojúhelníkù
    for i := 0 to polyNum - 1 do                                      // Prochází jednotlivé polygony
      for j := 0 to 2 do                                              // Prochází jednotlivé vertexy
        begin
        // Zkopírování aktuální normály do doèasné struktury
        TmpNormal.X := polyData[i].Verts[j].Nor.X;
        TmpNormal.Y := polyData[i].Verts[j].Nor.Y;
        TmpNormal.Z := polyData[i].Verts[j].Nor.Z;
        RotateVector(TmpMatrix,TmpNormal,TmpVector);                  // Otoèí vektor podle matice
        Normalize(TmpVector);                                         // Normalizace normály
        TmpShade := DotProduct(TmpVector,lightAngle);                 // Spoèítání hodnoty stínu
        if TmpShade < 0.0 then TmpShade := 0.0;                       // Pokud je TmpShade menší ne nula bude se rovnat nule
        glTexCoord1f(TmpShade);                                       // Nastavení texturovací souøadnice na hodnotu stínu
        glVertex3fv(@polyData[i].Verts[j].Pos.X);                     // Pošle pozici vertexu
        end;
  glEnd;                                                              // Konec kreslení
  glDisable(GL_TEXTURE_1D);                                           // Vypne 1D texturování
  // Kód pro vykreslení obrysù
  if outlineDraw then                                                 // Chceme vùbec kreslit obrys?
    begin
    glEnable(GL_BLEND);                                               // Zapne blending
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);                 // Mód blendingu
    glPolygonMode(GL_BACK,GL_LINE);                                   // Odvrácené polygony se stanout pouze obrysovımi èarami
    glLineWidth(outlineWidth);                                        // Nastavení šíøky èáry
    glCullFace(GL_FRONT);                                             // Nerenderovat pøivrácené polygony
    glDepthFunc(GL_LEQUAL);                                           // Mód testování hloubky
    glColor3fv(@outlineColor[0]);                                     // Barva obrysu (èerná)
    glBegin(GL_TRIANGLES);                                            // Zaèátek kreslení trojúhelníkù
      for i := 0 to polyNum - 1 do                                    // Prochází jednotlivé polygony
        for j := 0 to 2 do                                            // Prochází jednotlivé vertexy
          glVertex3fv(@polyData[i].Verts[j].Pos.X);                   // Pošle pozici vertexu
    glEnd;                                                            // Konec kreslení
    glDepthFunc(GL_LESS);                                             // Testování hloubky na pùvodní nastavení
    glCullFace(GL_BACK);                                              // Nastavení oøezávání na pùvodní hodnotu
    glPolygonMode(GL_BACK,GL_FILL);                                   // Normální vykreslování
    glDisable(GL_BLEND);                                              // Vypne blending
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
  if uMsg = WM_SYSCOMMAND then                                        // Systémovı pøíkaz
      case wParam of                                                  // Typ systémového pøíkazu
        SC_SCREENSAVE,SC_MONITORPOWER:                                // Pokus o zapnutí šetøièe obrazovky, Pokus o pøechod do úsporného reimu?
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
          ReshapeGL(LOWORD(lParam),HIWORD(lParam));                 // LoWord=Šíøka, HiWord=Vıška
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
    init.title := 'NeHe''s Cel-Shading Tutorial';
    init.width := 640;
    init.height := 480;
    init.bitsPerPixel := 16;
    init.isFullScreen := true;
    end;
  ZeroMemory(@key,Sizeof(key));
  // Dotaz na uivatele pro fullscreen/okno
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
            if msg.message <> WM_QUIT then                          // Obdreli jsme zprávu pro ukonèení?
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
  DecimalSeparator := '.';
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );                  // Start programu
  DecimalSeparator := ',';
end.

