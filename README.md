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

## 用法

  1. 如果你的对象从TInterfacedObject继承，那么改为从TWeakableInterfaced继承
  2. 在需要互相引用之处，使用 IWeakInterface 替代实际的接口
  3. 在需要实际的接口实例之处，使用 IWeakInterface 的 Ref属性获取实例（需要转型到实际的接口类型）

