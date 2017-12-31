program lesson30a;

{   kÛd pro Delphi 7}

uses
  Windows, 
  Messages,
  OpenGL,
  sysutils,
  GLaux,
  Vector in 'Vector.pas',
  mmsystem,
  Ray in 'Ray.pas';

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glDeleteTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

type
  Plane = record                                            // Struktura roviny
    _Position: TVector;
    _Normal: TVector;
    end;

  Cylinder = record                                         // Struktura v·lce
    _Position: TVector;
    _Axis: TVector;
    _Radius: Double;
    end;

  Explosion = record                                        // Struktura exploze
    _Position: TVector;
    _Alpha: GLfloat;
    _Scale: GLfloat;
    end;

const
  spec: array [0..3] of GLfloat = (1.0, 1.0, 1.0, 1.0);     // BodovÈ svÏtlo
  posl: array [0..3] of GLfloat = (0, 400, 0, 1);           // Pozice svÏtla
  amb: array [0..3] of GLfloat = (0.2, 0.2, 0.2, 1.0);      // OkolnÌ svÏtlo glob·lnÌ
  amb2: array [0..3] of GLfloat = (0.3, 0.3, 0.3, 1.0);     // OkolnÌ svÏtlo bodovÈho svÏtla
  ZERO = EPSILON;

var
  h_Rc: HGLRC;		                                          // Trval˝ Rendering Context
  h_Dc: HDC;                                                // Priv·tnÌ GDI Device Context
  h_Wnd: HWND;                                              // Obsahuje Handle naöeho okna
  keys: array [0..255] of BOOL;	                            // Pole pro ukl·d·nÌ vstupu z kl·vesnice
  Active: bool = true;                                      // Ponese informaci o tom, zda je okno aktivnÌ
  FullScreen:bool = true;                                   // Ponese informaci o tom, zda je program ve fullscreenu
  dir: TVector = (x:0; y:0; z:-10);                         // SmÏr kamery
  pos: TVector = (x:0; y:-50; z:1000);                      // Pozice kamery
  camera_rotation: GLfloat = 0;                             // Rotace scÈny na ose y
  veloc: TVector = (x:0.5; y:-0.1; z:0.5);                  // PoË·teËnÌ rychlost koulÌ
  accel: TVector = (x:0; y:-0.05; z:0);                     // GravitaËnÌ zrychlenÌ aplikovanÈ na koule
  ArrayVel: array [0..9] of TVector;                        // Rychlost koulÌ
  ArrayPos: array [0..9] of TVector;                        // Pozice koulÌ
  OldPos: array [0..9] of TVector;                          // StarÈ pozice koulÌ
  NrOfBalls: integer;                                       // PoËet koulÌ
  Time: Double = 0.6;                                       // »asov˝ krok simulace
  hook_toball1: boolean = false;                            // Sledovat kamerou kouli?
  sounds: boolean = true;                                   // ZvukovÈ efekty on/off
  pl1, pl2, pl3, pl4, pl5: Plane;                           // PÏt rovin mÌstnosti (bez stropu)
  cyl1, cyl2, cyl3: Cylinder;                               // T¯i v·lce
  ExplosionArray: array [0..19] of Explosion;               // Dvacet explozÌ
  texture: array [0..3] of GLuint;                          // »ty¯i textury
  dlist: GLuint;                                            // Display list v˝buchu
  cylinder_obj: GLUquadricObj;                              // Quadratic pro kreslenÌ koulÌ a v·lc˘

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

function LoadGLTextures: Bool;                                                  // Loading bitmapy a konverze na texturu
var TextureImage: array [0..3] of PTAUX_RGBImageRec;                            // Ukl·d· bitmapy
    Status: Bool;                                                               // Indikuje chyby
    i: integer;                                                                 // Cyklus
begin
  Status := false;
  ZeroMemory(@TextureImage,sizeof(TextureImage));                               // Vynuluje pamÏù
  TextureImage[0] := LoadBMP('Data/Marble.bmp');                                // Nahraje bitmapy
  TextureImage[1] := LoadBMP('Data/Spark.bmp');
  TextureImage[2] := LoadBMP('Data/Boden.bmp');
  TextureImage[3] := LoadBMP('Data/Wand.bmp');
  if Assigned(TextureImage[0]) and Assigned(TextureImage[1])
    and Assigned(TextureImage[2]) and Assigned(TextureImage[3]) then            // Vöe je bez problÈm˘?
    begin
    Status := true;                                                             // Vöe je bez problÈm˘
    glGenTextures(4,Texture[0]);                                                // Generuje textury
    for i := 0 to 3 do
      begin
      glBindTexture(GL_TEXTURE_2D,texture[i]);                                  // TypickÈ vytv·¯enÌ textury z bitmapy
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);           // Filtrov·nÌ p¯i zvÏtöenÌ
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);           // Filtrov·nÌ p¯i zmenöenÌ
      glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);               // Opakov·nÌ textury ve smÏru S
	    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);               // Opakov·nÌ textury ve smÏru T
      glTexImage2D(GL_TEXTURE_2D,0,3,TextureImage[i].sizeX,TextureImage[i].sizeY,0,GL_RGB,GL_UNSIGNED_BYTE,TextureImage[i].data);    // VlastnÌ vytv·¯enÌ textury
      end;
    end;
  Result := Status;                                                             // Ozn·mÌ p¯ÌpadnÈ chyby
end;

procedure InitVars;                                     // Inicializace promÏnn˝ch
var
  i: integer;                                           // Cyklus
begin
  pl1._Position := Vektor(0,-300,0);                    // 1. rovina
  pl1._Normal := Vektor(0,1,0);
  pl2._Position := Vektor(300,0,0);                     // 2. rovina
  pl2._Normal := Vektor(-1,0,0);
  pl3._Position := Vektor(-300,0,0);                    // 3. rovina
  pl3._Normal := Vektor(1,0,0);
  pl4._Position := Vektor(0,0,300);                     // 4. rovina
  pl4._Normal := Vektor(0,0,-1);
  pl5._Position := Vektor(0,0,-300);                    // 5. rovina
  pl5._Normal := Vektor(0,0,1);
  cyl1._Position := Vektor(0,0,0);                      // 1. v·lec
	cyl1._Axis := Vektor(0,1,0);
	cyl1._Radius := 60+20;
	cyl2._Position := Vektor(200,-300,0);                 // 2. v·lec
	cyl2._Axis := Vektor(0,0,1);
	cyl2._Radius := 60+20;
	cyl3._Position := Vektor(-200,0,0);                   // 3. v·lec
	cyl3._Axis := Vektor(0,1,1);
  cyl3._Axis := Uni(cyl3._Axis);
	cyl3._Radius := 30+20; 
  cylinder_obj := gluNewQuadric;                        // Nov˝ kvadratik objekt
  gluQuadricTexture(cylinder_obj,GL_TRUE);
	NrOfBalls := 10;                                      // PoËet mÌË˘
	ArrayVel[0] := veloc;                                 // 1. mÌË
	ArrayPos[0] := Vektor(199,180,10);
	ExplosionArray[0]._Alpha := 0;
	ExplosionArray[0]._Scale := 1;
	ArrayVel[1] := veloc;                                 // 2. mÌË
	ArrayPos[1] := Vektor(0,150,100);
	ExplosionArray[1]._Alpha := 0;
	ExplosionArray[1]._Scale := 1;
	ArrayVel[2] := veloc;                                 // 3. mÌË
	ArrayPos[2] := Vektor(-100,180,-100);
	ExplosionArray[2]._Alpha := 0;
	ExplosionArray[2]._Scale := 1;
  for i := 3 to 9 do                                    // 4. - 10. mÌË
    begin
    ArrayVel[i] := veloc;
	  ArrayPos[i] := Vektor(-500+i*75,300,-500+i*50);
		ExplosionArray[i]._Alpha := 0;
	  ExplosionArray[i]._Scale := 1;
    end;
	for i := 10 to 19 do
    begin
    ExplosionArray[i]._Alpha := 0;
	  ExplosionArray[i]._Scale := 1;
    end;
end;

function TestIntersionPlane(plane: Plane; position, direction: TVector; var lamda: Double; var pNormal: TVector): boolean;
var
  DotProduct, l2: double;                                                       // Skal·rnÌ souËin vektor˘, UrËuje koliznÌ bod
begin
  DotProduct := Dot(direction,plane._Normal);                                   // Skal·rnÌ souËin vektor˘
  if ((DotProduct < ZERO) and (DotProduct > -ZERO)) then                        // Je polop¯Ìmka rovnobÏûn· s rovinou?
    begin
		Result := false;                                                            // Bez pr˘seËÌku
    exit;
    end;
  l2 := Dot(plane._Normal,Subtract(plane._Position,position)) / DotProduct;     // DosazenÌ do vzorce
  if l2 < -ZERO then                                                            // SmÏ¯uje polop¯Ìmka od roviny?
    begin
		Result := false;                                                            // Bez pr˘seËÌku
    exit;
    end;
  pNormal := plane._Normal;                                                     // Norm·la roviny
	lamda := l2;                                                                  // KoliznÌ bod
  Result := true;                                                               // Pr˘seËÌk existuje
end;

function TestIntersionCylinder(cylinder: Cylinder; position, direction: TVector; var lamda: Double; var pNormal, newposition: TVector): boolean;
var
	RC: TVector;
	d,t,s: Double;
	n,O,HB: TVector;
	ln,vstup,vystup: Double;
begin
  RC := Subtract(position,cylinder._Position);
  n := Cross(direction,cylinder._Axis);
  ln := Mag(n.x,n.y,n.z);
	if (ln < ZERO) and (ln > -ZERO) then
    begin
    Result := false;
    exit;
    end;
	n := Uni(n);
	d := Abs(Dot(RC,n));
  if d <= cylinder._Radius then
    begin
    O := Cross(RC,cylinder._Axis);
		t := - (Dot(O,n) / ln);
		O := Cross(n,cylinder._Axis);
		O := Uni(O);
		s := Abs(sqrt(cylinder._Radius*cylinder._Radius - d*d) / Dot(direction,O));
		vstup := t - s;
		vystup := t + s;
		if vstup < -ZERO then
			if vystup < -ZERO then
        begin
        Result := false;
        exit;
        end
			  else lamda := vystup
		  else
      if vystup < -ZERO then
        lamda := vstup
		    else
		    if vstup < vystup then
          lamda := vstup
		      else lamda := vystup;
    newposition := Add(position,Multiply(direction,lamda));
		HB := Subtract(newposition,cylinder._Position);
		pNormal := Subtract(HB,Multiply(cylinder._Axis,Dot(HB,cylinder._Axis)));
		pNormal := Uni(pNormal);
		Result := true;
    exit;
	  end;
  Result := false;
end;

function FindBallCol(var point: TVector; var TimePoint: Double; Time2: Double; var BallNr1, BallNr2: Integer): boolean;
var
  RelativeV: TVector;                                                           // RelativnÌ rychlost mezi koulemi
  rays: TRay;                                                                   // Polop¯Ìmka
  MyTime, AddTime, Timedummy: double;                                           // Hled·nÌ p¯esnÈ pozice n·razu
  posi: TVector;                                                                // Pozice na polop¯Ìmce
  i, j: integer;                                                                // Cykly
begin
  AddTime := Time2 / 150.0;                                                     // Rozkouskuje Ëasov˝ ˙sek na 150 Ë·stÌ
  Timedummy := 10000;                                                           // »as n·razu
	// Test vöech koulÌ proti vöem ostatnÌm po 150 krocÌch
	for i := 0 to NrOfBalls - 2 do                                                // Vöechny koule
	  for j := i + 1 to NrOfBalls - 1 do                                          // Vöechny zb˝vajÌcÌ koule
      begin
		  RelativeV := Subtract(ArrayVel[i],ArrayVel[j]);                           // RelativnÌ rychlost mezi koulemi
			rays.P := OldPos[i];                                                      // Polop¯Ìmka
      rays.V := Uni(RelativeV);
			MyTime := 0.0;                                                            // Inicializace p¯ed vstupem do cyklu
			if DistR(rays.P,rays.V,OldPos[j]) > 40 then                               // Je vzd·lenost vÏtöÌ neû 2 polomÏry?
        begin
        continue;                                                               // DalöÌ
        end;
			while MyTime < Time2 do                                                   // P¯esn˝ bod n·razu
        begin
			  MyTime := MyTime + AddTime;                                             // ZvÏtöÌ Ëas
			  posi := Add(OldPos[i],Multiply(RelativeV,MyTime));                      //P¯esun na dalöÌ bod (pohyb na polop¯Ìmce)
			  if DistV(posi,OldPos[j]) <= 40 then                                     // N·raz
          begin
          point := posi;                                                        // Bod n·razu
          if Timedummy > (MyTime - AddTime) then Timedummy := MyTime - AddTime; // BliûöÌ n·raz, neû kter˝ jsme uû naöli (v Ëase)? P¯i¯adit Ëas n·razu
          BallNr1 := i;                                                         // OznaËenÌ koulÌ, kterÈ narazily
          BallNr2 := j;
          break;                                                                // UkonËÌ vnit¯nÌ cyklus
          end;
			  end;
      end;
	if Timedummy <> 10000 then                                                    // Naöli jsme kolizi?
    begin
    TimePoint := Timedummy;                                                     // »as n·razu
	  Result := true;                                                             // ⁄spÏch
    exit;
    end;
	Result := false;                                                              // Bez kolize
end;

procedure Idle;                                                                 // SimulaËnÌ logika - kolize
var
  rt, rt2, rt4, lamda: double;                                                  // Deklarace promÏnn˝ch
  norm, uveloc: TVector;
  normal, point, ltime: TVector;
  RestTime, BallTime: double;
  Pos2: TVector;
  BallNr, dummy, BallColNr1, BallColNr2: integer;
  Nc: TVector;
  i, j: integer;
  pb1,pb2,xaxis,U1x,U1y,U2x,U2y,V1x,V1y,V2x,V2y: TVector;
  a,b: double;
begin
  BallNr := 0;
  dummy := 0;
  if not hook_toball1 then                                                      // Pokud kamera nesleduje kouli
    begin
    camera_rotation := camera_rotation + 0.1;                                   // PootoËenÌ scÈny
    if camera_rotation > 360 then camera_rotation := 0;                         // Oöet¯enÌ p¯eteËenÌ
    end;
  RestTime := Time;
  lamda := 1000;
  // V˝poËet rychlostÌ vöech koulÌ pro n·sledujÌcÌ Ëasov˝ ˙sek (Eulerovy rovnice)
  for j := 0 to NrOfBalls - 1 do
    ArrayVel[j] := Add(ArrayVel[j],Multiply(accel,RestTime));
  while RestTime > ZERO do                                                      // Dokud neskonËil Ëasov˝ ˙sek
    begin
    lamda := 10000;                                                             // Inicializace na velmi vysokou hodnotu
    // Kolize vöech koulÌ s rovinami a v·lci
    for i := 0 to NrOfBalls - 1 do                                              // Vöechny koule
      begin
      OldPos[i] := ArrayPos[i];                                                 // V˝poËet novÈ pozice a vzd·lenosti
      uveloc := Uni(ArrayVel[i]);
      ArrayPos[i] := Add(ArrayPos[i],Multiply(ArrayVel[i],RestTime));
      rt2 := DistV(OldPos[i],ArrayPos[i]);
      // Kolize koule s rovinou
      if TestIntersionPlane(pl1,OldPos[i],uveloc,rt,norm) then
        begin
        rt4 := rt * RestTime / rt2;                                             // »as n·razu
        if rt4 <= lamda then                                                    // Pokud je menöÌ neû nÏkter˝ z d¯Ìve nalezen˝ch nahradit ho
          if rt4 <= (RestTime + ZERO) then
            if not ((rt <= ZERO) and (Dot(uveloc,norm) > ZERO)) then
              begin
              normal := norm;
              point := Add(OldPos[i],Multiply(uveloc,rt));
              lamda := rt4;
              BallNr := i;
              end;
        end;
      if TestIntersionPlane(pl2,OldPos[i],uveloc,rt,norm) then
        begin
        rt4 := rt * RestTime / rt2;                                             // »as n·razu
        if rt4 <= lamda then                                                    // Pokud je menöÌ neû nÏkter˝ z d¯Ìve nalezen˝ch nahradit ho
          if rt4 <= (RestTime + ZERO) then
            if not ((rt <= ZERO) and (Dot(uveloc,norm) > ZERO)) then
              begin
              normal := norm;
              point := Add(OldPos[i],Multiply(uveloc,rt));
              lamda := rt4;
              BallNr := i;
              dummy := 1;
              end;
        end;
      if TestIntersionPlane(pl3,OldPos[i],uveloc,rt,norm) then
        begin
        rt4 := rt * RestTime / rt2;                                             // »as n·razu
        if rt4 <= lamda then                                                    // Pokud je menöÌ neû nÏkter˝ z d¯Ìve nalezen˝ch nahradit ho
          if rt4 <= (RestTime + ZERO) then
            if not ((rt <= ZERO) and (Dot(uveloc,norm) > ZERO)) then
              begin
              normal := norm;
              point := Add(OldPos[i],Multiply(uveloc,rt));
              lamda := rt4;
              BallNr := i;
              end;
        end;
      if TestIntersionPlane(pl4,OldPos[i],uveloc,rt,norm) then
        begin
        rt4 := rt * RestTime / rt2;                                             // »as n·razu
        if rt4 <= lamda then                                                    // Pokud je menöÌ neû nÏkter˝ z d¯Ìve nalezen˝ch nahradit ho
          if rt4 <= (RestTime + ZERO) then
            if not ((rt <= ZERO) and (Dot(uveloc,norm) > ZERO)) then
              begin
              normal := norm;
              point := Add(OldPos[i],Multiply(uveloc,rt));
              lamda := rt4;
              BallNr := i;
              end;
        end;
      if TestIntersionPlane(pl5,OldPos[i],uveloc,rt,norm) then
        begin
        rt4 := rt * RestTime / rt2;                                             // »as n·razu
        if rt4 <= lamda then                                                    // Pokud je menöÌ neû nÏkter˝ z d¯Ìve nalezen˝ch nahradit ho
          if rt4 <= (RestTime + ZERO) then
            if not ((rt <= ZERO) and (Dot(uveloc,norm) > ZERO)) then
              begin
              normal := norm;
              point := Add(OldPos[i],Multiply(uveloc,rt));
              lamda := rt4;
              BallNr := i;
              end;
        end;
      // Kolize koule s v·lcem
      if TestIntersionCylinder(cyl1,OldPos[i],uveloc,rt,norm,Nc) then
        begin
        rt4 := rt * RestTime / rt2;                                             // »as n·razu
        if rt4 <= lamda then                                                    // Pokud je menöÌ neû nÏkter˝ z d¯Ìve nalezen˝ch nahradit ho
          if rt4 <= (RestTime + ZERO) then
            if not ((rt <= ZERO) and (Dot(uveloc,norm) > ZERO)) then
              begin
              normal := norm;
              point := Nc;
              lamda := rt4;
              BallNr := i;
              end;
        end;
      if TestIntersionCylinder(cyl2,OldPos[i],uveloc,rt,norm,Nc) then
        begin
        rt4 := rt * RestTime / rt2;                                             // »as n·razu
        if rt4 <= lamda then                                                    // Pokud je menöÌ neû nÏkter˝ z d¯Ìve nalezen˝ch nahradit ho
          if rt4 <= (RestTime + ZERO) then
            if not ((rt <= ZERO) and (Dot(uveloc,norm) > ZERO)) then
              begin
              normal := norm;
              point := Nc;
              lamda := rt4;
              BallNr := i;
              end;
        end;
      if TestIntersionCylinder(cyl3,OldPos[i],uveloc,rt,norm,Nc) then
        begin
        rt4 := rt * RestTime / rt2;                                             // »as n·razu
        if rt4 <= lamda then                                                    // Pokud je menöÌ neû nÏkter˝ z d¯Ìve nalezen˝ch nahradit ho
          if rt4 <= (RestTime + ZERO) then
            if not ((rt <= ZERO) and (Dot(uveloc,norm) > ZERO)) then
              begin
              normal := norm;
              point := Nc;
              lamda := rt4;
              BallNr := i;
              end;
        end;
      end;
    // Kolize mezi koulemi
    if FindBallCol(Pos2,BallTime,RestTime,BallColNr1,BallColNr2) then
      begin
      if sounds then PlaySound('Data/Explode.wav',0,SND_FILENAME or SND_ASYNC); // Jsou zapnutÈ zvuky?
      if (lamda = 10000) or (lamda > BallTime) then
        begin
        RestTime := RestTime - BallTime;
        pb1 := Add(OldPos[BallColNr1],Multiply(ArrayVel[BallColNr1],BallTime)); // NalezenÌ pozice koule 1
        pb2 := Add(OldPos[BallColNr2],Multiply(ArrayVel[BallColNr2],BallTime)); // NalezenÌ pozice koule 2
        xaxis := Uni(Subtract(pb2,pb1));                                        // NalezenÌ X_Axis
        a := Dot(xaxis,ArrayVel[BallColNr1]);                                   // NalezenÌ projekce
        U1x := Multiply(xaxis,a);                                               // NalezenÌ pr˘mÏt˘ vektor˘
        U1y := Subtract(ArrayVel[BallColNr1],U1x);
        xaxis := Uni(Subtract(pb1,pb2));                                        // NalezenÌ X_Axis
        b := Dot(xaxis,ArrayVel[BallColNr2]);                                   // NalezenÌ projekce
        U2x := Multiply(xaxis,b);                                               // NalezenÌ pr˘mÏt˘ vektor˘
        U2y := Subtract(ArrayVel[BallColNr2],U2x);
        V1x := U2x;                 // NalezenÌ nov˝ch rychlostÌ
        V2x := U1x;
        V1y := U1y;
        V2y := U2y;
        for j := 0 to NrOfBalls - 1 do                                          // Aktualizace pozic vöech koulÌ
          ArrayPos[j] := Add(OldPos[j],Multiply(ArrayVel[j],BallTime));
        ArrayVel[BallColNr1] := Add(V1x,V1y);                                   // NastavenÌ pr·vÏ vypoËÌtan˝ch vektor˘ koulÌm, kterÈ do sebe narazily
        ArrayVel[BallColNr2] := Add(V2x,V2y);
        // Aktualizace pole explozÌ
        for j := 0 to 19 do
          if ExplosionArray[j]._Alpha <= 0 then                                 // Hled· volnÈ mÌsto
            begin
            ExplosionArray[j]._Alpha := 1;                                      // Nepr˘hledn·
            ExplosionArray[j]._Position := ArrayPos[BallColNr1];                // Pozice
            ExplosionArray[j]._Scale := 1;                                      // MÏ¯Ìtko
            break;
            end;
        continue;
        end;
      end;
    // Konec test˘ kolizÌ
    // Pokud se proöel cel˝ Ëasov˝ ˙sek a byly vypoËteny reakce koulÌ, kterÈ narazily
    if lamda <> 10000 then
      begin
      RestTime := RestTime - lamda;                                             // OdeËtenÌ Ëasu kolize od ËasovÈho ˙seku
      for j := 0 to NrOfBalls - 1 do
        ArrayPos[j] := Add(OldPos[j],Multiply(ArrayVel[j],lamda));
      rt2 := Mag(ArrayVel[BallNr].x,ArrayVel[BallNr].y,ArrayVel[BallNr].z);
      ArrayVel[BallNr] := Uni(ArrayVel[BallNr]);
      ArrayVel[BallNr] := Uni(Add(Multiply(normal,2*Dot(normal,Invert(ArrayVel[BallNr]))),ArrayVel[BallNr]))  ;
      ArrayVel[BallNr] := Multiply(ArrayVel[BallNr],rt2);
      // Aktualizace pole explozÌ
      for j := 0 to 19 do
        if ExplosionArray[j]._Alpha <= 0 then                                   // Hled· volnÈ mÌsto
          begin
          ExplosionArray[j]._Alpha := 1;                                        // Nepr˘hledn·
          ExplosionArray[j]._Position := point;                                 // Pozice
          ExplosionArray[j]._Scale := 1;                                        // MÏ¯Ìtko
          break;                                                                // UkonËit prohled·v·nÌ
          end;
      end
      else
      RestTime := 0;                                                            // UkonËenÌ hlavnÌho cyklu a vlastnÏ i funkce
    end;
end;

procedure ProcessKeys;                                                          // Obsluha stisku kl·ves
begin
  if keys[VK_UP] then pos := Add(pos,Vektor(0,0,-10));
  if keys[VK_DOWN] then pos := Add(pos,Vektor(0,0,10));
  if keys[VK_LEFT] then camera_rotation := camera_rotation + 10;
  if keys[VK_RIGHT] then camera_rotation := camera_rotation - 10;
  if keys[VK_ADD] then
    begin
    Time := Time + 0.1;
    keys[VK_ADD] := false;
    end;
  if keys[VK_SUBTRACT] then
    begin
    Time := Time - 0.1;
    keys[VK_SUBTRACT] := false;
    end;
  if keys[VK_F3] then
    begin
    sounds := not sounds;
    keys[VK_F3] := false;
    end;
  if keys[VK_F2] then
    begin
    hook_toball1 := not hook_toball1;
    camera_rotation := 0;
    keys[VK_F2] := false;
    end;
end;

procedure ReSizeGLScene(Width: GLsizei; Height: GLsizei); // ZmÏna velikosti a inicializace OpenGL okna
begin
  if (Height=0) then		                                  // ZabezpeËenÌ proti dÏlenÌ nulou
     Height:=1;                                           // NastavÌ v˝öku na jedna
  glViewport(0, 0, Width, Height);                        // Resetuje aktu·lnÌ nastavenÌ
  glMatrixMode(GL_PROJECTION);                            // ZvolÌ projekËnÌ matici
  glLoadIdentity();                                       // Reset matice
  gluPerspective(50.0,Width/Height,10.0,1700.0);          // V˝poËet perspektivy
  glMatrixMode(GL_MODELVIEW);                             // ZvolÌ matici Modelview
  glLoadIdentity;                                         // Reset matice
end;


function InitGL:bool;	                              // Vöechno nastavenÌ OpenGL
var
  df: GLfloat;
begin
  df := 100.0;
  glClearDepth(1.0);				                        // NastavenÌ hloubkovÈho bufferu
  glEnable(GL_DEPTH_TEST);			                    // PovolÌ hloubkovÈ testov·nÌ
  glDepthFunc(GL_LEQUAL);				                    // Typ hloubkovÈho testov·nÌ
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST); // NejlepöÌ perspektivnÌ korekce
  glClearColor(0.0, 0.0, 0.0, 0.0);	  	            // »ernÈ pozadÌ
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glShadeModel(GL_SMOOTH);			                    // PovolÌ jemnÈ stÌnov·nÌ
  glEnable(GL_CULL_FACE);
  glEnable(GL_DEPTH_TEST);
  glMaterialfv(GL_FRONT,GL_SPECULAR,@spec);
	glMaterialfv(GL_FRONT,GL_SHININESS,@df);
  glEnable(GL_LIGHTING);
	glLightfv(GL_LIGHT0,GL_POSITION,@posl);
	glLightfv(GL_LIGHT0,GL_AMBIENT,@amb2);
	glEnable(GL_LIGHT0);
  glLightModelfv(GL_LIGHT_MODEL_AMBIENT,@amb);
	glEnable(GL_COLOR_MATERIAL);
	glColorMaterial(GL_FRONT,GL_AMBIENT_AND_DIFFUSE);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  glEnable(GL_TEXTURE_2D);                          // Zapne mapov·nÌ textur
  if not LoadGLTextures then                        // Nahraje texturu
    begin
    Result := false;
    exit;
    end;
  dlist := glGenLists(1);
  glNewList(dlist,GL_COMPILE);
    glBegin(GL_QUADS);
	    glRotatef(-45,0,1,0);
	    glNormal3f(0,0,1);
	    glTexCoord2f(0.0, 0.0); glVertex3f(-50,-40,0);
	    glTexCoord2f(0.0, 1.0); glVertex3f(50,-40,0);
	    glTexCoord2f(1.0, 1.0); glVertex3f(50,40,0);
	    glTexCoord2f(1.0, 0.0); glVertex3f(-50,40,0);
      glNormal3f(0,0,-1);
	    glTexCoord2f(0.0, 0.0); glVertex3f(-50,40,0);
	    glTexCoord2f(0.0, 1.0); glVertex3f(50,40,0);
	    glTexCoord2f(1.0, 1.0); glVertex3f(50,-40,0);
	    glTexCoord2f(1.0, 0.0); glVertex3f(-50,-40,0);
	    glNormal3f(1,0,0);
	    glTexCoord2f(0.0, 0.0); glVertex3f(0,-40,50);
	    glTexCoord2f(0.0, 1.0); glVertex3f(0,-40,-50);
	    glTexCoord2f(1.0, 1.0); glVertex3f(0,40,-50);
	    glTexCoord2f(1.0, 0.0); glVertex3f(0,40,50);
      glNormal3f(-1,0,0);
	    glTexCoord2f(0.0, 0.0); glVertex3f(0,40,50);
	    glTexCoord2f(0.0, 1.0); glVertex3f(0,40,-50);
	    glTexCoord2f(1.0, 1.0); glVertex3f(0,-40,-50);
	    glTexCoord2f(1.0, 0.0); glVertex3f(0,-40,50);
	  glEnd();
  glEndList();
  Result:=true;                                     // Inicializace probÏhla v po¯·dku
end;


function DrawGLScene():bool;                                                    // Vykreslov·nÌ
var
  i: integer;
  unit_followvector: TVector;
begin
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();	                                                            // Reset matice
  if hook_toball1 then                                                          // Sledov·nÌ koule?
	  begin
    unit_followvector := ArrayVel[0];
		unit_followvector := Uni(unit_followvector);
 		gluLookAt(ArrayPos[0].X+250,ArrayPos[0].Y+250,ArrayPos[0].Z,ArrayPos[0].X+ArrayVel[0].X,ArrayPos[0].Y+ArrayVel[0].Y,ArrayPos[0].Z+ArrayVel[0].Z,0.0,1.0,0.0);
    end
	  else
	  gluLookAt(pos.X,pos.Y,pos.Z,pos.X+dir.X,pos.Y+dir.Y,pos.Z+dir.Z,0.0,1.0,0.0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);                          // Smaûe obrazovku a hloubkov˝ buffer
  glRotatef(camera_rotation,0.0,1.0,0.0);                                       // Rotace
  for i := 0 to NrOfBalls - 1 do                                                // NastavenÌ barev pro koule
    begin
    case i of
      1: glColor3f(1.0,1.0,1.0);
      2: glColor3f(1.0,1.0,0.0);
      3: glColor3f(0.0,1.0,1.0);
      4: glColor3f(0.0,1.0,0.0);
      5: glColor3f(0.0,0.0,1.0);
      6: glColor3f(0.65,0.2,0.3);
      7: glColor3f(1.0,0.0,1.0);
      8: glColor3f(0.0,0.7,0.4);
      else
      glColor3f(1.0,0.0,0.0);
      end;
    glPushMatrix;
    glTranslated(ArrayPos[i].X,ArrayPos[i].Y,ArrayPos[i].Z);                    // VykreslenÌ koule
    gluSphere(cylinder_obj,20,20,20);
    glPopMatrix;
    end;
  glEnable(GL_TEXTURE_2D);                                                      // ZapnutÌ textur
	// OtexturovanÈ stÏny
	glBindTexture(GL_TEXTURE_2D, texture[3]);
	glColor3f(1, 1, 1);
	glBegin(GL_QUADS);
	glTexCoord2f(1.0, 0.0); glVertex3f(320,320,320);
	glTexCoord2f(1.0, 1.0); glVertex3f(320,-320,320);
  glTexCoord2f(0.0, 1.0); glVertex3f(-320,-320,320);
	glTexCoord2f(0.0, 0.0); glVertex3f(-320,320,320);
	glTexCoord2f(1.0, 0.0); glVertex3f(-320,320,-320);
	glTexCoord2f(1.0, 1.0); glVertex3f(-320,-320,-320);
  glTexCoord2f(0.0, 1.0); glVertex3f(320,-320,-320);
	glTexCoord2f(0.0, 0.0); glVertex3f(320,320,-320);
	glTexCoord2f(1.0, 0.0); glVertex3f(320,320,-320);
	glTexCoord2f(1.0, 1.0); glVertex3f(320,-320,-320);
  glTexCoord2f(0.0, 1.0); glVertex3f(320,-320,320);
	glTexCoord2f(0.0, 0.0); glVertex3f(320,320,320);
	glTexCoord2f(1.0, 0.0); glVertex3f(-320,320,320);
	glTexCoord2f(1.0, 1.0); glVertex3f(-320,-320,320);
  glTexCoord2f(0.0, 1.0); glVertex3f(-320,-320,-320);
	glTexCoord2f(0.0, 0.0); glVertex3f(-320,320,-320);
	glEnd;
	// Otexturovan· podlaha
	glBindTexture(GL_TEXTURE_2D, texture[2]);
  glBegin(GL_QUADS);
	glTexCoord2f(1.0, 0.0); glVertex3f(-320,-320,320);
	glTexCoord2f(1.0, 1.0); glVertex3f(320,-320,320);
  glTexCoord2f(0.0, 1.0); glVertex3f(320,-320,-320);
	glTexCoord2f(0.0, 0.0); glVertex3f(-320,-320,-320);
	glEnd;
  // V·lce
	glBindTexture(GL_TEXTURE_2D, texture[0]);
	glColor3f(0.5,0.5,0.5);
  glPushMatrix;
	glRotatef(90, 1,0,0);
	glTranslatef(0,0,-500);
	gluCylinder(cylinder_obj, 60, 60, 1000, 20, 2);
	glPopMatrix;
  glPushMatrix;
  glTranslatef(200,-300,-500);
	gluCylinder(cylinder_obj, 60, 60, 1000, 20, 2);
	glPopMatrix;
	glPushMatrix;
  glTranslatef(-200,0,0);
	glRotatef(135, 1,0,0);
	glTranslatef(0,0,-500);
	gluCylinder(cylinder_obj, 30, 30, 1000, 20, 2);
	glPopMatrix;
  glEnable(GL_BLEND);                                                           // Blending
  glDepthMask(GL_FALSE);                                                        // Vypne z·pis do depth bufferu
  glBindTexture(GL_TEXTURE_2D, texture[1]);                                     // Textura exploze
  for i := 0 to 19 do                                                           // Proch·zÌ v˝buchy
    if ExplosionArray[i]._Alpha >= 0 then                                       // Je exploze vidÏt?
      begin
      glPushMatrix;                                                             // Z·loha matice
      ExplosionArray[i]._Alpha := ExplosionArray[i]._Alpha - 0.01;              // Aktualizace alfa hodnoty
      ExplosionArray[i]._Scale := ExplosionArray[i]._Scale + 0.03;              // Aktualizace mÏ¯Ìtka
      glColor4f(1,1,0,ExplosionArray[i]._Alpha);                                // élut· barva s pr˘hlednostÌ
      glScalef(ExplosionArray[i]._Scale,ExplosionArray[i]._Scale,ExplosionArray[i]._Scale); // ZmÏna mÏ¯Ìtka
      glTranslatef(ExplosionArray[i]._Position.X/ExplosionArray[i]._Scale,ExplosionArray[i]._Position.Y/ExplosionArray[i]._Scale,ExplosionArray[i]._Position.Z/ExplosionArray[i]._Scale); // P¯esun na pozici koliznÌho bodu, mÏ¯Ìtko je offsetem
      glCallList(dlist);                                                        // Zavol· display list
      glPopMatrix;                                                              // Obnova p˘vodnÌ matice
      end; 
  glDepthMask(GL_TRUE);                                                         // Obnova p˘vodnÌch parametr˘ OpenGL
  glDisable(GL_BLEND);
  glDisable(GL_TEXTURE_2D);
  Result := true;                                                               // VykreslenÌ probÏhlo v po¯·dku
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
  InitVars;                                           // Inicializace promÏnn˝ch
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
            begin
            Idle;                                     // VlastnÌ logika simulace
            SwapBuffers(h_Dc);                        // ProhozenÌ buffer˘ (Double Buffering)
            end;
          if keys[VK_F1] then                         // Byla stisknuta kl·vesa F1?
            begin
            Keys[VK_F1] := false;                     // OznaË ji jako nestisknutou
            KillGLWindow();                           // ZruöÌ okno
            FullScreen := not FullScreen;             // Negace fullscreen
            // Znovuvytvo¯enÌ okna
            if not CreateGLWindow('NeHe''s OpenGL Framework',640,480,16,fullscreen) then
              Result := 0;                            // Konec programu pokud nebylo vytvo¯eno
            end;
          ProcessKeys;                                // Obsluha stisku kl·ves
        end;
    end;                                              // Konec smyËky while
  killGLwindow();                                     // Zav¯e okno
  glDeleteTextures(4,texture[0]);                     // Smaûe textury
  glDeleteLists(dlist,1);                             // ZruöÌ displaylist
  result:=msg.wParam;                                 // UkonËenÌ programu
end;

begin
  WinMain( hInstance, hPrevInst, CmdLine, CmdShow );   // Start programu
end.

