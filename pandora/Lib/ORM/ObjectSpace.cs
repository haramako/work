using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Google.Protobuf;

namespace Pandora.ORM
{

    public abstract class Entity
    {
        public uint Id { get; internal set; }
        protected bool _hasChanged;
        protected bool _isCreated;
        public bool HasChanged { get { return _hasChanged; } }
        public bool IsCreated { get { return _isCreated; } }
        public abstract uint ClassId { get; }

        public void SetCreateFlag()
        {
            _hasChanged = true;
            _isCreated = true;
        }
        public void ClearCreated()
        {
            _isCreated = false;
        }
        public void ClearChanged()
        {
            _hasChanged = false;
        }

        public abstract int GetSerializedSize();
        public abstract void WriteTo(CodedOutputStream s);
        public abstract void ReadFrom(CodedInputStream s);
        //public abstract Entity Clone();
        //public abstract Entity DeepClone();

        // internal
        public ObjectSpace _space;
        public abstract void BeginFreeze(); // dirty管理を始める
        public abstract void EndFreeze(); // dirty管理を終わる
    }

    public class ObjectSpaceDesc
    {
        public Dictionary<UInt32, Type> ClassIdDict;
    }

    public partial class ObjectSpace
    {
        ObjectSpaceDesc desc;
        Dictionary<uint, Entity> entities = new Dictionary<uint, Entity>();
        uint nextEntityId;

        public ObjectSpace(ObjectSpaceDesc _desc)
        {
            desc = _desc;
            nextEntityId = 1;
        }

        public Entity RootEntity { get; private set; }
        public T Create<T>(bool isRoot = false) where T:Entity, new()
        {
            var entity = new T();
            register(entity, isRoot, true);
            return entity;
        }

        public T GetEntity<T>(uint id) where T: Entity
        {
            return (T)entities[id];
        }


        public Entity CreateEntityFromClassId(UInt32 classId, UInt32 id, bool isRoot)
        {
            var type = desc.ClassIdDict[classId];
            var entity = (Entity)Activator.CreateInstance(type);
            entity.Id = id;
            register(entity, isRoot, true);
            return entity;
        }

        public void Register(Entity entity, bool isRoot)
        {
            register(entity, isRoot, true);
        }

        void register(Entity entity, bool isRoot, bool created)
        {
            if (entity._space != null)
            {
                throw new InvalidOperationException();
            }
            entity._space = this;
            entity.Id = nextEntityId++;
            if (created) { entity.SetCreateFlag(); }
            entities[entity.Id] = entity;
        }

        public IEnumerable<Entity> GetEntities()
        {
            return entities.Values;
        }

        public bool Frozen { get; private set; }

        public void BeginFreeze()
        {
            if( Frozen)
            {
                throw new InvalidOperationException();
            }
            foreach( var e in GetEntities())
            {
                e.BeginFreeze();
            }
            Frozen = true;
        }

        public void EndFreeze()
        {
            if (!Frozen)
            {
                throw new InvalidOperationException();
            }
            foreach (var e in GetEntities())
            {
                e.EndFreeze();
            }
            Frozen = false;
        }

        public bool LogEnabled;

        [Conditional("DEBUG")]
        public void log(string format, params object[] args)
        {
            if( LogEnabled)
            {
                Console.WriteLine(format, args);
            }
        }

        // internal
        public void WriteTo(CodedOutputStream s)
        {
            foreach (var e in GetEntities())
            {
                if (e.IsCreated)
                {
                    log("Create {0} {1}", e.ClassId, e.Id);
                    s.WriteUInt32((e.Id << 1) | 1);
                    s.WriteUInt32(e.ClassId);
                    e.ClearCreated();
                }
            }

            foreach (var e in GetEntities())
            { 
                if ( e.HasChanged)
                {
                    log("Write {0}", e.Id);
                    s.WriteUInt32((e.Id << 1) | 0);
                    s.WriteUInt32((uint)e.GetSerializedSize());
                    e.WriteTo(s);
                    e.ClearChanged();
                }
            }
            s.Flush();
        }

        public void ReadFrom(CodedInputStream s)
        {
            while (!s.IsAtEnd)
            {
                var n = s.ReadUInt32();
                var id = n >> 1;
                if ((n & 1) == 1)
                {
                    var classId = s.ReadUInt32();
                    log("Create id={1}, classId={0}", classId, id);
                    CreateEntityFromClassId(classId, id, false);
                }
                else
                {
                    var size = s.ReadInt32();
                    log("Read id={0}, size={1}", id, size);

                    var oldLimit = s.PushLimit(size);
                    try
                    {
                        entities[id].ReadFrom(s);
                    }
                    finally
                    {
                        s.PopLimit(oldLimit);
                    }
                }
            }
        }
    }
}
