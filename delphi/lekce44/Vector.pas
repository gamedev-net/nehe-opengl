unit Vector;

interface

type
  glVector = class
    public
      i, j, k: Double;
      m_Mag: Double;
      constructor Create;
      destructor Destroy; override;
      procedure MultiplySelf(scalar: Double);
      function Magnitude: Double;
      procedure Normalize;
      function Multiply(scalar: Double): glVector;
      function Add(v: glVector): glVector;
      procedure Assign(v: glVector);
    end;

implementation

{ glVector }

function glVector.Add(v: glVector): glVector;
var
  r: glVector;
begin
  r := glVector.Create;
  r.i := i + v.i;
  r.j := j + v.j;
  r.k := k + v.k;
  Result := r;
  r.Free;
end;

procedure glVector.Assign(v: glVector);
begin
  i := v.i;
  j := v.j;
  k := v.k;
  m_Mag := v.m_Mag;
end;

constructor glVector.Create;
begin
  inherited;
  i := 0.0;
  j := 0.0;
  k := 0.0;
  m_Mag := 0.0;
end;

destructor glVector.Destroy;
begin
  inherited;
end;

function glVector.Magnitude: Double;
var
  res: Double;
begin
  res := sqrt(sqr(i) + sqr(j) + sqr(k));
  m_Mag := res;
  Result := res;
end;

function glVector.Multiply(scalar: Double): glVector;
var
  r: glVector;
begin
  r := glVector.Create;
  r.i := i * scalar;
  r.j := j * scalar;
  r.k := k * scalar;
  Result := r;
  r.Free;
end;

procedure glVector.MultiplySelf(scalar: Double);
begin
  i := i * scalar;
  j := j * scalar;
  k := k * scalar;
end;

procedure glVector.Normalize;
begin
  if m_Mag <> 0.0 then
    begin
    i := i / m_Mag;
    j := j / m_Mag;
    k := k / m_Mag;
    Magnitude;
    end;
end;

end.
