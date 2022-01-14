using System;
using NUnit.Framework;

namespace ToydeaCabinet
{
	class CabinetKeyTest
	{
		[Test]
		public void TestCreateFromUInt64()
		{
			Assert.AreEqual(1, new CabinetKey(1, 1).EmbededValue);
			Assert.AreEqual(0xffffffff, new CabinetKey(0xffffffff, 4).EmbededValue);
		}

		[Test]
		public void TestCreateFromString()
		{
			Assert.AreEqual(new CabinetKey(0x6100000000000000, 1), new CabinetKey("a"));
			Assert.AreEqual(new CabinetKey(0x6162630000000000, 3), new CabinetKey("abc"));
		}

		[Test]
		public void TestCompareLongKey()
		{
			// Short and Short
			Assert.AreEqual(0, new CabinetKey("12345678").CompareTo(new CabinetKey("12345678")));

			// Short and Long
			Assert.AreEqual(-1, new CabinetKey("11").CompareTo(new CabinetKey("123456789")));
			Assert.AreEqual(-1, new CabinetKey("12345678").CompareTo(new CabinetKey("123456789")));

			Assert.AreEqual(1, new CabinetKey("13").CompareTo(new CabinetKey("123456789")));
			Assert.AreEqual(1, new CabinetKey("12345679").CompareTo(new CabinetKey("123456789")));

			// Long and Long
			Assert.AreEqual(-1, new CabinetKey("123456789").CompareTo(new CabinetKey("1234567891")));
			Assert.AreEqual(1, new CabinetKey("12345678912").CompareTo(new CabinetKey("1234567891")));

			Assert.AreEqual(-1, new CabinetKey("1234567890").CompareTo(new CabinetKey("1234567891")));
			Assert.AreEqual(0, new CabinetKey("1234567891").CompareTo(new CabinetKey("1234567891")));
			Assert.AreEqual(1, new CabinetKey("1234567892").CompareTo(new CabinetKey("1234567891")));
		}


		CabinetKey v(int len, UInt64 num)
		{
			return new CabinetKey(num, len);
		}

		[Test]
		public void TestStoreNum()
		{
			var k = new CabinetKeyBuilder();
			k.Store(1, 1);
			Assert.AreEqual(v(1, 0x0100000000000000), k.Build());
			k.Store(1, 7);
			Assert.AreEqual(v(2, 0x0107000000000000), k.Build());
			k.Store(4, 1);
			k.Store(2, 1);
			Assert.AreEqual(v(8, 0x0107000000010001), k.Build());
		}

		[Test]
		public void TestIsPrefixOf()
		{
			var k = new CabinetKey("hoge");
			Assert.True(new CabinetKey("").IsPrefixOf(k));
			Assert.True(new CabinetKey("ho").IsPrefixOf(k));
			Assert.True(new CabinetKey("hoge").IsPrefixOf(k));
			Assert.False(new CabinetKey("hol").IsPrefixOf(k));
		}
	}
}
