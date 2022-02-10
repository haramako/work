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
        CharacterRepository rep;

        [SetUp]
        public void SetUp()
        {
            c = new Cabinet();
            rep = new CharacterRepository(c);

            rep.Save(new Character() { Id = 1, Name = "Tanjiro", Age = 16, Weight = 50 });
            rep.Save(new Character() { Id = 2, Name = "Nezuko", Age = 14, Weight = 40 });
            rep.Save(new Character() { Id = 3, Name = "Giyuu", Age = 20, Weight = 58 });
            rep.Save(new Character() { Id = 4, Name = "Zenitsu", Age = 16, Weight = 46 });
        }


        static string names(IEnumerable<Character> cs)
        {
            return string.Join(',', cs.Select(c => c.Name).ToArray());
        }

        [Test]
        public void TestFind()
        {
            Assert.AreEqual("Tanjiro", rep.Find(1).Name);
        }

        [Test]
        public void TestSearchWithString()
        {
            Assert.AreEqual("Tanjiro,Zenitsu", names(rep.SearchByName(Range.GreaterEq("Tanjiro"))));
            Assert.AreEqual("Giyuu,Nezuko", names(rep.SearchByName(Range.Less("Tanjiro"))));
        }

        [Test]
        public void TestSearchWithMultipleFields()
        {
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
