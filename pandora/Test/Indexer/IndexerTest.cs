using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text;
using NUnit.Framework;
using ToydeaCabinet;

namespace ToydeaCabinet.Indexer
{
#if false
    [Serializable]
    public class Character
    {
        public int Id { get; set; }
        public int Age { get; set; }
        public int Weight { get; set; }
        public string Name { get; set; }

        public byte[] Serialize()
        {
            return Encoding.UTF8.GetBytes(JsonSerializer.Serialize(this));
        }

        public static Character Deserialize(ByteSpan data)
        {
            return JsonSerializer.Deserialize<Character>(data.ToBytes());
        }
    }

    [Serializable]
    public class Item
    {
        public int Id;

        public byte[] Serialize()
        {
            return Encoding.UTF8.GetBytes(JsonSerializer.Serialize(this));
        }
    }
#endif

#if false
    public partial class Characters
    {
        const byte TableKey = 1;
        const byte AgeWeightKey = 2;

        CabinetKeyBuilder kb = new CabinetKeyBuilder();
        Cabinet c;
        public Characters(Cabinet _c)
        {
            c = _c;
        }

        public void Save(Character v)
        {
            {
                var key = kb.Cleared().Store(TableKey).Store(v.Id).Build();
                c.Put(key, v.Serialize());
            }
            {
                var key = kb.Cleared().Store(AgeWeightKey).Store(v.Age).Store(v.Weight).Store(v.Id).Build();
                c.Put(key, new ByteSpan());
            }
        }

        public Character Find(int k)
        {
            var key = kb.Cleared().Store(TableKey).Store(k).Build();
            var data = c.Get(key);
            if (data.IsEmpty)
            {
                return null;
            }
            else
            {
                return Character.Deserialize(data);
            }
        }

        public IEnumerable<Character> SearchById(Range<int> id)
        {
            var start = kb.Cleared().Store(TableKey).Store(id.Start).Build();
            var end = kb.Cleared().Store(TableKey).Store(id.End).Build();
            var found = c.GetRange(start, end);
            return found.Select(kv => Character.Deserialize(kv.Data));
        }

        public IEnumerable<Character> SearchByAgeWeidht(Range<int> age)
        {
            var start = kb.Cleared().Store(AgeWeightKey).Store(age.Start).Build();
            var end = kb.Cleared().Store(AgeWeightKey).Store(age.End).Build();
            var found = c.GetRange(start, end);
            byte[] buf = new byte[16];
            return found.Select(kv =>
            {
                kv.Key.WriteTo(buf, 0);
                var id = MyBitConverter.Reverse(BitConverter.ToInt32(buf, 9));
                return Find(id);
            });
        }

        public IEnumerable<Character> SearchByAgeWeidht(int age, Range<int> weight)
        {
            var start = kb.Cleared().Store(AgeWeightKey).Store(age).Store(weight.Start).Build();
            var end = kb.Cleared().Store(AgeWeightKey).Store(age).Store(weight.End).Build();
            var found = c.GetRange(start, end);
            byte[] buf = new byte[16];
            return found.Select(kv =>
            {
                kv.Key.WriteTo(buf, 0);
                var id = MyBitConverter.Reverse(BitConverter.ToInt32(buf, 9));
                return Find(id);
            });
        }
    }

    class IndexerTest
    {
        Cabinet c;

		[SetUp]
		public void SetUp()
		{
            c = new Cabinet();
        }


        static string names(IEnumerable<Character> cs)
        {
            return string.Join(',', cs.Select(c => c.Name).ToArray());
        }

        [Test]
		public void TestDatabase()
        {
            var rep = new Characters(c);
            rep.Save(new Character() { Id = 1, Name = "Tanjiro", Age = 16, Weight = 50 });
            rep.Save(new Character() { Id = 2, Name = "Nezuko", Age = 14, Weight = 40 });
            rep.Save(new Character() { Id = 3, Name = "Giyuu", Age = 20, Weight = 58 });
            rep.Save(new Character() { Id = 4, Name = "Zenitsu", Age = 16, Weight = 46 });

            Assert.AreEqual("Tanjiro", rep.Find(1).Name);

            Assert.AreEqual(3, rep.SearchById(Range.Greater(1)).Count());

            Assert.AreEqual("Zenitsu,Tanjiro", names(rep.SearchByAgeWeidht(16, Range.Greater(45))));
            Assert.AreEqual("Tanjiro", names(rep.SearchByAgeWeidht(16, Range.Greater(46))));
            Assert.AreEqual("Tanjiro", names(rep.SearchByAgeWeidht(16, Range.Greater(49))));
            Assert.AreEqual("Tanjiro", names(rep.SearchByAgeWeidht(16, Range.GreaterEq(50))));
            Assert.AreEqual("", names(rep.SearchByAgeWeidht(16, Range.Greater(50))));

            Assert.AreEqual("", names(rep.SearchByAgeWeidht(16, Range.Less(46))));
            Assert.AreEqual("Zenitsu", names(rep.SearchByAgeWeidht(16, Range.Less(47))));

            Assert.AreEqual("Nezuko,Zenitsu,Tanjiro", names(rep.SearchByAgeWeidht(Range.Between(14,17))));
        }

        static byte[] b(string s)
        {
            return Encoding.UTF8.GetBytes(s);
        }

        [Test]
        public void TestRange()
        {
            var kb = new CabinetKeyBuilder();
            c.Put(kb.Cleared().Store((byte)1).Build(), "1");
            c.Put(kb.Cleared().Store((byte)2).Build(), "2");

            Assert.AreEqual(c.Get(kb.Cleared().Store((byte)1).Build()).ToBytes(), "1");
        }
    }
#endif
}

