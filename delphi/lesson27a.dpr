program lesson27a;

{   kód pro Delphi 7}

uses
  Windows,
  Messages, sysutils,
  OpenGL;

type
  sPoint = record                             // Souøadnice bodu nebo vektoru
    x, y, z: GLfloat;
    end;

  sPlaneEq = record                           // Rovnice roviny
    a, b, c, d: GLfloat;                      // Ve tvaru ax + by + cz + d = 0
    end;

  sPlane = record                             // Popisuje jeden face objektu
    p: array [0..2] of GLuint;                // Indexy 3 vertexù v objektu, které vytváøejí tento face
    normals: array [0..2] of sPoint;          // Normálové vektory každého vertexu
    neigh: array [0..2] of GLuint;            // Indexy sousedních facù
    PlaneEq: sPlaneEq;                        // Rovnice roviny facu
    visible: boolean;                         // Je face viditelný (pøivrácený ke svìtlu)?
    end;

  GLObject = record                           // Struktura objektu
    nPoints: GLuint;                          // Poèet vertexù
    points: array [0..99] of sPoint;          // Pole vertexù
    nPlanes: GLuint;                          // Poèet facù
    planes: array [0..199] of sPlane;         // Pole facù
    end;

  GLvector4f = array [0..3] of GLfloat;       // Nový datový typ
  GLmatrix16f = array [0..15] of GLfloat;     // Nový datový typ

var
  h_Rc: HGLRC;		                                          // Trvalý Rendering Context
  h_Dc: HDC;                                                // Privátní GDI Device Context
  h_Wnd: HWND;                                              // Obsahuje Handle našeho okna
  keys: array [0..255] of BOOL;	                            // Pole pro ukládání vstupu z klávesnice
  Active: bool = true;                                      // Ponese informaci o tom, zda je okno aktivní
  FullScreen:bool = true;                                   // Ponese informaci o tom, zda je program ve fullscreenu
  obj: GLObject;                                            // Objekt, který vrhá stín
  ObjPos: array [0..2] of GLfloat = (-2.0,-2.0,-5.0);       // Pozice objektu
  xrot: GLfloat = 0;                                        // X rotace
  xspeed: GLfloat = 0;                                      // X rychlost rotace objektu
  yrot: GLfloat = 0;                                        // Y rotace
  yspeed: GLfloat = 0;                                      // Y rychlost rotace objektu
  LightPos: array [0..3] of GLfloat = (0.0,5.0,-4.0,1.0);   // Pozice svìtla
  LightAmb: array [0..3] of GLfloat = (0.2,0.2,0.2,1.0);    // Ambient svìtlo
  LightDif: array [0..3] of GLfloat = (0.6,0.6,0.6,1.0);    // Diffuse svìtlo
  LightSpc: array [0..3] of GLfloat = (-0.2,-0.2,-0.2,1.0); // Specular svìtlo
  MatAmb: array [0..3] of GLfloat = (0.4,0.4,0.4,1.0);      // Materiál - Ambient hodnoty (prostøedí, atmosféra)
  MatDif: array [0..3] of GLfloat = (0.2,0.6,0.9,1.0);      // Materiál - Diffuse hodnoty (rozptylování svìtla)
  MatSpc: array [0..3] of GLfloat = (0.0,0.0,0.0,1.0);      // Materiál - Specular hodnoty (zrcadlivost)
  MatShn: array [0..0] of GLfloat = (0.0);                  // Materiál - Shininess hodnoty (lesk)
  q: GLUquadricObj;                                         // Quadratic pro kreslení koule
  SpherePos: array [0..2] of GLfloat = (-4.0,-5.0,-6.0);    // Pozice koule

function FindNumber(var retezec: string):string;            // Náhrada funkce fscanf z C++ - vrací øetìzec obsahující extrahované èíslo
var i: integer;                                             // Index v øetìzci
begin
  for i := 1 to Length(retezec) do
    if retezec[i] <> ' ' then break;                        // Najde první "ne-mezeru" - èíslici nebo zneménko "-"
  Delete(retezec,1,i-1);                                    // Smaže nepotøebnou èást øetìzce
  i := Pos(' ',retezec)-1;                                  // Index konce èíslice pøed další mezerou
  if i = -1 then i := Length(retezec);                      // Pokud další mezera neexistuje, vrátíme konec øetìzce
  Result := Copy(retezec,1,i);                              // Vrátí èást øetìzce do další mezery nebo konce øetìzce
  Delete(retezec,1,i);                                      // Smaže pøeètenou èást øetìzce
end;

procedure ReadStr(var f: textfile; var s: string);          // Naète jeden použitelný øádek ze souboru
begin
  readln(f,s);                                              // Naèti øádek
  while ((copy(s, 1, 1) = '/') or (length(s) = 0)) do       // Pokud není použitelný naèti další
    readln(f,s);
end;

function ReadObject(st: string; var o: GLObject): boolean;  // Nahraje objekt
var
  f: TextFile;                                              // Handle souboru
  i: integer;                                               // Øídící promìnná cyklù
  temp: string;                                             // Pomocná promìnná pro naèítání hodnot ze souboru
begin
  AssignFile(f,st);
  {$I-}
  Reset(f);                                                 // Otevøe soubor pro ètení
  {$I+}
  if IOResult <> 0 then                                     // Podaøilo se ho otevøít?
    begin
    Result := false;                                        // Pokud ne - konec funkce
    exit;
    end;
  ReadStr(f,temp);                                          // Naètení poètu vertexù
  o.nPoints := StrToInt(FindNumber(temp));
  for i := 1 to o.nPoints do                                // Naèítá vertexy
    begin
    ReadStr(f,temp);
    o.points[i].x := StrToFloat(FindNumber(temp));          // Jednotlivé x, y, z složky
    o.points[i].y := StrToFloat(FindNumber(temp));
    o.points[i].z := StrToFloat(FindNumber(temp));
    end;
  ReadStr(f,temp);
  o.nPlanes := StrToInt(FindNumber(temp));                  // Naètení poètu facù
  for i := 0 to o.nPlanes - 1 do                            // Naèítá facy
    begin
    ReadStr(f,temp);
    o.planes[i].p[0] := StrToInt(FindNumber(temp));             // Naètení indexù vertexù
    o.planes[i].p[1] := StrToInt(FindNumber(temp));
    o.planes[i].p[2] := StrToInt(FindNumber(temp));
    o.planes[i].normals[0].x := StrToFloat(FindNumber(temp));   // Normálové vektory prvního vertexu
    o.planes[i].normals[0].y := StrToFloat(FindNumber(temp));
    o.planes[i].normals[0].z := StrToFloat(FindNumber(temp));
    o.planes[i].normals[1].x := StrToFloat(FindNumber(temp));   // Normálové vektory druhého vertexu
    o.planes[i].normals[1].y := StrToFloat(FindNumber(temp));
    o.planes[i].normals[1].z := StrToFloat(FindNumber(temp));
    o.planes[i].normals[2].x := StrToFloat(FindNumber(temp));   // Normálové vektory tøetího vertexu
    o.planes[i].normals[2].y := StrToFloat(FindNumber(temp));
    o.planes[i].normals[2].z := StrToFloat(FindNumber(temp));
    end;
  CloseFile(f);                                                 // Zavøe soubor
  Result := true;                                               // Vše v poøádku
end;

procedure SetConnectivity(var o :GLObject);                     // Nastavení sousedù jednotlivých facù
var
  p1i, p2i, p1j, p2j: GLuint;                                   // Pomocné promìnné
  q1i, q2i, q1j, q2j: GLuint;                                   // Pomocné promìnné
  i, j, ki, kj: GLuint;                                         // Øídící promìnné cyklù
begin
  for i := 0 to o.nPlanes - 2 do                                // Každý face objektu (A)
    for j := i + 1 to o.nPlanes - 1 do                          // Každý face objektu (B)
      for ki := 0 to 2 do                                       // Každý okraj facu (A)
        if o.planes[i].neigh[ki] <> 0 then                      // Okraj ještì nemá souseda?
          for kj := 0 to 2 do                                   // Každý okraj facu (B)
            begin
            p1i := ki;                                          // Výpoèty pro zjištìní sousedství
            p1j := kj;
            p2i := (ki+1) mod 3;
            p2j := (kj+1) mod 3;
            p1i := o.planes[i].p[p1i];
            p2i := o.planes[i].p[p2i];
            p1j := o.planes[j].p[p1j];
            p2j := o.planes[j].p[p2j];
            q1i := ((p1i+p2i) - abs(p1i-p2i)) div 2;
            q2i := ((p1i+p2i) + abs(p1i-p2i)) div 2;
            q1j := ((p1j+p2j) - abs(p1j-p2j)) div 2;
            q2j := ((p1j+p2j) + abs(p1j-p2j)) div 2;
            if (q1i = q2i) and (q1j = q2j) then                 // Jsou sousedé?
              begin
              o.planes[i].neigh[ki] := j+1;
              o.planes[j].neigh[kj] := i+1;
              end;
            end;
end;

procedure DrawGLObject(o: GLObject);                            // Vykreslení objektu
var
  i, j: GLuint;                                                 // Øídící promìnné cyklù
begin
  glBegin(GL_TRIANGLES);                                        // Kreslení trojúhelníkù
    for i := 0 to o.nPlanes-1 do                                // Projde všechny facy
      for j := 0 to 2 do                                        // Trojúhelník má tøi rohy
        begin                                                   // Normálový vektor a umístìní bodu
        glNormal3f(o.planes[i].normals[j].x,o.planes[i].normals[j].y,o.planes[i].normals[j].z);
        glVertex3f(o.points[o.planes[i].p[j]].x,o.points[o.planes[i].p[j]].y,o.points[o.planes[i].p[j]].z);
        end;
  glEnd;
end;

procedure CalcPlane(o: GLObject; var plane: sPlane);      // Rovnice roviny ze tøí bodù
var
  v: array [0..3] of sPoint;                              // Pomocné hodnoty
  i: integer;                                             // Øídící promìnná cyklù
begin
  for i := 0 to 2 do                                      // Pro zkrácení zápisu
    begin
    v[i+1].x := o.points[plane.p[i]].x;                   // Uloží hodnoty do pomocných promìnných
    v[i+1].y := o.points[plane.p[i]].y;
    v[i+1].z := o.points[plane.p[i]].z;
    end;
  plane.PlaneEq.a := v[1].y*(v[2].z-v[3].z) + v[2].y*(v[3].z-v[1].z) + v[3].y*(v[1].z-v[2].z);
  plane.PlaneEq.b := v[1].z*(v[2].x-v[3].x) + v[2].z*(v[3].x-v[1].x) + v[3].z*(v[1].x-v[2].x);
  plane.PlaneEq.c := v[1].x*(v[2].y-v[3].y) + v[2].x*(v[3].y-v[1].y) + v[3].x*(v[1].y-v[2].y);
  plane.PlaneEq.d := -( v[1].x*(v[2].y*v[3].z - v[3].y*v[2].z) + v[2].x*(v[3].y*v[1].z - v[1].y*v[3].z) + v[3].x*(v[1].y*v[2].z - v[2].y*v[1].z) );
end;

function InitGLObject: boolean;                           // Inicializuje objekty
var i: GLuint;                                            // Cyklus
begin
  if not ReadObject('Data/Object2.txt',obj) then          // Nahraje objekt
    begin
    Result := false;                                      // Pøi chybì konec
    exit;
    end;
  SetConnectivity(obj);                                   // Pospojuje facy (najde sousedy)
  for i := 0 to obj.nPlanes - 1 do                        // Prochází facy
    CalcPlane(obj,obj.planes[i]);                         // Spoèítá rovnici roviny facu
  Result := true;                                         // Vše v poøádku
end;

procedure CastShadow(var o: GLObject; lp: GLvector4f);                          // Vržení stínu
var
  i, j, k, jj: GLuint;                                                          // Pomocné
  p1, p2: GLuint;                                                               // Dva body okraje vertexu, které vrhají stín
  v1, v2: sPoint;                                                               // Vektor mezi svìtlem a pøedchozími body
  side: GLfloat;                                                                // Pomocná promìnná
begin
  for i := 0 to o.nPlanes - 1 do                                                // Projde všechny facy objektu
    begin                                                                 
    side := o.planes[i].PlaneEq.a*lp[0] + o.planes[i].PlaneEq.b*lp[1]           // Rozhodne jestli je face pøivrácený nebo odvrácený od svìtla
      + o.planes[i].PlaneEq.c*lp[2] + o.planes[i].PlaneEq.d*lp[3];
    if side > 0 then                                                            // Je pøivrácený?
      o.planes[i].visible := true
      else                                                                      // Není
      o.planes[i].visible := false;
    end;
  glDisable(GL_LIGHTING);                                                       // Vypne svìtla
  glDepthMask(GL_FALSE);                                                        // Vypne zápis do depth bufferu
  glDepthFunc(GL_LEQUAL);                                                       // Funkce depth bufferu
  glEnable(GL_STENCIL_TEST);                                                    // Zapne stencilové testy
  glColorMask(GL_FALSE,GL_FALSE,GL_FALSE,GL_FALSE);                             // Nekreslit na obrazovky
  glStencilFunc(GL_ALWAYS,1,$FFFFFFFF);                                         // Funkce stencilu
  glFrontFace(GL_CCW);                                                          // Èelní stìna proti smìru hodinových ruèièek
  glStencilOp(GL_KEEP,GL_KEEP,GL_INCR);                                         // Zvyšování hodnoty stencilu
  for i := 0 to o.nPlanes - 1 do                                                // Každý face objektu
    if o.planes[i].visible then                                                 // Je pøivrácený ke svìtlu
      for j := 0 to 2 do                                                        // Každý okraj facu
        begin
        k := o.planes[i].neigh[j];                                              // Index souseda (pomocný)
        if (k = 0) or (not o.planes[k-1].visible) then                          // Pokud nemá souseda, který je pøivrácený ke svìtlu
          begin
          p1 := o.planes[i].p[j];                                               // První bod okraje
          jj := (j+1) mod 3;                                                    // Pro získání druhého okraje
          p2 := o.planes[i].p[jj];                                              // Druhý bod okraje
          v1.x := (o.points[p1].x - lp[0]) * 100;                               // Délka vektoru
          v1.y := (o.points[p1].y - lp[1]) * 100;
          v1.z := (o.points[p1].z - lp[2]) * 100;
          v2.x := (o.points[p2].x - lp[0]) * 100;
          v2.y := (o.points[p2].y - lp[1]) * 100;
          v2.z := (o.points[p2].z - lp[2]) * 100;
          glBegin(GL_TRIANGLE_STRIP);                                           // Nakreslí okrajový polygon stínu
            glVertex3f(o.points[p1].x, o.points[p1].y, o.points[p1].z);
            glVertex3f(o.points[p1].x + v1.x, o.points[p1].y + v1.y, o.points[p1].z + v1.z);
            glVertex3f(o.points[p2].x, o.points[p2].y, o.points[p2].z);
            glVertex3f(o.points[p2].x + v2.x, o.points[p2].y + v2.y, o.points[p2].z + v2.z);
          glEnd();
          end;
        end;
  glFrontFace(GL_CW);                                                           // Èelní stìna po smìru hodinových ruèièek
  glStencilOp(GL_KEEP,GL_KEEP,GL_DECR);                                         // Snižování hodnoty stencilu
  for i := 0 to o.nPlanes - 1 do                                                // Každý face objektu
    if o.planes[i].visible then                                                 // Je pøivrácený ke svìtlu
      for j := 0 to 2 do                                                        // Každý okraj facu
        begin
        k := o.planes[i].neigh[j];                                              // Index souseda (pomocný)
        if (k = 0) or (not o.planes[k-1].visible) then                          // Pokud nemá souseda, který je pøivrácený ke svìtlu
          begin
          p1 := o.planes[i].p[j];                                               // První bod okraje
          jj := (j+1) mod 3;                                                    // Pro získání druhého okraje
          p2 := o.planes[i].p[jj];                                              // Druhý bod okraje
          v1.x := (o.points[p1].x - lp[0]) * 100;                               // Délka vektoru
          v1.y := (o.points[p1].y - lp[1]) * 100;
          v1.z := (o.points[p1].z - lp[2]) * 100;
          v2.x := (o.points[p2].x - lp[0]) * 100;
          v2.y := (o.points[p2].y - lp[1]) * 100;
          v2.z := (o.points[p2].z - lp[2]) * 100;
          glBegin(GL_TRIANGLE_STRIP);                                           // Nakreslí okrajový polygon stínu
            glVertex3f(o.points[p1].x, o.points[p1].y, o.points[p1].z);
            glVertex3f(o.points[p1].x + v1.x, o.points[p1].y + v1.y, o.points[p1].z + v1.z);
            glVertex3f(o.points[p2].x, o.points[p2].y, o.points[p2].z);
            glVertex3f(o.points[p2].x + v2.x, o.points[p2].y + v2.y, o.points[p2].z + v2.z);
          glEnd();
          end;
        end;
  glFrontFace(GL_CCW);                                                          // Èelní stìna proti smìru hodinových ruèièek
  glColorMask(GL_TRUE,GL_TRUE,GL_TRUE,GL_TRUE);                                 // Vykreslovat na obrazovku
  glColor4f(0.0,0.0,0.0,0.4);                                                   // Èerná, 40% prùhledná
  glEnable(GL_BLEND);                                                           // Zapne blending
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);                             // Typ blendingu
  glStencilFunc(GL_NOTEQUAL,0,$FFFFFFFF);                                       // Nastavení stencilu
  glStencilOp(GL_KEEP,GL_KEEP,GL_KEEP);                                         // Nemìnit hodnotu stencilu
  glPushMatrix();                                                               // Uloží matici
  glLoadIdentity();                                                             // Reset matice
  glBegin(GL_TRIANGLE_STRIP);                                                   // Èerný obdélník
    glVertex3f(-0.1, 0.1,-0.10);
    glVertex3f(-0.1,-0.1,-0.10);
    glVertex3f( 0.1, 0.1,-0.10);
    glVertex3f( 0.1,-0.1,-0.10);
  glEnd();
  glPopMatrix();                                                                // Obnoví matici
  glDisable(GL_BLEND);                                                          // Obnoví zmìnìné parametry OpenGL
  glDepthFunc(GL_LEQUAL);
  glDepthMask(GL_TRUE);
  glEnable(GL_LIGHTING);
  glDisable(GL_STENCIL_TEST);
  glShadeModel(GL_SMOOTH);
end;

procedure ReSizeGLScene(Width: GLsizei; Height: GLsizei); // Zmìna velikosti a inicializace OpenGL okna
begin
  if (Height=0) then		                                  // Zabezpeèení proti dìlení nulou
     Height:=1;                                           // Nastaví výšku na jedna
  glViewport(0, 0, Width, Height);                        // Resetuje aktuální nastavení
  glMatrixMode(GL_PROJECTION);                            // Zvolí projekèní matici
  glLoadIdentity();                                       // Reset matice
  gluPerspective(45.0,Width/Height,0.1,100.0);            // Výpoèet perspektivy
  glMatrixMode(GL_MODELVIEW);                             // Zvolí matici Modelview
  glLoadIdentity;                                         // Reset matice
end;


function InitGL:bool;	                              // Všechno nastavení OpenGL
begin
  if not InitGLObject then                          // Nahraje objekt
    begin
    Result := false;
    exit;
    end;
  glShadeModel(GL_SMOOTH);			                    // Povolí jemné stínování
  glClearColor(0.0, 0.0, 0.0, 0.5);	  	            // Èerné pozadí
  glClearDepth(1.0);				                        // Nastavení hloubkového bufferu
  glClearStencil(0);                                // Nastavení stencil bufferu
  glEnable(GL_DEPTH_TEST);			                    // Povolí hloubkové testování
  glDepthFunc(GL_LEQUAL);				                    // Typ hloubkového testování
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST); // Nejlepší perspektivní korekce
  glLightfv(GL_LIGHT1,GL_POSITION,@LightPos);       // Pozice svìtla
  glLightfv(GL_LIGHT1,GL_AMBIENT,@LightAmb);        // Ambient svìtlo
  glLightfv(GL_LIGHT1,GL_DIFFUSE,@LightDif);        // Diffuse svìtlo
  glLightfv(GL_LIGHT1,GL_SPECULAR,@LightSpc);       // Specular svìtlo
  glEnable(GL_LIGHT1);                              // Zapne svìtlo 1
  glEnable(GL_LIGHTING);                            // Zapne svìtla
  glMaterialfv(GL_FRONT,GL_AMBIENT,@MatAmb);        // Prostøedí, atmosféra
  glMaterialfv(GL_FRONT,GL_DIFFUSE,@MatDif);        // Rozptylování svìtla
  glMaterialfv(GL_FRONT,GL_SPECULAR,@MatSpc);       // Zrcadlivost
  glMaterialfv(GL_FRONT,GL_SHININESS,@MatShn);      // Lesk
  glCullFace(GL_BACK);                              // Oøezávání zadních stran
  glEnable(GL_CULL_FACE);                           // Zapne oøezávání
  q := gluNewQuadric;                               // Nový quadratic
  gluQuadricNormals(q,GL_SMOOTH);                   // Generování normálových vektorù pro svìtlo
  gluQuadricTexture(q,GL_FALSE);                    // Nepotøebujeme texturovací koordináty
  Result:=true;                                     // Inicializace probìhla v poøádku
end;

procedure DrawGLRoom;                               // Vykreslí místnost (krychli)
begin
  glBegin(GL_QUADS);                                // Zaèátek kreslení obdélníkù
    // Podlaha
    glNormal3f(0.0, 1.0, 0.0);                      // Normála smìøuje nahoru
    glVertex3f(-10.0,-10.0,-20.0);                  // Levý zadní
    glVertex3f(-10.0,-10.0, 20.0);                  // Levý pøední
    glVertex3f( 10.0,-10.0, 20.0);                  // Pravý pøední
    glVertex3f( 10.0,-10.0,-20.0);                  // Pravý zadní
    // Strop
    glNormal3f(0.0,-1.0, 0.0);                      // Normála smìøuje dolù
    glVertex3f(-10.0, 10.0, 20.0);                  // Levý pøední
    glVertex3f(-10.0, 10.0,-20.0);                  // Levý zadní
    glVertex3f( 10.0, 10.0,-20.0);                  // Pravý zadní
    glVertex3f( 10.0, 10.0, 20.0);                  // Pravý pøední
    // Èelní stìna
    glNormal3f(0.0, 0.0, 1.0);                      // Normála smìøuje do hloubky
    glVertex3f(-10.0, 10.0,-20.0);                  // Levý horní
    glVertex3f(-10.0,-10.0,-20.0);                  // Levý dolní
    glVertex3f( 10.0,-10.0,-20.0);                  // Pravý dolní
    glVertex3f( 10.0, 10.0,-20.0);                  // Pravý horní
    // Zadní stìna
    glNormal3f(0.0, 0.0,-1.0);                      // Normála smìøuje k obrazovce
    glVertex3f( 10.0, 10.0, 20.0);                  // Pravý horní
    glVertex3f( 10.0,-10.0, 20.0);                  // Pravý spodní
    glVertex3f(-10.0,-10.0, 20.0);                  // Levý spodní
    glVertex3f(-10.0, 10.0, 20.0);                  // Levý zadní
    // Levá stìna
    glNormal3f(1.0, 0.0, 0.0);                      // Normála smìøuje doprava
    glVertex3f(-10.0, 10.0, 20.0);                  // Pøední horní
    glVertex3f(-10.0,-10.0, 20.0);                  // Pøední dolní
    glVertex3f(-10.0,-10.0,-20.0);                  // Zadní dolní
    glVertex3f(-10.0, 10.0,-20.0);                  // Zadní horní
    // Pravá stìna
    glNormal3f(-1.0, 0.0, 0.0);                     // Normála smìøuje doleva
    glVertex3f( 10.0, 10.0,-20.0);                  // Zadní horní
    glVertex3f( 10.0,-10.0,-20.0);                  // Zadní dolní
    glVertex3f( 10.0,-10.0, 20.0);                  // Pøední dolní
    glVertex3f( 10.0, 10.0, 20.0);                  // Pøední horní
  glEnd();                                          // Konec kreslení
end;

procedure VMatMult(M: GLmatrix16f; var v: GLvector4f);
var res: GLvector4f;                                            // Ukládá výsledky
begin
  res[0] := M[ 0]*v[0] + M[ 4]*v[1] + M[ 8]*v[2] + M[12]*v[3];
  res[1] := M[ 1]*v[0] + M[ 5]*v[1] + M[ 9]*v[2] + M[13]*v[3];
  res[2] := M[ 2]*v[0] + M[ 6]*v[1] + M[10]*v[2] + M[14]*v[3];
  res[3] := M[ 3]*v[0] + M[ 7]*v[1] + M[11]*v[2] + M[15]*v[3];
  v[0] := res[0];                                               // Výsledek uloží zpìt do v
  v[1] := res[1];
  v[2] := res[2];
  v[3] := res[3];                                               // Homogenní souøadnice
end;

function DrawGLScene():bool;                            // Vykreslování
var
  Minv: GLmatrix16f;                                    // OpenGL matice
  wlp, lp: GLvector4f;                                  // Relativní pozice svìtla
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
          or GL_STENCIL_BUFFER_BIT);                    // Smaže buffery
  glLoadIdentity();	                                    // Reset matice
  glTranslatef(0.0,0.0,-20.0);                          // Pøesun 20 jednotek do hloubky
  glLightfv(GL_LIGHT1,GL_POSITION,@LightPos);           // Umístìní svìtla
  glTranslatef(SpherePos[0],SpherePos[1],SpherePos[2]); // Umístìní koule
  gluSphere(q,1.5,32,16);                               // Vykreslení koule
  glLoadIdentity;                                       // Reset matice
  glRotatef(-yrot,0.0,1.0,0.0);                         // Rotace na ose y
  glRotatef(-xrot,1.0,0.0,0.0);                         // Rotace na ose x
  glGetFloatv(GL_MODELVIEW_MATRIX,@Minv);               // Uložení ModelView matice do Minv
  lp[0] := LightPos[0];                                 // Uložení pozice svìtla
  lp[1] := LightPos[1];
  lp[2] := LightPos[2];
  lp[3] := LightPos[3];
  VMatMult(Minv, lp);                                   // Vynásobení pozice svìtla OpenGL maticí
  glTranslatef(-ObjPos[0],-ObjPos[1],-ObjPos[2]);       // Posun zápornì o pozici objektu
  glGetFloatv(GL_MODELVIEW_MATRIX, @Minv);              // Uložení ModelView matice do Minv
  wlp[0] := 0.0;                                        // Globální koordináty na nulu
  wlp[1] := 0.0;
  wlp[2] := 0.0;
  wlp[3] := 1.0;
  VMatMult(Minv, wlp);                                  // Originální globální souøadnicový systém relativnì k lokálnímu
  lp[0] := lp[0] + wlp[0];                              // Pozice svìtla je relativní k lokálnímu souøadnicovému systému objektu
  lp[1] := lp[1] + wlp[1];
  lp[2] := lp[2] + wlp[2];
  glLoadIdentity;                                       // Reset matice
  glTranslatef(0.0,0.0,-20.0);                          // Pøesun 20 jednotek do hloubky
  DrawGLRoom;                                           // Vykreslení místnosti
  glTranslatef(ObjPos[0],ObjPos[1],ObjPos[2]);          // Umístìní objektu
  glRotatef(xrot,1.0,0.0,0.0);                          // Rotace na ose x
  glRotatef(yrot,0.0,1.0,0.0);                          // Rotace na ose y
  DrawGLObject(obj);                                    // Vykreslení objektu
  CastShadow(obj,lp);                                   // Vržení stínu založené na siluetì
  glColor4f(0.7,0.4,0.0,1.0);                           // Oranžová barva
  glDisable(GL_LIGHTING);                               // Vypne svìtlo
  glDepthMask(GL_FALSE);                                // Vypne masku hloubky
  glTranslatef(lp[0],lp[1],lp[2]);                      // Translace na pozici svìtla
  gluSphere(q,0.2,16,8);                                // Vykreslení malé koule (reprezentuje svìtlo)
  glEnable(GL_LIGHTING);                                // Zapne svìtlo
  glDepthMask(GL_TRUE);                                 // Zapne masku hloubky
  xrot := xrot + xspeed;                                // Zvìtšení úhlu rotace objektu
  yrot := yrot + yspeed;
  glFlush;
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
      cStencilBits:= 1;                               // Stencil Buffer
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

procedure ProcessKeyboard;                                      // Ošetøení klávesnice
begin
  // Rotace objektu
  if keys[VK_LEFT] then yspeed := yspeed - 0.1;                 // Šipka vlevo - snižuje y rychlost
  if keys[VK_RIGHT] then yspeed := yspeed + 0.1;                // Šipka vpravo - zvyšuje y rychlost
  if keys[VK_UP] then xspeed := xspeed - 0.1;                   // Šipka nahoru - snižuje x rychlost
  if keys[VK_DOWN] then xspeed := xspeed + 0.1;                 // Šipka dolù - zvyšuje x rychlost
  // Pozice objektu
  if keys[VK_NUMPAD6] then ObjPos[0] := ObjPos[0] + 0.05;       // '6' - pohybuje objektem doprava
  if keys[VK_NUMPAD4] then ObjPos[0] := ObjPos[0] - 0.05;       // '4' - pohybuje objektem doleva
  if keys[VK_NUMPAD8] then ObjPos[1] := ObjPos[1] + 0.05;       // '8' - pohybuje objektem nahoru
  if keys[VK_NUMPAD5] then ObjPos[1] := ObjPos[1] - 0.05;       // '5' - pohybuje objektem dolù
  if keys[VK_NUMPAD9] then ObjPos[2] := ObjPos[2] + 0.05;       // '9' - pøibližuje objekt
  if keys[VK_NUMPAD7] then ObjPos[2] := ObjPos[2] - 0.05;       // '7' oddaluje objekt
  // Pozice svìtla
  if keys[Ord('L')] then LightPos[0] := LightPos[0] + 0.05;     // 'L' - pohybuje svìtlem doprava
  if keys[Ord('J')] then LightPos[0] := LightPos[0] - 0.05;     // 'J' - pohybuje svìtlem doleva
  if keys[Ord('I')] then LightPos[1] := LightPos[1] + 0.05;     // 'I' - pohybuje svìtlem nahoru
  if keys[Ord('K')] then LightPos[1] := LightPos[1] - 0.05;     // 'K' - pohybuje svìtlem dolù
  if keys[Ord('O')] then LightPos[2] := LightPos[2] + 0.05;     // 'O' - pøibližuje svìtlo
  if keys[Ord('U')] then LightPos[2] := LightPos[2] - 0.05;     // 'U' - oddaluje svìtlo
  // Pozice koule
  if keys[Ord('D')] then SpherePos[0] := SpherePos[0] + 0.05;   // 'D' - pohybuje koulí doprava
  if keys[Ord('A')] then SpherePos[0] := SpherePos[0] - 0.05;   // 'A' - pohybuje koulí doleva
  if keys[Ord('W')] then SpherePos[1] := SpherePos[1] + 0.05;   // 'W' - pohybuje koulí nahoru
  if keys[Ord('S')] then SpherePos[1] := SpherePos[1] - 0.05;   // 'S'- pohybuje koulí dolù
  if keys[Ord('E')] then SpherePos[2] := SpherePos[2] + 0.05;   // 'E' - pøibližuje kouli
  if keys[Ord('Q')] then SpherePos[2] := SpherePos[2] - 0.05;   // 'Q' - oddaluje kouli
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
  // Dotaz na uživatele pro fullscreen/okno
  if MessageBox(0,'Would You Like To Run In FullScreen Mode?','Start FullScreen',
                             MB_YESNO or MB_ICONQUESTION)=IDNO then
    FullScreen:=false                                 // Bìh v oknì
  else
    FullScreen:=true;                                 // Fullscreen
  if not CreateGLWindow('NeHe''s OpenGL Framework',800,600,32,FullScreen) then // Vytvoøení OpenGL okna
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
            if not CreateGLWindow('NeHe''s OpenGL Framework',800,600,32,fullscreen) then
              Result := 0;                            // Konec programu pokud nebylo vytvoøeno
            end;
          ProcessKeyboard;
        end;
    end;                                              // Konec smyèky while
  killGLwindow();                                     // Zavøe okno
  result:=msg.wParam;                                 // Ukonèení programu
end;

begin
  DecimalSeparator := '.';                            // Desetinná teèka
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );  // Start programu
  DecimalSeparator := ',';                            // Zpìt desetinná èárka
end.

