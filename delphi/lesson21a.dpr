program lesson21a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages,
  OpenGL,sysutils,mmsystem,
  GLaux;

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

type
  gameobject = record                       // Struktura objektu ve høe
    fx, fy: integer;                        // Pohybová pozice
    x, y: integer;                          // Absolutní pozice
    spin: glfloat;                          // Otáèení objektu dokola
    end;
  timer = record                            // Informace pro èasovaè
    frequency: Int64;                       // Frekvence
    resolution: glfloat;                    // Perioda
    mm_timer_start: LongWord;               // Startovní èas multimediálního timeru
    mm_timer_elapsed: LongWord;             // Uplynulý èas multimediální timeru
    performance_timer: bool;                // Užíváme Performance Timer?
    performance_timer_start: Int64;         // Startovní èas Performance Timeru
    performance_timer_elapsed: Int64;       // Uplynulý èas Performance Timeru
    end;

var
  h_Rc: HGLRC;		                  // Trvalý Rendering Context
  h_Dc: HDC;                        // Privátní GDI Device Context
  h_Wnd: HWND;                      // Obsahuje Handle našeho okna
  keys: array [0..255] of BOOL;	    // Pole pro ukládání vstupu z klávesnice
  Active: bool = true;              // Ponese informaci o tom, zda je okno aktivní
  FullScreen:bool = true;           // Ponese informaci o tom, zda je program ve fullscreenu
  vline: array [0..10,0..9] of bool;// Ukládá záznamy o vertikálních linkách
  hline: array [0..9,0..10] of bool;// Ukládá záznamy o horizontálních linkách
  ap: bool;                         // Stisknuto 'A'?
  filled: bool;                     // Bylo ukonèeno vyplòování møížky?
  gameover: bool;                   // Konec hry?
  anti: bool = true;                // Antialiasing?
  loop1, loop2: integer;            // Øídící promìnné cyklù
  delay: integer;                   // Doba zastavení nepøátel
  adjust: integer = 3;              // Rychlostní kompenzace pro pomalé systémy
  lives: integer = 5;               // Poèet životù hráèe
  level: integer = 1;               // Vnitøní obtížnost hry
  level2: integer = 1;              // Zobrazovaný level
  stage: integer = 1;               // Etapa/fáze hry
  player: gameobject;               // Hráè
  enemy: array [0..8] of gameobject;// Nepøátelé
  hourglass: gameobject;            // Sklenìné hodiny
  steps: array [0..5] of integer = (1,2,4,5,10,20); // Krokovací hodnota pro pøizpùsobení pomalého videa
  texture: array [0..1] of gluint;  // Dvì textury
  base: gluint;                     // Základní display list pro font
  gametimer: timer;                 // Èasovaè

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
var TextureImage: array [0..1] of PTAUX_RGBImageRec;        // Ukládá bitmapu
    Status: Bool;                                           // Indikuje chyby
    i: integer;
begin
  Status := false;
  ZeroMemory(@TextureImage,sizeof(TextureImage));           // Vynuluje pamì
  TextureImage[0] := LoadBMP('Data/font.bmp');              // Nahraje bitmapu
  TextureImage[1] := LoadBMP('Data/image.bmp');
  if Assigned(TextureImage[0]) and Assigned(TextureImage[1]) then // Vše je bez problémù?
    begin
    Status := true;                                         // Vše je bez problémù
    glGenTextures(2,Texture[0]);                            // Generuje textury
    for i:=0 to 1 do
      begin
      glBindTexture(GL_TEXTURE_2D,texture[i]);
      glTexImage2D(GL_TEXTURE_2D,0,3,TextureImage[i].sizeX,TextureImage[i].sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage[i].data);
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
      end;
    end;
  Result := Status;                                         // Oznámí pøípadné chyby
end;

procedure TimerInit;                                            // Inicializace timeru
begin
  ZeroMemory(@gametimer,sizeof(gametimer));                     // Vynuluje promìnné struktury
  // Zjistí jestli je Performance Counter dostupný a pokud ano, bude naètena jeho frekvence
  if not QueryPerformanceFrequency(gametimer.frequency) then
    begin                                                       // Performance Counter není dostupný
    gametimer.performance_timer := false;                       // Nastaví Performance Timer na FALSE
    gametimer.mm_timer_start := timeGetTime;                    // Získání aktuálního èasu
    gametimer.resolution := 1/1000;                             // Nastavení periody
    gametimer.frequency := 1000;                                // Nastavení frekvence
    gametimer.mm_timer_elapsed := gametimer.mm_timer_start;     // Uplynulý èas = poèáteèní
    end
    else
    begin                                                       // Performance Counter je možné používat
    QueryPerformanceCounter(gametimer.performance_timer_start); // Poèáteèní èas
    gametimer.performance_timer := true;                        // Nastavení Performance Timer na TRUE
    gametimer.resolution := 1/gametimer.frequency;              // Spoèítání periody
    gametimer.performance_timer_elapsed := gametimer.performance_timer_start; //Nastaví uplynulý èas na poèáteèní
    end;
end;

function TimerGetTime: GLfloat;                                 // Získá èas v milisekundách
var time: Int64;                                                // Èas se ukládá do 64-bitového integeru
begin
  if gametimer.performance_timer then                           // Performance Timer
    begin
    QueryPerformanceCounter(time);                              // Naète aktuální èas
    Result := (time - gametimer.performance_timer_start)*gametimer.resolution*1000;     // Vrátí uplynulý èas v milisekundách
    end                                                                                 // Multimediální timer
    else Result := (timeGetTime - gametimer.mm_timer_start)*gametimer.resolution*1000;  // Vrátí uplynulý èas v milisekundách
end;

procedure ResetObjects;                                         // Reset hráèe a nepøátel
begin
  with player do                                                // Hráè
    begin
    x := 0;                                                     // Hráè bude vlevo nahoøe
    y := 0;                                                     // Hráè bude vlevo nahoøe
    fx := 0;                                                    // Pohybová pozice
    fy := 0;                                                    // Pohybová pozice
    end;
  for loop1:=0 to (stage*level)-1 do                            // Prochází nepøátele
    begin
    with enemy[loop1] do
      begin
      x := 5 + random(6);                                       // Nastaví randomovou x pozici
      y := random(11);                                          // Nastaví randomovou y pozici
      fx := x * 60;                                             // Pohybová pozice
      fy := y * 40;                                             // Pohybová pozice
      end;
    end;
end;

procedure BuildFont;                                            // Vytvoøení display listù fontu
var
  cx, cy: GLfloat;                                              // Koordináty x, y
  loop: integer;                                                // Cyklus
begin                                                           
  base := glGenLists(256);                                      // 256 display listù
  glBindTexture(GL_TEXTURE_2D,texture[0]);                      // Výbìr textury
  for loop:=0 to 255 do                                         // Vytváøí 256 display listù
    begin
    cx := (loop mod 16) / 16;                                   // X pozice aktuálního znaku
    cy := (loop div 16) /16;                                    // Y pozice aktuálního znaku
    glNewList(base + loop,GL_COMPILE);                          // Vytvoøení display listu
      glBegin(GL_QUADS);                                        // Pro každý znak jeden obdélník
        glTexCoord2f(cx,1-cy-0.0625);glVertex2i(0,16);
        glTexCoord2f(cx+0.0625,1-cy-0.0625);glVertex2i(16,16);
        glTexCoord2f(cx+0.0625,1-cy);glVertex2i(16,0);
        glTexCoord2f(cx,1-cy);glVertex2i(0,0);
      glEnd;                                                    // Konec znaku
      glTranslated(15,0,0);                                     // Pøesun na pravou stranu znaku
    glEndList;                                                  // Konec kreslení display listu
    end;
end;

procedure KillFont;                                             // Uvolní pamì fontu
begin
  glDeleteLists(base,256);                                      // Smaže 256 display listù
end;

procedure glPrint(x,y: GLint;text: string;sada: integer);       // Výpis textù
begin
  if text = '' then exit;                                       // Nebyl pøedán øetìzec
  if sada>1 then sada:=1;                                       // Byla pøedána špatná znaková sada? Pokud ano, zvolí se kurzíva
  glEnable(GL_TEXTURE_2D);                                      // Zapne texturové mapování
  glLoadIdentity;                                               // Reset matice
  glTranslated(x,y,0);                                          // Pøesun na požadovanou pozici
  glListBase(base-32+(128*sada));                               // Zvolí znakovou sadu
  if sada = 0 then glScalef(1.5,2.0,1.0);                       // Pokud je urèena první znaková sada font bude vìtší
  glCallLists(length(text),GL_UNSIGNED_BYTE,Pchar(text));       // Výpis textu na monitor
  glDisable(GL_TEXTURE_2D);                                     // Vypne texturové mapování
end;

procedure ReSizeGLScene(Width: GLsizei; Height: GLsizei); // Zmìna velikosti a inicializace OpenGL okna
begin
  if (Height=0) then		                                  // Zabezpeèení proti dìlení nulou
     Height:=1;                                           // Nastaví výšku na jedna
  glViewport(0, 0, Width, Height);                        // Resetuje aktuální nastavení
  glMatrixMode(GL_PROJECTION);                            // Zvolí projekèní matici
  glLoadIdentity();                                       // Reset matice
  glOrtho(0.0,Width,Height,0.0,-1.0,1.0);                 // Vytvoøí pravoúhlou scénu
  glMatrixMode(GL_MODELVIEW);                             // Zvolí matici Modelview
  glLoadIdentity;                                         // Reset matice
end;


function InitGL:bool;	                              // Všechno nastavení OpenGL
begin
  if not LoadGLTextures then                        // Nahraje textury
    begin
    Result := false;
    exit;
    end;
  BuildFont;                                        // Vytvoøení fontu
  glShadeModel(GL_SMOOTH);			                    // Povolí jemné stínování
  glClearColor(0.0, 0.0, 0.0, 0.5);	  	            // Èerné pozadí
  glClearDepth(1.0);				                        // Nastavení hloubkového bufferu
  glHint(GL_LINE_SMOOTH,GL_NICEST);                 // Nastavení antialiasingu linek
  glEnable(GL_BLEND);                               // Zapne blending
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); // Typ blendingu
  Result:=true;                                     // Inicializace probìhla v poøádku
end;


function DrawGLScene():bool;                            // Vykreslování
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);  // Smaže obrazovku a hloubkový buffer
  glBindTexture(GL_TEXTURE_2D,texture[0]);              // Zvolí texturu fontu
  glColor3f(1.0,0.5,1.0);                               // Purpurová barva
  glPrint(207,24,'CRAZY GRID',0);                       // Vypíše logo hry
  glColor3f(1.0,1.0,0.0);                               // Žlutá barva
  glPrint(20,20,Format('Level:%2d',[level2]),1);        // Vypíše level
  glPrint(20,40,Format('Stage:%2d',[stage]),1);         // Vypíše etapu
  if gameover then                                      // Konec hry?
    begin
    glColor3ub(random(255),random(255),random(255));    // Náhodná barva
    glPrint(472,20,'GAME OVER',1);                      // Vypíše GAME OVER
    glPrint(456,40,'PRESS SPACE',1);                    // Vypíše PRESS SPACE
    end;
  for loop1:=0 to lives-2 do                            // Cyklus vykreslující životy
    begin
    glLoadIdentity();	                                  // Reset matice
    glTranslatef(490+(loop1*40),40,0);                  // Pøesun doprava od titulku
    glRotatef(-player.spin,0.0,0.0,1.0);                // Rotace proti smìru hodinových ruèièek
    glColor3f(0.0,1.0,0.0);                             // Zelená barva
    glBegin(GL_LINES);                                  // Zaèátek kreslení životù
      glVertex2d(-5,-5);                                // Levý horní bod
      glVertex2d(5,5);                                  // Pravý dolní bod
      glVertex2d(5,-5);                                 // Pravý horní bod
      glVertex2d(-5,5);                                 // Levý dolní bod
    glEnd;                                              // Konec kreslení
    glRotatef(-player.spin*0.5,0.0,0.0,1.0);            // Rotace proti smìru hodinových ruèièek
    glColor3f(0.0,0.75,0.0);                            // Tmavší zelená barva
    glBegin(GL_LINES);                                  // Pokraèování kreslení životù
      glVertex2d(-7,0);                                 // Levý støedový bod
      glVertex2d(7,0);                                  // Pravý støedový bod
      glVertex2d(0,-7);                                 // Horní støedový bod
      glVertex2d(0,7);                                  // Dolní støedový bod
    glEnd;                                              // Konec kreslení
    end;
  filled := true;                                       // Pøed testem je všechno vyplnìné
  glLineWidth(2.0);                                     // Širší èáry
  glDisable(GL_LINE_SMOOTH);                            // Vypne antialiasing
  glLoadIdentity;                                       // Reset matice
  for loop1:=0 to 10 do                                 // Cyklus zleva doprava
    begin
    for loop2:=0 to 10 do                               // Cyklus ze shora dolù
      begin
      glColor3f(0.0,0.5,1.0);                           // Modrá barva
      if hline[loop1,loop2] then glColor3f(1.0,1.0,1.0);// Byla už linka pøejetá? Bílá barva
      if loop1 < 10 then                                // Nekreslit úplnì vpravo
        begin
        if not hline[loop1,loop2] then filled := false; // Nebyla linka ještì pøejetá? Všechno ještì není vyplnìno
        glBegin(GL_LINES);                              // Zaèátek kreslení horizontálních linek
          glVertex2d(20+(loop1*60),70+(loop2*40));      // Levý bod
          glVertex2d(80+(loop1*60),70+(loop2*40));      // Pravý bod
        glEnd;                                          // Konec kreslení
        end;
      glColor3f(0.0,0.5,1.0);                           // Modrá barva
      if vline[loop1,loop2] then glColor3f(1.0,1.0,1.0);// Byla už linka pøejetá? Bílá barva
      if loop2 < 10 then                                // Nekreslit úplnì dolù
        begin
        if not vline[loop1,loop2] then filled := false; // Nebyla linka ještì pøejetá? Všechno ještì nebylo vyplnìno
        glBegin(GL_LINES);                              // Zaèátek kreslení vertikálních linek
          glVertex2d(20+(loop1*60),70+(loop2*40));      // Horní bod
          glVertex2d(20+(loop1*60),110+(loop2*40));     // Dolní bod
        glEnd;                                          // Konec kreslení
        end;
      glEnable(GL_TEXTURE_2D);                          // Zapne mapování textur
      glColor3f(1.0,1.0,1.0);                           // Bílá barva
      glBindTexture(GL_TEXTURE_2D,texture[1]);          // Zvolí texturu
      if (loop1 < 10) and (loop2 < 10) then             // Pouze pokud je obdélník v hrací ploše
        begin
        // Jsou pøejety všechny ètyøi okraje obdélníku?
        if hline[loop1,loop2] and hline[loop1,loop2+1] and
            vline[loop1,loop2] and vline[loop1+1,loop2] then
          begin
          glBegin(GL_QUADS);                            // Vykreslí otexturovaný obdélník
            glTexCoord2f((loop1/10)+0.1,1-(loop2/10));
            glVertex2d(20+loop1*60+59,70+loop2*40+1);   // Pravý horní
            glTexCoord2f(loop1/10,1-(loop2/10));
            glVertex2d(20+loop1*60+1,70+loop2*40+1);    // Levý horní
            glTexCoord2f(loop1/10,1-loop2/10+0.1);
            glVertex2d(20+loop1*60+1,70+loop2*40+39);   // Levý dolní
            glTexCoord2f(loop1/10+0.1,1-loop2/10+0.1);
            glVertex2d(20+loop1*60+59,70+loop2*40+39);  // Pravý dolní
          glEnd;                                        // Konec kreslení
          end;
        end;
      glDisable(GL_TEXTURE_2D);                         // Vypne mapování textur
      end;
    end;
  glLineWidth(1.0);                                     // Šíøka èáry 1.0
  if anti then glEnable(GL_LINE_SMOOTH);                // Má být zapnutý antialiasing? Zapne antialiasing
  if hourglass.fx = 1 then                              // Hodiny se mají vykreslit
    begin
    glLoadIdentity;                                     // Reset Matice
    glTranslatef(20+hourglass.x*60,70+hourglass.y*40,0);// Umístìní
    glRotatef(hourglass.spin,0.0,0.0,1.0);              // Rotace ve smìru hodinových ruèièek
    glColor3ub(random(255),random(255),random(255));    // Náhodná barva
    glBegin(GL_LINES);                                  // Vykreslení pøesýpacích hodin
      glVertex2d(-5,-5);                                // Levý horní bod
      glVertex2d( 5, 5);                                // Pravý dolní bod
      glVertex2d( 5,-5);                                // Pravý horní bod
      glVertex2d(-5, 5);                                // Levý dolní bod
      glVertex2d(-5, 5);                                // Levý dolní bod
      glVertex2d( 5, 5);                                // Pravý dolní bod
      glVertex2d(-5,-5);                                // Levý horní bod
      glVertex2d( 5,-5);                                // Pravý horní bod
    glEnd();                                            // Konec kreslení
    end;
  glLoadIdentity;                                       // Reset Matice
  glTranslatef(20+player.fx,70+player.fy,0.0);          // Pøesun na pozici
  glRotatef(player.spin,0.0,0.0,1.0);                   // Rotace po smìru hodinových ruèièek
  glColor3f(0.0,1.0,0.0);                               // Zelená barva
  glBegin(GL_LINES);                                    // Vykreslení hráèe
    glVertex2d(-5,-5);                                  // Levý horní bod
    glVertex2d( 5, 5);                                  // Pravý dolní bod
    glVertex2d( 5,-5);                                  // Pravý horní bod
    glVertex2d(-5, 5);                                  // Levý dolní bod
  glEnd();                                              // Konec kreslení
  glRotatef(player.spin*0.5,0.0,0.0,1.0);               // Rotace po smìru hodinových ruèièek
  glColor3f(0.0,0.75,0.0);                              // Tmavší zelená barva
  glBegin(GL_LINES);                                    // Pokraèování kreslení hráèe
    glVertex2d(-7, 0);                                  // Levý støedový bod
    glVertex2d( 7, 0);                                  // Pravý støedový bod
    glVertex2d( 0,-7);                                  // Horní støedový bod
    glVertex2d( 0, 7);                                  // Dolní støedový bod
  glEnd();                                              // Konec kreslení
  for loop1:=0 to (stage*level)-1 do                    // Vykreslí nepøátele
    begin
    glLoadIdentity;                                     // Reset matice
    glTranslatef(20+enemy[loop1].fx,70+enemy[loop1].fy,0.0);  // Pøesun na pozici
    glColor3f(1.0,0.5,0.5);                             // Rùžová barva
    glBegin(GL_LINES);                                  // Vykreslení nepøátel
      glVertex2d( 0,-7);                                // Horní bod
      glVertex2d(-7, 0);                                // Levý bod
      glVertex2d(-7, 0);                                // Levý bod
      glVertex2d( 0, 7);                                // Dolní bod
      glVertex2d( 0, 7);                                // Dolní bod
      glVertex2d( 7, 0);                                // Pravý bod
      glVertex2d( 7, 0);                                // Pravý bod
      glVertex2d( 0,-7);                                // Horní bod
    glEnd();                                            // Konec kreslení
    glRotatef(enemy[loop1].spin,0.0,0.0,1.0);           // Rotace vnitøku nepøítele
    glColor3f(1.0,0.0,0.0);                             // Krvavá barva
    glBegin(GL_LINES);                                  // Pokraèování kreslení nepøátel
      glVertex2d(-7,-7);                                // Levý horní bod
      glVertex2d( 7, 7);                                // Pravý dolní bod
      glVertex2d(-7, 7);                                // Levý dolní bod
      glVertex2d( 7,-7);                                // Pravý horní bod
    glEnd();                                            // Konec kreslení
    end;
  Result := true;                                       // Vykreslení probìhlo v poøádku
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
  KillFont;                                             // Zruší font
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
  start: glfloat;
begin
  done:=false;
  // Dotaz na uživatele pro fullscreen/okno
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
  ResetObjects;                                       // Inicializuje pozici hráèe a nepøátel
  TimerInit;                                          // Zprovoznìní timeru
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
          start := TimerGetTime;                      // Nagrabujeme aktuální èas
          // Je program aktivní, ale nelze kreslit? Byl stisknut ESC?
          if (active and not(DrawGLScene()) or keys[VK_ESCAPE]) then
            done:=true                                // Ukonèíme program
          else                                        // Pøekreslení scény
            SwapBuffers(h_Dc);                        // Prohození bufferù (Double Buffering)
          while (TimerGetTime < start + steps[adjust]*2.0) do
            begin
            // Plýtvá cykly procesoru na rychlých systémech
            end;
          if keys[VK_F1] then                         // Byla stisknuta klávesa F1?
            begin
            Keys[VK_F1] := false;                     // Oznaè ji jako nestisknutou
            KillGLWindow();                           // Zruší okno
            FullScreen := not FullScreen;             // Negace fullscreen
            // Znovuvytvoøení okna
            if not CreateGLWindow('NeHe''s OpenGL Framework',640,480,16,fullscreen) then
              Result := 0;                            // Konec programu pokud nebylo vytvoøeno
            end;
          if (keys[ord('A')] and not(ap)) then        // Stisk A
            begin
            ap := TRUE;                               // Nastaví pøíznak
            anti := not(anti);                        // Zapne/vypne antialiasing
            end;
          if not(keys[ord('A')]) then ap := FALSE;    // Uvolnìní A
          if (not(gameover) and active) then          // Není-li konec hry a okno je aktivní
            begin
            for loop1 := 0 to (stage*level) - 1 do    // Prochází všechny nepøátele
              begin
              if ((enemy[loop1].x<player.x) and (enemy[loop1].fy=enemy[loop1].y*40)) then enemy[loop1].x := enemy[loop1].x + 1;   // Pøesun o políèko doprava
              if ((enemy[loop1].x>player.x) and (enemy[loop1].fy=enemy[loop1].y*40)) then enemy[loop1].x := enemy[loop1].x - 1;   // Pøesun o políèko doleva
              if ((enemy[loop1].y<player.y) and (enemy[loop1].fx=enemy[loop1].x*60)) then enemy[loop1].y := enemy[loop1].y + 1;   // Pøesun o políèko dolù
              if ((enemy[loop1].y>player.y) and (enemy[loop1].fx=enemy[loop1].x*60)) then enemy[loop1].y := enemy[loop1].y - 1;   // Pøesun o políèko nahoru
              if ((delay >(3-level)) and (hourglass.fx <> 2)) then              // Hráè nesebral pøesýpací hodiny
                begin
                delay := 0;                                                     // Reset delay na nulu
                for loop2 := 0 to (stage*level) - 1 do                          // Prochází všechny nepøátele
                  begin
                  if (enemy[loop2].fx<enemy[loop2].x*60) then                   // Fx je menší než x
                    begin
                    enemy[loop2].fx := enemy[loop2].fx + steps[adjust];         // Zvýšit fx
                    enemy[loop2].spin := enemy[loop2].spin + steps[adjust];     // Rotace ve smìru hodinových ruèièek
                    end;
                  if (enemy[loop2].fx>enemy[loop2].x*60) then                   // Fx je vìtší než x
                    begin
                    enemy[loop2].fx := enemy[loop2].fx - steps[adjust];         // Snížit fx
                    enemy[loop2].spin := enemy[loop2].spin - steps[adjust];     // Rotace proti smìru hodinových ruèièek
                    end;
                  if (enemy[loop2].fy<enemy[loop2].y*40) then                   // Fy je menší než y
                    begin
                    enemy[loop2].fy := enemy[loop2].fy + steps[adjust];         // Zvýšit fy
                    enemy[loop2].spin := enemy[loop2].spin + steps[adjust];     // Rotace ve smìru hodinových ruèièek
                    end;
                  if (enemy[loop2].fy>enemy[loop2].y*40) then                   // Fy je vìtší než y
                    begin
                    enemy[loop2].fy := enemy[loop2].fy - steps[adjust];         // Snížit fy
                    enemy[loop2].spin := enemy[loop2].spin - steps[adjust];     // Rotace proti smìru hodinových ruèièek
                    end;
                  end;
                end;
              // Setkání nepøítele s hráèem
              if ((enemy[loop1].fx = player.fx) and (enemy[loop1].fy = player.fy)) then
                begin
                lives := lives - 1;                                             // Hráè ztrácí život
                if (lives = 0) then gameover := TRUE;                           // Nulový poèet životù - Konec hry
                ResetObjects();                                                 // Reset pozice hráèe a nepøátel
                PlaySound('Data/Die.wav', 0, SND_SYNC);                         // Zahraje umíráèek
                end;
              end;
            if (keys[VK_RIGHT] and (player.x<10) and (player.fx =player.x*60) and (player.fy= player.y*40)) then
              begin
              hline[player.x][player.y] := TRUE;                                // Oznaèení linky
              player.x := player.x + 1;                                         // Doprava
              end;
            if (keys[VK_LEFT] and (player.x>0) and (player.fx =player.x*60) and (player.fy= player.y*40)) then
              begin
              player.x := player.x - 1;                                         // Doleva
              hline[player.x][player.y] := TRUE;                                // Oznaèení linky
              end;
            if (keys[VK_DOWN] and (player.y<10) and (player.fx =player.x*60) and (player.fy= player.y*40)) then
              begin
              vline[player.x][player.y] := TRUE;                                // Oznaèení linky
              player.y := player.y + 1;                                         // Dolù
              end;
            if (keys[VK_UP] and (player.y>0) and (player.fx =player.x*60) and (player.fy= player.y*40)) then
              begin
              player.y := player.y - 1;                                         // Nahoru
              vline[player.x][player.y] := TRUE;                                // Oznaèení linky
              end;
            if (player.fx<player.x*60) then                                     // Fx je menší než x
              begin
              player.fx := player.fx + steps[adjust];                           // Zvìtší fx
              end;
            if (player.fx>player.x*60) then                                     // Fx je vìtší než x
              begin
              player.fx := player.fx - steps[adjust];                           // Zmenší fx
              end;
            if (player.fy<player.y*40) then                                     // Fy je menší než y
              begin
              player.fy := player.fy + steps[adjust];                           // Zvìtší fy
              end;
            if (player.fy>player.y*40) then                                     // Fy je vìtší než y
              begin
              player.fy := player.fy - steps[adjust];                           // Zmenší fy
              end;
            end
            else                                                                // Jinak (if (not(gameover) and active))
            begin
            if (keys[ord(' ')]) then                                            // Stisknutý mezerník
              begin
              gameover := FALSE;                                                // Konec hry
              filled := TRUE;                                                   // Møížka vyplnìná
              level := 1;                                                       // Level
              level2 := 1;                                                      // Zobrazovaný level
              stage := 0;                                                       // Obtížnost hry
              lives := 5;                                                       // Poèet životù
              end;
            end;
          if (filled) then                                                      // Vyplnìná møížka?
            begin
            PlaySound('Data/Complete.wav', 0, SND_SYNC);                        // Zvuk ukonèení levelu
            stage := stage + 1;                                                 // Inkrementace obtížnosti
            if (stage>3) then                                                   // Je vìtší než tøi?
              begin
              stage := 1;                                                       // Reset na jednièku
              level := level + 1;                                               // Zvìtší level
              level2 := level2 + 1;                                             // Zvìtší zobrazovaný level
              if (level>3) then                                                 // Je level vìtší než tøi?
                begin
                level := 3;                                                     // Vrátí ho zpátky na tøi
                lives := lives + 1;                                             // Život navíc
                if (lives>5) then lives := 5;                                   // Má víc životù než pìt? Maximální poèet životù pìt
                end;
              end;
            ResetObjects();                                                     // Reset pozice hráèe a nepøátel
            for loop1 := 0 to 10 do                                             // Cyklus skrz x koordináty møížky
              for loop2 := 0 to 10 do                                           // Cyklus skrz y koordináty møížky
                begin
                if (loop1<10) then hline[loop1][loop2] := FALSE;                // X musí být menší než deset - Nulování
                if (loop2<10) then vline[loop1][loop2] := FALSE;                // Y musí být menší než deset - Nulování
                end;
            end;
          // Hráè sebral pøesýpací hodiny
          if ((player.fx = hourglass.x*60) and (player.fy = hourglass.y*40) and (hourglass.fx = 1)) then
            begin
            PlaySound('Data/freeze.wav', 0, SND_ASYNC or SND_LOOP);             // Zvuk zmrazení
            hourglass.fx := 2;                                                  // Skryje hodiny
            hourglass.fy := 0;                                                  // Nuluje èítaè
            end;
          player.spin := player.spin + 0.5*steps[adjust];                       // Rotace hráèe
          if (player.spin>360.0) then player.spin := player.spin - 360;         // Úhel je vìtší než 360°? Odeète 360
          hourglass.spin := hourglass.spin - 0.25*steps[adjust];                // Rotace pøesýpacích hodin
          if (hourglass.spin<0.0) then hourglass.spin := hourglass.spin + 360.0;// Úhel je menší než 0°? Pøiète 360
          hourglass.fy := hourglass.fy + steps[adjust];                         // Zvìtšení hodnoty èítaèe pøesýpacích hodin
          if ((hourglass.fx = 0) and (hourglass.fy>6000/level)) then            // Hodiny jsou skryté a pøetekl èítaè
            begin
            PlaySound('Data/hourglass.wav', 0, SND_ASYNC);                      // Zvuk zobrazení hodin
            hourglass.x := random(10) + 1;                                      // Náhodná pozice
            hourglass.y := random(11);                                          // Náhodná pozice
            hourglass.fx := 1;                                                  // Zobrazení hodin
            hourglass.fy := 0;                                                  // Nulování èítaèe
            end;
          if ((hourglass.fx = 1) and (hourglass.fy>6000/level)) then            // Hodiny jsou zobrazené a pøetekl èítaè
            begin
            hourglass.fx := 0;                                                  // Skrýt hodiny
            hourglass.fy := 0;                                                  // Nulování èítaèe
            end;
          if ((hourglass.fx = 2) and (hourglass.fy>500+(500*level))) then       // Nepøátelé zmrazení a pøetekl èítaè
            begin
            PlaySound(nil, 0, 0);                                               // Vypne zvuk zmrazení
            hourglass.fx := 0;                                                  // Skrýt hodiny
            hourglass.fy := 0;                                                  // Nulování èítaèe
            end;
          delay := delay + 1;                                                   // Inkrementuje èítaè zpoždìní nepøátel
        end;
    end;                                              // Konec smyèky while
  killGLwindow();                                     // Zavøe okno
  result:=msg.wParam;                                 // Ukonèení programu
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
end.

