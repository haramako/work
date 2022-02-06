using System;
using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;
using ToydeaCabinet;
using MapperSampleUtil;
using System.IO;

namespace ToydeaCabinet
{
	#if false
	class MapperTest
	{
		MapperSample m_;
		Cabinet c_;

		[SetUp]
		public void SetUp()
		{
			//Logger.LogEnabled = true;
			m_ = new MapperSample();
			c_ = new Cabinet();
		}

		[Test]
		public void TestMapper()
		{
			m_.LoadFromCabinet(c_);
			m_.UpdateHp(100);
			m_.UpdateName("hoge");
			m_.UpdateItem(new Item { Id = 1, ItemType = 100 });
			m_.UpdateItem(new Item { Id = 2, ItemType = 200 });
			m_.Commit();

			var dump = (c_.Storage as Cabinet.MemoryStorage).Dump();
			System.IO.File.WriteAllBytes(Path.Combine(Path.GetTempPath(), "mapper.tc"), dump);
			var c2 = new Cabinet(dump);
			var m2 = new MapperSample();
			m2.Connect(c2);

			Assert.AreEqual(100, m2.Hp);
			Assert.AreEqual("hoge", m2.Name);
			Assert.AreEqual(2, m2.Items.Count);
			Assert.AreEqual(100, m2.Items[1].ItemType);
			Assert.AreEqual(200, m2.Items[2].ItemType);
		}
	}
	#endif
}
