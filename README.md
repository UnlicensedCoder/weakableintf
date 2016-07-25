# Weak reference to interface

## 说明

  这个单元主要解决接口循环引用导致不能释放的问题。比如有两个接口：
```
  IIntfA = interface
	property B: IIntfB;
  end;
  
  IIntfB = interface
	property A: IIntfA;
  end;
```

  假如有两个IIntfA和IIntfB的实例A和B，使用代码互相引用，那么它们将无法释放：
```
  procedure proc;
  var
	A: IIntfA;
	B: IIntfB;
  begin
	...
	
	A.B := B;
	B.A := A;
	
	...
  end;
```

  weakableintf.pas提供了一些类，帮助解决循环引用导致引用计数不正常的问题。
  类 TWeakableInterfaced提供了一个功能：把实例转成 IWeakInterface 接口，但不增加自身引用计数。当通过 IWeakInterface.Ref 重新获取原来的实例时，有可能返回nil，因为实例有可能已经释放。
  
## 用法

  1. 如果你的对象从TInterfacedObject继承，那么改为从TWeakableInterfaced继承
  2. 在需要互相引用之处，使用 IWeakInterface 替代实际的接口。这可以通过 IWeakable的Weak获取
  3. 在需要实际的接口实例之处，使用 IWeakInterface 的 Ref属性获取实例（需要转型到实际的接口类型）

## 示例

```
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

```

