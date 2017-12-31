unit Point;

interface
 
uses Vector;

type
  glPoint = class
    public
      x, y, z: Double;
      constructor Create;
      destructor Destroy; override;
      procedure Assign(v: glVector); overload;
      procedure Assign(p: glPoint); overload;
      function Subtract(p: glPoint): glVector;
      function Add(p: glPoint): glPoint;
      procedure AddSelf(p: glPoint);
    end;

implementation

{ glPoint }

function glPoint.Add(p: glPoint): glPoint;    
var
  r: glPoint;
begin
  r := glPoint.Create;
  r.x := x + p.x;
  r.y := y + p.y;
  r.z := z + p.z;
  Result := r;
  r.Free;
end;

procedure glPoint.AddSelf(p: glPoint);
begin
  x := x + p.x;
  y := y + p.y;
  z := z + p.z;
end;

procedure glPoint.Assign(v: glVector);
begin
  x := v.i;
  y := v.j;
  z := v.k;
end;

procedure glPoint.Assign(p: glPoint);
begin
  x := p.x;
  y := p.y;
  z := p.z;
end;

constructor glPoint.Create;
begin
  inherited;
  x := 0.0;
  y := 0.0;
  z := 0.0;
end;

destructor glPoint.Destroy;
begin
  inherited;
end;

function glPoint.Subtract(p: glPoint): glVector;
var
  r: glVector;
begin
  r := glVector.Create;
  r.i := x - p.x;
  r.j := y - p.y;
  r.k := z - p.z;
  Result := r;
  r.Free;
end;

end.
