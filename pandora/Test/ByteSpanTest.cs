using System;
using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;

namespace ToydeaCabinet
{
	class ByteSpanTest
	{
		[TestCase("hoge", "hoge", true)]
		[TestCase("hoge", "fuga", false)]
		public void TestSpan(string sa, string sb, bool equal)
		{
			var a = new ByteSpan(sa);
			var b = new ByteSpan(sb);
			Assert.AreEqual(a.Equals(b), equal);
		}

		[TestCase(0, 3, true)]
		[TestCase(0, 0, false)]
		[TestCase(0, 2, false)]
		[TestCase(5, 3, true)]
		[TestCase(5, 4, false)]
		public void TestConstructor(int start, int len, bool equal)
		{
			byte[] src = new byte[] { 0, 1, 2, 3, 4, 0, 1, 2, 0, 1, 3 };
			var a = new ByteSpan(src, 0, 3);
			var b = new ByteSpan(src, start, len);
			Assert.AreEqual(a.Equals(b), equal);

			ByteSpan a2 = a;
			Assert.AreEqual(a.Equals(a2), true);

			Assert.AreEqual(a.GetHashCode() == b.GetHashCode(), equal);
		}

		[Test]
		public void TestDict()
		{
			var dict = new Dictionary<ByteSpan, int>();
			dict[new ByteSpan("hoge")] = 1;
			Assert.AreEqual(dict[new ByteSpan("hoge")], 1);

			Assert.IsTrue(dict.ContainsKey(new ByteSpan("hoge")));
			Assert.IsFalse(dict.ContainsKey(new ByteSpan("fuga")));
		}

		[Test]
		public void TestSharedIsNotShared()
		{
			byte[] src = new byte[] { 0, 1, 2, 3 };
			var a = new ByteSpan(src, 0, 3, frozen: true);
			Assert.IsTrue(a.IsShared);

			var b = new ByteSpan(src, 1, 3, frozen: true);
			Assert.IsTrue(b.IsShared);
		}

		[Test]
		public void TestFrozenIsNotShared()
		{
			var a = new ByteSpan(new byte[] { 1 }, frozen: true);
			Assert.IsFalse(a.IsShared);
		}

		[Test]
		public void TestNotFrozenIsShared()
		{
			var a = new ByteSpan(new byte[] { 1 }, frozen: false);
			Assert.IsTrue(a.IsShared);
		}

		[Test]
		public void TestAllBytesIsNotShared()
		{
			var a = new ByteSpan(new byte[] { 1 }, 0, 1, frozen: true);
			Assert.IsFalse(a.IsShared);
		}

		[Test]
		public void TestEmptyIsNotShared()
		{
			var a = new ByteSpan(new byte[] { 1 }, 0, 0);
			Assert.IsFalse(a.IsShared);

			a = new ByteSpan(new byte[] { 1 }, 1, 0);
			Assert.IsFalse(a.IsShared);
		}

		[Test]
		public void TestEmptyIsFrozen()
		{
			var a = new ByteSpan(new byte[] { 1 }, 0, 0, frozen: false);
			Assert.IsTrue(a.IsFrozen);

			a = new ByteSpan(new byte[] { 1 }, 1, 0, frozen: false);
			Assert.IsTrue(a.IsFrozen);

			a = new ByteSpan();
			Assert.IsTrue(a.IsFrozen);
		}

		[Test]
		public void TestInvalidRangeThrowException()
		{
			var src = new byte[] { 1, 2 };
			Assert.Throws<Exception>(() => { new ByteSpan(src, 0, 3); });
			Assert.Throws<Exception>(() => { new ByteSpan(src, -1, 1); });
			Assert.Throws<Exception>(() => { new ByteSpan(src, 0, -1); });
			Assert.Throws<Exception>(() => { new ByteSpan(null, 0, 1); });

			var nullSpan = new ByteSpan(null, 0, 0);
		}

		[Test]
		public void TestImplicitConvertFromByteArray()
		{
			Assert.AreEqual(new ByteSpan(new byte[] { 1, 2, 3 }), (ByteSpan)new byte[] { 1, 2, 3 });
		}

		[Test]
		public void TestImplicitConvertFromString()
		{
			Assert.AreEqual(new ByteSpan("hoge"), (ByteSpan)"hoge");
		}
	}
}
