# Pandora ORM

- オブジェクトのシリアライズを自分で実装
- 差分保存のメカニズム
- スレッドセーフは実装しない


```
namespace ToydeaCabinet.CodeGenTest;

entity Character {
  string Name = 1;
  int Age = 2;
  int Weight = 3;
  Item[] Items = 4;
  Position Pos = 5;
}

entity Item {
  string Name = 1;
}

value Position {
  int X = 1;
  int Y = 2;
}
```

```

class ObjectSpace {
    ObjectSpace(Type rootObjectType );
    ObjectSpace();
    PandoraObject RootObject;
    void Create<T>();
    IEnumerable<PandoraObject> GetObjects();

    bool Frozen { get; private set; }
    void BeginFreeze();
    void EndFreeze();

    // internal
    void ReadDiffFrom(CodeStream s);
    PandoraObject ReadObject(CodeStream s);
}

abstract class PandoraObject {
    virtual int GetSerializedSize();
    virtual int GetSerializedDiffSize();
    virtual void WriteTo(CodeStream s);
    virtual void WriteDiffTo(CodeStream s);
    virtual void ReadFrom(CodeStream s);
    virtual void ReadDiffFrom(CodeStream s);
    virtual PandoraObject Clone();
    virtual PandoraObject DeepClone();

    // internal
    virtual void Freeze(); // dirty管理を始める
    virtual void Unfreeze(); // dirty管理を終わる
}

class Character : PandoraObject {
  const int DirtyMask_Name = ?;
  const int DirtyFlag_Name = ?;
  ...

  ObjectSpace _space;
  UInt64 _dirty_flag; // Which fields has changed in frozen.

  int Id { get; private set; }
  
  string _name;
  string _old_name;
  string _frozen_name;
  string Name {
    get; 
    set { 
      if( _name == value ) return;
      if( _space.Frozen && _dirty_flag & DirtyMask_Name != 0 ){
        _frozen_flag |= DirtyBit_Name;
        _fronzen_name = _name;
      }
      _name = value;
  }}
}
```
