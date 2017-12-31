unit ArcBall;

//******************************************************************************
// Jen to nejnutnìjší ze souborù arcball.h a arcball.cpp
//******************************************************************************

interface

uses Windows, OpenGL, math;

//******************************************************************************
// Definice typù jsem poupravit tak, aby byly funkèní a zároveò co nejvíce
// podobné originálnímu kódu. Je však pro mì záhadou, jak to v C++ funguje.
// Tøi dny jsem strávil trace-ováním kódu, abych zjistil, že urèitá èást
// struktury "s" v záznamu se "kopíruje" do pole "M". Já osobnì bych používal
// buï pole nebo záznamy, ale nekombinoval bych to. Pokud nìkdo zná vysvìtlení,
// rád se pouèím :-)) Výsledek je tedy trochu nepøehledný, ale funguje.
//
// PS: Díky Radomíru Vránovi, za èlánek o maticích v OpenGL. Díky jemu jsem zjistil,
// že prvky matice se do pole ukládají po øádcích a ne po sloupcích. (A já se
// divil, proè to furt nechce rotovat!!!!)
//******************************************************************************

type
  Vector3fT = record                      // Vektor
    s: record
      X, Y, Z: GLfloat;
      end;
    //T: array [0..2] of GLfloat;         // Nevím, k èemu to mìlo být v originále, ale nikde jsem nenašel, že by se to použilo
    end;

  Point2fT = record                       // Bod
    s: record
      X, Y: GLfloat;
      end;
    //T: array [0..1] of GLfloat;
    end;

  Quat4ft = record                        // Quternion
    s: record
      X, Y, Z, W: GLfloat;
      end;
    //T: array [0..3] of GLfloat;
    end;

  Matrix4fT = record                      // Matice 4x4
    s: record
      M00, XX, SX: GLfloat;
      M10, XY: GLfloat;
      M20, XZ: GLfloat;
      M30, XW: GLfloat;
      M01, YX: GLfloat;
      M11, YY, SY: GLfloat;
      M21, YZ: GLfloat;
      M31, YW: GLfloat;
      M02, ZX: GLfloat;
      M12, ZY: GLfloat;
      M22, ZZ, SZ: GLfloat;
      M32, ZW: GLfloat;
      M03, TX: GLfloat;
      M13, TY: GLfloat;
      M23, TZ: GLfloat;
      M33, TW, SW: GLfloat;
      end;
    M: array [0..15] of GLfloat;
    end;

  Matrix3fT = record                      // Matice 3x3
    s: record
      M00, XX, SX: GLfloat;
      M10, XY: GLfloat;
      M20, XZ: GLfloat;
      M01, YX: GLfloat;
      M11, YY, SY: GLfloat;
      M21, YZ: GLfloat;
      M02, ZX: GLfloat;
      M12, ZY: GLfloat;
      M22, ZZ, SZ: GLfloat;
      end;
    M: array [0..8] of GLfloat;
    end;

  PVector3fT = ^Vector3fT;                // Ukazatele na jednotlivé datové typy
  PPoint2fT = ^Point2fT;
  PQuat4ft = ^Quat4ft;
  PMatrix3fT = ^Matrix3fT;
  PMatrix4fT = ^Matrix4fT;

  ArcBallT = class                                                              // Tøída ArcBall
    protected
      StVec: Vector3fT;                                                         // Poèáteèní vektor
      EnVec: Vector3fT;                                                         // Koncový vektor
      AdjustWidth: GLfloat;                                                     // Korekce šíøky
      AdjustHeight: GLfloat;                                                    // Korekce výšky
      procedure _mapToSphere(const NewPt: PPoint2fT; NewVec: PVector3fT);       // Mapování
    public
      constructor Create(NewWidth, NewHeight: GLfloat);                         // Konstruktor
      destructor Destroy; override;                                             // Destruktor
      procedure setBounds(NewWidth, NewHeight: GLfloat);                        // Nastavení oktrajù
      procedure click(const NewPt: PPoint2fT);                                  // Kliknutí myší
      procedure drag(const NewPt: PPoint2fT; NewRot: PQuat4fT);                 // Tažení myší
    end;

procedure Matrix3fSetIdentity(NewObj: PMatrix3fT);                              // Aby bylo procedure vidìt i mimo unitu
procedure Matrix4fSetRotationFromMatrix3f(NewObj: PMatrix4fT; const m1: PMatrix3fT);
procedure Matrix3fSetRotationFromQuat4f(NewObj: PMatrix3fT; const q1: PQuat4fT);
procedure Matrix3fMulMatrix3f(NewObj: PMatrix3fT; const m1: PMatrix3fT);

const
  Epsilon = 1.0e-5;

implementation

procedure ValueToArray(Obj: PMatrix3fT); overload;                              // Mùj vlastní výplod
begin                                                                           // Procedury na zkopírování hodnot ze záznamu do pole
  with Obj^ do
    begin
    M[0] := s.M00;
    M[1] := s.M10;
    M[2] := s.M20;
    M[3] := s.M01;
    M[4] := s.M11;
    M[5] := s.M21;
    M[6] := s.M02;
    M[7] := s.M12;
    M[8] := s.M22;
    end;
end;

procedure ValueToArray(Obj: PMatrix4fT); overload;
begin
  with Obj^ do
    begin
    M[0] := s.XX;
    M[1] := s.YX;
    M[2] := s.ZX;
    M[3] := 0;
    M[4] := s.XY;
    M[5] := s.YY;
    M[6] := s.ZY;
    M[7] := 0;
    M[8] := s.XZ;
    M[9] := s.YZ;
    M[10] := s.ZZ;
    M[11] := 0;
    M[12] := s.XW;
    M[13] := s.YW;
    M[14] := s.ZW;
    M[15] := 1;
    end;
end;

procedure Vector3fCross(NewObj: PVector3fT; const v1, v2: PVector3fT);          // Vektorový souèin
begin
  NewObj.s.X := (v1.s.Y * v2.s.Z) - (v1.s.Z * v2.s.Y);
  NewObj.s.Y := (v1.s.Z * v2.s.X) - (v1.s.X * v2.s.Z);
  NewObj.s.Z := (v1.s.X * v2.s.Y) - (v1.s.Y * v2.s.X);
end;

function Vector3fLength(const NewObj: PVector3fT): GLfloat;                     // Délka vektoru
begin
  Result := Sqrt(Sqr(NewObj.s.X) + Sqr(NewObj.s.Y) + Sqr(NewObj.s.Z));
end;

function Vector3fDot(const NewObj, v1: PVector3fT): GLfloat;                    // Skalární souèin
begin
  Result := (NewObj.s.X * v1.s.X) + (NewObj.s.Y * v1.s.Y) + (NewObj.s.Z * v1.s.Z);
end;

procedure Matrix3fSetZero(NewObj: PMatrix3fT);                                  // Nulování matice
begin                                                                           // Pùvodní kód nìjak nechodil, tak jsem to vyøešil po svém
  ZeroMemory(NewObj,sizeof(Matrix3fT));
end;

procedure Matrix3fSetIdentity(NewObj: PMatrix3fT);                              // Reset Matice - obdoba glLoadIdentity
begin
  Matrix3fSetZero(NewObj);
  NewObj.s.M00 := 1.0;
  NewObj.s.XX := 1.0;
  NewObj.s.M11 := 1.0;
  NewObj.s.YY := 1.0;
  NewObj.s.M22 := 1.0;
  NewObj.s.ZZ := 1.0;
  ValueToArray(NewObj);
end;

procedure Matrix4fSetRotationScaleFromMatrix4f(NewObj: PMatrix4fT; const m1: PMatrix4fT); // Nastavení hodnot matice
begin
  NewObj.s.XX := m1.s.XX; NewObj.s.YX := m1.s.YX; NewObj.s.ZX := m1.s.ZX;
  NewObj.s.XY := m1.s.XY; NewObj.s.YY := m1.s.YY; NewObj.s.ZY := m1.s.ZY;
  NewObj.s.XZ := m1.s.XZ; NewObj.s.YZ := m1.s.YZ; NewObj.s.ZZ := m1.s.ZZ;
  ValueToArray(NewObj);
end;

function Matrix4fSVD(const NewObj: PMatrix4fT; rot3: PMatrix3fT; rot4: PMatrix4fT): GLfloat;
var
  s, n: GLfloat;
begin
  s := Sqrt((Sqr(NewObj.s.XX) + Sqr(NewObj.s.XY) + Sqr(NewObj.s.XZ) +
             Sqr(NewObj.s.YX) + Sqr(NewObj.s.YY) + Sqr(NewObj.s.YZ) +
             Sqr(NewObj.s.ZX) + Sqr(NewObj.s.ZY) + Sqr(NewObj.s.ZZ)) / 3.0);
  if Assigned(rot3) then
    begin
    rot3.s.XX := NewObj.s.XX; rot3.s.XY := NewObj.s.XY; rot3.s.XZ := NewObj.s.XZ;
    rot3.s.YX := NewObj.s.YX; rot3.s.YY := NewObj.s.YY; rot3.s.YZ := NewObj.s.YZ;
    rot3.s.ZX := NewObj.s.ZX; rot3.s.ZY := NewObj.s.ZY; rot3.s.ZZ := NewObj.s.ZZ;
    n := 1.0 / Sqrt(Sqr(NewObj.s.XX) + Sqr(NewObj.s.XY) + Sqr(NewObj.s.XZ));
    rot3.s.XX := rot3.s.XX * n;
    rot3.s.XY := rot3.s.XY * n;
    rot3.s.XZ := rot3.s.XZ * n;
    n := 1.0 / Sqrt(Sqr(NewObj.s.YX) + Sqr(NewObj.s.YY) + Sqr(NewObj.s.YZ));
    rot3.s.YX := rot3.s.YX * n;
    rot3.s.YY := rot3.s.YY * n;
    rot3.s.YZ := rot3.s.YZ * n;
    n := 1.0 / Sqrt(Sqr(NewObj.s.ZX) + Sqr(NewObj.s.ZY) + Sqr(NewObj.s.ZZ));
    rot3.s.ZX := rot3.s.ZX * n;
    rot3.s.ZY := rot3.s.ZY * n;
    rot3.s.ZZ := rot3.s.ZZ * n;
    ValueToArray(rot3);
    end;
  if Assigned(rot4) then
    begin
    if rot4 <> NewObj then Matrix4fSetRotationScaleFromMatrix4f(rot4, NewObj);
    n := 1.0 / Sqrt(Sqr(NewObj.s.XX) + Sqr(NewObj.s.XY) + Sqr(NewObj.s.XZ));
    rot4.s.XX := rot4.s.XX * n;
    rot4.s.XY := rot4.s.XY * n;
    rot4.s.XZ := rot4.s.XZ * n;
    n := 1.0 / Sqrt(Sqr(NewObj.s.YX) + Sqr(NewObj.s.YY) + Sqr(NewObj.s.YZ));
    rot4.s.YX := rot4.s.YX * n;
    rot4.s.YY := rot4.s.YY * n;
    rot4.s.YZ := rot4.s.YZ * n;
    n := 1.0 / Sqrt(Sqr(NewObj.s.ZX) + Sqr(NewObj.s.ZY) + Sqr(NewObj.s.ZZ));
    rot4.s.ZX := rot4.s.ZX * n;
    rot4.s.ZY := rot4.s.ZY * n;
    rot4.s.ZZ := rot4.s.ZZ * n;
    ValueToArray(rot4);
    end;
  Result := s;
end;

procedure Matrix4fSetRotationScaleFromMatrix3f(NewObj: PMatrix4fT; const m1: PMatrix3fT); // Nastavení matice
begin
  NewObj.s.XX := m1.s.XX; NewObj.s.YX := m1.s.YX; NewObj.s.ZX := m1.s.ZX;
  NewObj.s.XY := m1.s.XY; NewObj.s.YY := m1.s.YY; NewObj.s.ZY := m1.s.ZY;
  NewObj.s.XZ := m1.s.XZ; NewObj.s.YZ := m1.s.YZ; NewObj.s.ZZ := m1.s.ZZ;
  ValueToArray(NewObj);
end;

procedure Matrix4fMulRotationScale(NewObj: PMatrix4fT; scale: GLfloat);         // Násobení matice
begin
  NewObj.s.XX := NewObj.s.XX * scale; NewObj.s.YX := NewObj.s.YX * scale; NewObj.s.ZX := NewObj.s.ZX * scale;
  NewObj.s.XY := NewObj.s.XY * scale; NewObj.s.YY := NewObj.s.YY * scale; NewObj.s.ZY := NewObj.s.ZY * scale;
  NewObj.s.XZ := NewObj.s.XZ * scale; NewObj.s.YZ := NewObj.s.YZ * scale; NewObj.s.ZZ := NewObj.s.ZZ * scale;
end;

procedure Matrix4fSetRotationFromMatrix3f(NewObj: PMatrix4fT; const m1: PMatrix3fT);  // Nastavení rotace z matice
var
  scale: GLfloat;
begin
  scale := Matrix4fSVD(NewObj,nil,nil);
  Matrix4fSetRotationScaleFromMatrix3f(NewObj,m1);
  Matrix4fMulRotationScale(NewObj,scale);
end;

procedure Matrix3fSetRotationFromQuat4f(NewObj: PMatrix3fT; const q1: PQuat4fT);  // Nastavení rotace z Quaternionu
var
  n, s: GLfloat;
  xs, ys, zs: GLfloat;
  wx, wy, wz: GLfloat;
  xx, xy, xz: GLfloat;
  yy, yz, zz: GLfloat;
begin
  n := Sqr(q1.s.X) + Sqr(q1.s.Y) + Sqr(q1.s.Z) + Sqr(q1.s.W);
  if n > 0.0 then
    s := 2.0 / n
    else
    s := 0.0;
  xs := q1.s.X * s;  ys := q1.s.Y * s;  zs := q1.s.Z * s;
  wx := q1.s.W * xs; wy := q1.s.W * ys; wz := q1.s.W * zs;
  xx := q1.s.X * xs; xy := q1.s.X * ys; xz := q1.s.X * zs;
  yy := q1.s.Y * ys; yz := q1.s.Y * zs; zz := q1.s.Z * zs;
  NewObj.s.XX := 1.0 - (yy + zz); NewObj.s.YX :=        xy - wz;  NewObj.s.ZX :=        xz + wy;
  NewObj.s.XY :=        xy + wz;  NewObj.s.YY := 1.0 - (xx + zz); NewObj.s.ZY :=        yz - wx;
  NewObj.s.XZ :=        xz - wy;  NewObj.s.YZ :=        yz + wx;  NewObj.s.ZZ := 1.0 - (xx + yy);
  ValueToArray(NewObj);
end;

procedure Matrix3fMulMatrix3f(NewObj: PMatrix3fT; const m1: PMatrix3fT);        // Násobení matice maticí
var
  Res: Matrix3fT;
begin
  Res.s.XX := (NewObj.s.XX * m1.s.XX) + (NewObj.s.YX * m1.s.XY) + (NewObj.s.ZX * m1.s.XZ);
  Res.s.YX := (NewObj.s.XX * m1.s.YX) + (NewObj.s.YX * m1.s.YY) + (NewObj.s.ZX * m1.s.YZ);
  Res.s.ZX := (NewObj.s.XX * m1.s.ZX) + (NewObj.s.YX * m1.s.ZY) + (NewObj.s.ZX * m1.s.ZZ);
  Res.s.XY := (NewObj.s.XY * m1.s.XX) + (NewObj.s.YY * m1.s.XY) + (NewObj.s.ZY * m1.s.XZ);
  Res.s.YY := (NewObj.s.XY * m1.s.YX) + (NewObj.s.YY * m1.s.YY) + (NewObj.s.ZY * m1.s.YZ);
  Res.s.ZY := (NewObj.s.XY * m1.s.ZX) + (NewObj.s.YY * m1.s.ZY) + (NewObj.s.ZY * m1.s.ZZ);
  Res.s.XZ := (NewObj.s.XZ * m1.s.XX) + (NewObj.s.YZ * m1.s.XY) + (NewObj.s.ZZ * m1.s.XZ);
  Res.s.YZ := (NewObj.s.XZ * m1.s.YX) + (NewObj.s.YZ * m1.s.YY) + (NewObj.s.ZZ * m1.s.YZ);
  Res.s.ZZ := (NewObj.s.XZ * m1.s.ZX) + (NewObj.s.YZ * m1.s.ZY) + (NewObj.s.ZZ * m1.s.ZZ);
  NewObj.s := Res.s;
  ValueToArray(NewObj);
end;

{ ArcBallT }

procedure ArcBallT._mapToSphere(const NewPt: PPoint2fT; NewVec: PVector3fT);
var
  TempPt: Point2fT;
  length: GLfloat;
  norm: GLfloat;
begin
  TempPt := NewPt^;
  TempPt.s.X  := (TempPt.s.X * AdjustWidth) - 1.0;
  TempPt.s.Y  := 1.0 - (TempPt.s.Y * AdjustHeight);
  length := (TempPt.s.X * TempPt.s.X) + (TempPt.s.Y * TempPt.s.Y);
  if length > 1.0 then
    begin
    norm := 1.0 / Sqrt(length);
    NewVec.s.X := TempPt.s.X * norm;
    NewVec.s.Y := TempPt.s.Y * norm;
    NewVec.s.Z := 0.0;
    end
    else
    begin
    NewVec.s.X := TempPt.s.X;
    NewVec.s.Y := TempPt.s.Y;
    NewVec.s.Z := Sqrt(1.0 - length);
    end;
end;

procedure ArcBallT.click(const NewPt: PPoint2fT);
begin
  _mapToSphere(NewPt,@StVec);
end;

constructor ArcBallT.Create(NewWidth, NewHeight: GLfloat);
begin
  StVec.s.X := 0.0;
  StVec.s.Y := 0.0;
  StVec.s.Z := 0.0;
  EnVec.s.X := 0.0;
  EnVec.s.Y := 0.0;
  EnVec.s.Z := 0.0;
  setBounds(NewWidth,NewHeight);
end;

destructor ArcBallT.Destroy;
begin
  inherited;
end;

procedure ArcBallT.drag(const NewPt: PPoint2fT; NewRot: PQuat4fT);
var
  Perp: Vector3fT;
begin
  _mapToSphere(NewPt,@EnVec);
  if Assigned(NewRot) then
    begin
    ZeroMemory(@Perp,sizeof(Vector3fT));
    Vector3fCross(@Perp,@StVec,@EnVec);
    if Vector3fLength(@Perp) > Epsilon then    
      begin
      NewRot.s.X := Perp.s.X;
      NewRot.s.Y := Perp.s.Y;
      NewRot.s.Z := Perp.s.Z;
      NewRot.s.W := Vector3fDot(@StVec,@EnVec);
      end
      else
      begin
      NewRot.s.X := 0.0;
      NewRot.s.Y := 0.0;
      NewRot.s.Z := 0.0;
      NewRot.s.W := 0.0;
      end;
    end;
end;

procedure ArcBallT.setBounds(NewWidth, NewHeight: GLfloat);
begin
  AdjustWidth := 1.0 / ((NewWidth - 1.0) * 0.5);
  AdjustHeight := 1.0 / ((NewHeight - 1.0) * 0.5);
end;

end.
