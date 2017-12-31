unit Vector;

interface

type
  TVector = record                                                              // Struktura vektoru
  x, y, z: Double;
  end;

function Vektor(x, y, z: Double): TVector;
function Mag(x, y, z:Double): Double;
function Uni(V1: TVector): TVector;
function Dot(v1, v2: TVector): Double;
function Subtract(v1, v2: TVector): TVector;
function Cross(v1, v2: TVector): TVector;
function Add(v1, v2: TVector): TVector;
function Multiply(v1: TVector; scale: Double): TVector;
function DistV(v1, v2: TVector): Double;
function Invert(v1: TVector): TVector;
   
const
  EPSILON = 1.0e-8;


implementation

function Vektor(x, y, z: Double): TVector;                // Vrací vektor
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
end;

function Mag(x, y, z:Double): Double;                     // Vrací velikost vektoru
begin
  Result := sqrt(sqr(x) + sqr(y) + sqr(z));
end;

function Uni(V1: TVector): TVector;                       // Vrací jednotkový vektor
var
  rep: Double;
begin
  rep := Mag(V1.x,V1.y,V1.z);
  if rep < EPSILON then
    begin
    Result.x := 0.0;
    Result.y := 0.0;
    Result.z := 0.0;
    end
    else
    begin
    Result.x := V1.x / rep;
    Result.y := V1.y / rep;
    Result.z := V1.z / rep;
    end;
end;

function Dot(v1, v2: TVector): Double;                    // Skalární souèin
begin
  Result := v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
end;

function Subtract(v1, v2: TVector): TVector;              // Rozdíl
begin
  Result.x := v1.x - v2.x;
  Result.y := v1.y - v2.y;
  Result.z := v1.z - v2.z;
end;

function Cross(v1, v2: TVector): TVector;                 // Vektorový souèin
begin
  Result.x := v1.y*v2.z - v1.z*v2.y;
  Result.y := v1.z*v2.x - v1.x*v2.z;
  Result.z := v1.x*v2.y - v1.y*v2.x;
end;

function Add(v1, v2: TVector): TVector;                   // Souèet
begin
  Result.x := v1.x + v2.x;
  Result.y := v1.y + v2.y;
  Result.z := v1.z + v2.z;
end;

function Multiply(v1: TVector; scale: Double): TVector;   // Násobení
begin
  Result.x := v1.x * scale;
  Result.y := v1.y * scale;
  Result.z := v1.z * scale;
end;

function DistV(v1, v2: TVector): Double;                  // Vzdálenost vektorù
var
  tmp: TVector;
begin
  tmp := Subtract(v1,v2);
  Result := Mag(tmp.x,tmp.y,tmp.z);;
end;

function Invert(v1: TVector): TVector;                    // Inverzní vektor
begin
  Result.x := -v1.x;
  Result.y := -v1.y;
  Result.z := -v1.z;
end;

end.
