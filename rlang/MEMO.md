# RLang

## 文法

```
func hoge(i:int){
    print(i+1)
}

var i:int = 0
```

## アセンブラ

```
define i8 @add(i8 %1, i8 %2)
hoge:
%3 = add i8 %1,%2
%4 = call %r1(i8 %3, i8 %1)
ret i8 %4
```

- Label
- Ret
- Load,Store
- Add,Sub,Mul,Div,Mod
- And,Or,Xor
- Not
- Call
- Br,Jump

enum Code {
    Label(Symbol),
    BinOp(BinOp, Type, Reg, Reg, Reg),
    UnaryOp(UnaryOp, Type, Reg, Reg),
    Ret(Type,Reg)
    Call(Func, Vec<(Type,Reg)>)
}
