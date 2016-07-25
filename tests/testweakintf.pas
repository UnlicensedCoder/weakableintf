unit testweakintf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, weakable;

type

  TTestWeakIntf= class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test1;
  end;

implementation

var
  _GentlemanCount, _LadyCount: Integer;

procedure ResetCount;
begin
  _GentlemanCount := 0;
  _LadyCount := 0;
end;

type
  IGentleman = interface;

  ILady = interface
  ['{EBF25A5B-60F8-48D4-8309-AD0F63C40E84}']
    function GetGentleman: IGentleman;
    procedure SetGentleman(const Value: IGentleman);
    property Gentleman: IGentleman read GetGentleman write SetGentleman;
  end;

  IGentleman = interface
  ['{00F07C37-2569-4B18-85B4-71D404C4019E}']
    function GetLady: ILady;
    procedure SetLady(const Value: ILady);
    property Lady: ILady read GetLady write SetLady;
  end;

  { TLadyObj }

  TLadyObj = class(TWeakableInterfaced, ILady)
  private
    FGentlemanIntf: IWeakInterface;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetGentleman(const Value: IGentleman);
    function GetGentleman: IGentleman;
  end;

  { TGentlemanObj }

  TGentlemanObj = class(TWeakableInterfaced, IGentleman)
  private
    FLadyIntf: IWeakInterface;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetLady(const Value: ILady);
    function GetLady: ILady;
  end;

{ TLadyObj }

constructor TLadyObj.Create;
begin
  inherited;
  Inc(_LadyCount);
end;

destructor TLadyObj.Destroy;
begin
  Dec(_LadyCount);
  inherited Destroy;
end;

function TLadyObj.GetGentleman: IGentleman;
begin
  result := FGentlemanIntf.Ref as IGentleman;
end;

procedure TLadyObj.SetGentleman(const Value: IGentleman);
begin
  FGentlemanIntf := (Value as IWeakable).Weak;
end;

{ TGentlemanObj }

constructor TGentlemanObj.Create;
begin
  inherited;
  Inc(_GentlemanCount);
end;

destructor TGentlemanObj.Destroy;
begin
  Dec(_GentlemanCount);
  inherited Destroy;
end;

function TGentlemanObj.GetLady: ILady;
begin
  result := FLadyIntf.Ref as ILady;
end;

procedure TGentlemanObj.SetLady(const Value: ILady);
begin
  FLadyIntf := (Value as IWeakable).Weak;
end;

procedure TTestWeakIntf.Test1;
var
  lady: ILady;
  gentleman: IGentleman;
begin
  lady := TLadyObj.Create;
  gentleman := TGentlemanObj.Create;
  lady.Gentleman := gentleman;
  gentleman.Lady := lady;

  lady := nil;
  gentleman := nil;

  Self.CheckEquals(0, _GentlemanCount);
  Self.CheckEquals(0, _LadyCount);
end;

procedure TTestWeakIntf.SetUp;
begin

end;

procedure TTestWeakIntf.TearDown;
begin

end;

initialization

  RegisterTest(TTestWeakIntf);
end.

