// @NolicenseCoder
unit Weakable;
{$ifdef fpc}
{$mode delphi}{$h+}
{$endif}
interface
{$ifndef fpc}
uses Windows;
{$endif}

type
  TSharedCounter = class
  protected
    FRefCount, FWeakCount: Integer;
  public
    function AddRef: Integer; virtual;
    function ReleaseRef: Integer; virtual;
    function AddRefLock: Integer; virtual;
    function WeakAdd: Integer; virtual;
    function WeakRelease: Integer; virtual;
  end;

  TSingleSharedCounter = class(TSharedCounter)
  public
    function AddRef: Integer; override;
    function ReleaseRef: Integer; override;
    function AddRefLock: Integer; override;
    function WeakAdd: Integer; override;
    function WeakRelease: Integer; override;
  end;

  IWeakInterface = interface
  ['{55B04F56-4A59-42A8-A71A-CF226A107426}']
    function GetRef: IInterface;
    property Ref: IInterface read GetRef;
  end;

  IWeakable = interface
  ['{D6503E86-9316-499E-9421-F21FECDAE6AC}']
    function GetWeak: IWeakInterface;
    property Weak: IWeakInterface read GetWeak;
  end;

  TWeakInterface = class(TInterfacedObject, IWeakInterface)
  private
    FCounter: TSharedCounter;
    FRef: Pointer;
    function GetRef: IInterface;
  public
    destructor Destroy; override;
    property Ref: IInterface read GetRef;
  end;

  TWeakableInterfaced = class(TObject, IInterface, IWeakable)
  private
    FCounter: TSharedCounter;
    function GetWeak: IWeakInterface;
    function GetRefCount: Integer;
  protected
    function QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    class function NewInstance: TObject; override;
    property RefCount: Integer read GetRefCount;
    property Weak: IWeakInterface read GetWeak;
  end;

  TWeakableInterfacedClass = class of TWeakableInterfaced;

function WeakOf(const Intf: IInterface): IWeakInterface;

implementation

function WeakOf(const Intf: IInterface): IWeakInterface;
begin
  Result := (Intf as IWeakable).Weak;
end;

{ TWeakableInterfaced }

function TWeakableInterfaced._AddRef: Integer;
begin
  Result := FCounter.AddRef;
end;

function TWeakableInterfaced._Release: Integer;
begin
  Result := FCounter.ReleaseRef;
  if Result = 0 then
    Destroy;
end;

procedure TWeakableInterfaced.AfterConstruction;
begin
// Release the constructor's implicit refcount
  FCounter.ReleaseRef;
end;

procedure TWeakableInterfaced.BeforeDestruction;
begin
  if FCounter.FRefCount <> 0 then
    System.Error(reInvalidPtr);

  if FCounter.WeakRelease = 0 then
    FCounter.Free;
end;

class function TWeakableInterfaced.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  with TWeakableInterfaced(Result) do
  begin
    FCounter := TSharedCounter.Create;
    FCounter.FRefCount := 1;
    FCounter.FWeakCount := 1;
  end;
end;

function TWeakableInterfaced.QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID;
  out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TWeakableInterfaced.GetWeak: IWeakInterface;
var
  w: TWeakInterface;
  r: IInterface;
begin
  FCounter.WeakAdd;
  w := TWeakInterface.Create;
  w.FCounter := FCounter;
  r := Self as IInterface;
  w.FRef := Pointer(r);
  Result := w;
end;

function TWeakableInterfaced.GetRefCount: Integer;
begin
  Result := FCounter.FRefCount
end;

{ TWeakInterface }

destructor TWeakInterface.Destroy;
begin
  if FCounter.WeakRelease = 0 then
    FCounter.Free;
  inherited;
end;

function TWeakInterface.GetRef: IInterface;
var
  RefCnt: Integer;
begin
  RefCnt := FCounter.AddRefLock;
  if RefCnt = 0 then
    Result := nil
  else begin
    Result := IInterface(FRef); // refcount+1
    // Release the implicit refcount
    FCounter.ReleaseRef;
  end;
end;

{ TSharedCounter }

function TSharedCounter.AddRef: Integer;
begin
  Result := InterlockedIncrement(FRefCount);
end;

function TSharedCounter.AddRefLock: Integer;
begin
  while True do
  begin
    Result := FRefCount;
    if Result = 0 then Exit;
{$ifdef fpc}
    if InterlockedCompareExchange(
          FRefCount, Result + 1, Result
        ) = Result then
    begin
      Inc(Result);
      Exit;
    end;
{$else}
    if InterlockedCompareExchange(
          Pointer(FRefCount), Pointer(Result + 1), Pointer(Result)
        ) = Pointer(Result) then
    begin
      Inc(Result);
      Exit;
    end;
{$endif}
  end;
end;

function TSharedCounter.ReleaseRef: Integer;
begin
  Result := InterlockedDecrement(FRefCount);
end;

function TSharedCounter.WeakAdd: Integer;
begin
  Result := InterlockedIncrement(FWeakCount);
end;

function TSharedCounter.WeakRelease: Integer;
begin
  Result := InterlockedDecrement(FWeakCount);
end;

{ TSingleSharedCounter }

function TSingleSharedCounter.AddRef: Integer;
begin
  Inc(FRefCount);
  Result := FRefCount;
end;

function TSingleSharedCounter.AddRefLock: Integer;
begin
  if FRefCount > 0 then
    Inc(FRefCount);
  Result := FRefCount;
end;

function TSingleSharedCounter.ReleaseRef: Integer;
begin
  Dec(FRefCount);
  Result := FRefCount;
end;

function TSingleSharedCounter.WeakAdd: Integer;
begin
  Inc(FWeakCount);
  Result := FWeakCount;
end;

function TSingleSharedCounter.WeakRelease: Integer;
begin
  Dec(FWeakCount);
  Result := FWeakCount;
end;

end.
