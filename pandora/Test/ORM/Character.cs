using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Pandora.ORM;
using pb = Google.Protobuf;

namespace Pandora.ORMTest
{
    public partial class Character : Entity
    {
        const byte FieldTag_Name = 8;
        const UInt64 DirtyMask_Name = 1UL<<1;
        const UInt64 DirtyBit_Name = ~(1UL<<1);
        UInt64 _dirty_flag; // Which fields has changed in frozen.

        public override uint ClassId { get { return 1; } }


        string _name;
        string _old_name;
        string _frozen_name;
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
                    _frozen_name = _name;
                }
                _hasChanged = true;
                _name = value;
            }
        }

        public override int GetSerializedSize()
        {
            int size = 0;
            if (_old_name != _name)
            {
                size += 1 + pb::CodedOutputStream.ComputeStringSize(_name);
            }
            return size;
        }

        public override void WriteTo(pb::CodedOutputStream s)
        {
            if( _old_name != _name)
            {
                s.WriteRawTag(FieldTag_Name);
                s.WriteString(_name);
                _old_name = _name;
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
                        Name = s.ReadString();
                        continue;
                    default:
                        continue;
                }
            }
        }
        public override Entity Clone()
        {
            return null;
        }

        public override Entity DeepClone()
        {
            return null;
        }

        // internal
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
