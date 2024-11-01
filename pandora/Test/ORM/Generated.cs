// DON'T TOUCH. THIS FILE IS AUTO GENERATED BY codegen.rb
using System;
using System.Collections.Generic;
using System.Linq;

using Pandora;
using Pandora.ORM;
using pb = Google.Protobuf;


namespace Pandora.ORMTest {

public static class Keys
{
}

public partial class Character : Entity
{
    const byte FieldTag_Name = 8;
    const UInt64 DirtyMask_Name = 1UL<<1;
    const UInt64 DirtyBit_Name = ~(1UL<<1);
    const byte FieldTag_Age = 16;
    const UInt64 DirtyMask_Age = 1UL<<2;
    const UInt64 DirtyBit_Age = ~(1UL<<2);
    const byte FieldTag_Weight = 24;
    const UInt64 DirtyMask_Weight = 1UL<<3;
    const UInt64 DirtyBit_Weight = ~(1UL<<3);

    UInt64 _dirty_flag; // Which fields has changed in frozen.

    public override uint ClassId { get { return 1; } }

        string _name;
        string _oldName;
        string _frozenName;
        public string Name
        {
            get
            {
                return _name;
            }
            set
            {
                if (_name == value) return;
                if (_space != null && _space.Frozen && (_dirty_flag & DirtyMask_Name) != 0)
                {
                    _dirty_flag |= DirtyBit_Name;
                    _frozenName = _name;
                }
                _hasChanged = true;
                _name = value;
            }
        }

        int _age;
        int _oldAge;
        int _frozenAge;
        public int Age
        {
            get
            {
                return _age;
            }
            set
            {
                if (_age == value) return;
                if (_space != null && _space.Frozen && (_dirty_flag & DirtyMask_Age) != 0)
                {
                    _dirty_flag |= DirtyBit_Age;
                    _frozenAge = _age;
                }
                _hasChanged = true;
                _age = value;
            }
        }

        int _weight;
        int _oldWeight;
        int _frozenWeight;
        public int Weight
        {
            get
            {
                return _weight;
            }
            set
            {
                if (_weight == value) return;
                if (_space != null && _space.Frozen && (_dirty_flag & DirtyMask_Weight) != 0)
                {
                    _dirty_flag |= DirtyBit_Weight;
                    _frozenWeight = _weight;
                }
                _hasChanged = true;
                _weight = value;
            }
        }


    public override int GetSerializedSize()
    {
        int size = 0;
        if (_oldName != _name)
        {
            size += 1 + pb::CodedOutputStream.ComputeStringSize(_name);
        }
        if (_oldAge != _age)
        {
            size += 1 + pb::CodedOutputStream.ComputeInt32Size(_age);
        }
        if (_oldWeight != _weight)
        {
            size += 1 + pb::CodedOutputStream.ComputeInt32Size(_weight);
        }
        return size;
    }

    public override void WriteTo(pb::CodedOutputStream s)
    {
        if( _oldName != _name)
        {
            s.WriteRawTag(FieldTag_Name);
            s.WriteString(_name);
            _oldName = _name;
        }
        if( _oldAge != _age)
        {
            s.WriteRawTag(FieldTag_Age);
            s.WriteInt32(_age);
            _oldAge = _age;
        }
        if( _oldWeight != _weight)
        {
            s.WriteRawTag(FieldTag_Weight);
            s.WriteInt32(_weight);
            _oldWeight = _weight;
        }
    }

    public override void ReadFrom(pb::CodedInputStream s)
    {
        uint tag;
        while( (tag = s.ReadTag()) != 0)
        {
            switch (tag)
            {
                case FieldTag_Name:
                    _name = s.ReadString();
                    continue;
                case FieldTag_Age:
                    _age = s.ReadInt32();
                    continue;
                case FieldTag_Weight:
                    _weight = s.ReadInt32();
                    continue;
                default:
                    continue;
            }
        }
    }

    public override void BeginFreeze()
    {
        _dirty_flag = 0UL;
    }
    public override void EndFreeze()
    {
        _dirty_flag = 0UL;
    }
}

public partial class Item : Entity
{
    const byte FieldTag_OwnerId = 8;
    const UInt64 DirtyMask_OwnerId = 1UL<<1;
    const UInt64 DirtyBit_OwnerId = ~(1UL<<1);
    const byte FieldTag_Name = 16;
    const UInt64 DirtyMask_Name = 1UL<<2;
    const UInt64 DirtyBit_Name = ~(1UL<<2);

    UInt64 _dirty_flag; // Which fields has changed in frozen.

    public override uint ClassId { get { return 1; } }

        int _ownerid;
        int _oldOwnerId;
        int _frozenOwnerId;
        public int OwnerId
        {
            get
            {
                return _ownerid;
            }
            set
            {
                if (_ownerid == value) return;
                if (_space != null && _space.Frozen && (_dirty_flag & DirtyMask_OwnerId) != 0)
                {
                    _dirty_flag |= DirtyBit_OwnerId;
                    _frozenOwnerId = _ownerid;
                }
                _hasChanged = true;
                _ownerid = value;
            }
        }

        string _name;
        string _oldName;
        string _frozenName;
        public string Name
        {
            get
            {
                return _name;
            }
            set
            {
                if (_name == value) return;
                if (_space != null && _space.Frozen && (_dirty_flag & DirtyMask_Name) != 0)
                {
                    _dirty_flag |= DirtyBit_Name;
                    _frozenName = _name;
                }
                _hasChanged = true;
                _name = value;
            }
        }


    public override int GetSerializedSize()
    {
        int size = 0;
        if (_oldOwnerId != _ownerid)
        {
            size += 1 + pb::CodedOutputStream.ComputeInt32Size(_ownerid);
        }
        if (_oldName != _name)
        {
            size += 1 + pb::CodedOutputStream.ComputeStringSize(_name);
        }
        return size;
    }

    public override void WriteTo(pb::CodedOutputStream s)
    {
        if( _oldOwnerId != _ownerid)
        {
            s.WriteRawTag(FieldTag_OwnerId);
            s.WriteInt32(_ownerid);
            _oldOwnerId = _ownerid;
        }
        if( _oldName != _name)
        {
            s.WriteRawTag(FieldTag_Name);
            s.WriteString(_name);
            _oldName = _name;
        }
    }

    public override void ReadFrom(pb::CodedInputStream s)
    {
        uint tag;
        while( (tag = s.ReadTag()) != 0)
        {
            switch (tag)
            {
                case FieldTag_OwnerId:
                    _ownerid = s.ReadInt32();
                    continue;
                case FieldTag_Name:
                    _name = s.ReadString();
                    continue;
                default:
                    continue;
            }
        }
    }

    public override void BeginFreeze()
    {
        _dirty_flag = 0UL;
    }
    public override void EndFreeze()
    {
        _dirty_flag = 0UL;
    }
}

    


}
