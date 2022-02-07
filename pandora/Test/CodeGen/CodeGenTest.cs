using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text;
using NUnit.Framework;
using ToydeaCabinet;
using ToydeaCabinet.Indexer;

using Range = ToydeaCabinet.Indexer.Range;

namespace ToydeaCabinet.CodeGenTest
{
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

            //Assert.AreEqual(3, rep.SearchById(Range.Greater(1)).Count());

            Assert.AreEqual("Zenitsu,Tanjiro", names(rep.SearchByAgeWeight(16, Range.Greater(45))));
            Assert.AreEqual("Tanjiro", names(rep.SearchByAgeWeight(16, Range.Greater(46))));
            Assert.AreEqual("Tanjiro", names(rep.SearchByAgeWeight(16, Range.Greater(49))));
            Assert.AreEqual("Tanjiro", names(rep.SearchByAgeWeight(16, Range.GreaterEq(50))));
            Assert.AreEqual("", names(rep.SearchByAgeWeight(16, Range.Greater(50))));

            Assert.AreEqual("", names(rep.SearchByAgeWeight(16, Range.Less(46))));
            Assert.AreEqual("Zenitsu", names(rep.SearchByAgeWeight(16, Range.Less(47))));

            Assert.AreEqual("Nezuko,Zenitsu,Tanjiro", names(rep.SearchByAgeWeight(Range.Between(14, 17))));
        }
    }
}
