using System;
using System.Linq;
using System.IO;
using NUnit.Framework;
using System.Text;

namespace ToydeaCabinet
{
	class CabinetTest
	{
		Cabinet c_;
		Cabinet.MemoryStorage storage_;

		[SetUp]
		public void SetUp()
		{
			c_ = new Cabinet();
			storage_ = (Cabinet.MemoryStorage)c_.Storage;
		}

		static ByteSpan s(string src) => new ByteSpan(src);

		static CabinetKey k(string src) => new CabinetKey(src);

		[Test]
		public void TestPut()
		{
			c_.Put("hoge", "1");
			c_.Put("fuga", "2");

			Assert.AreEqual(s("1"), c_.Get("hoge"));

			Assert.AreEqual(s("2"), c_.Get("fuga"));

			Assert.IsTrue(c_.Get("piyo").IsEmpty);
		}

		[Test]
		public void TestCount()
		{
			c_.Put("hoge", "1");
			Assert.AreEqual(1, c_.Count);
			Assert.AreEqual(1, c_.DirtyCount);

			c_.Put("fuga", "2");
			Assert.AreEqual(2, c_.Count);
			Assert.AreEqual(2, c_.DirtyCount);

			c_.Put("hoge", "11");
			Assert.AreEqual(2, c_.Count);
			Assert.AreEqual(2, c_.DirtyCount);

			c_.Put("fuga", "22");
			Assert.AreEqual(2, c_.Count);
			Assert.AreEqual(2, c_.DirtyCount);
		}

		[Test]
		public void TestDelete()
		{
			c_.Put("hoge", "1");
			c_.Put("fuga", "2");

			Assert.IsTrue(c_.Delete("hoge"));
			Assert.IsTrue(c_.Get("hoge").IsEmpty);
			Assert.IsFalse(c_.Exist("hoge"));

			Assert.IsFalse(c_.Delete("hoge"));
		}

		[Test]
		public void TestDump()
		{
			c_.Put("hoge", "1");
			c_.Put("fuga", "2");
			Assert.AreEqual(2, c_.DirtyCount);

			var span = storage_.Dump();
			Assert.AreEqual(0, c_.DirtyCount);

			c_.Delete("hoge");
			Assert.AreEqual(1, c_.DirtyCount);
			Assert.AreEqual(1, c_.Count);

			span = storage_.Dump();
			Assert.AreEqual(0, c_.DirtyCount);
			Assert.AreEqual(1, c_.Count);
		}

		[Test]
		public void TestCommit()
		{
			c_.Put("hoge", "1");

			c_.Commit();
			Assert.AreEqual(0, c_.DirtyCount);

			c_.Put("fuga", "2");
			c_.Commit();

			c_.Delete("hoge");
			c_.Commit();
		}

		public static bool compareCabinet(Cabinet c1, Cabinet c2)
		{
			if( c1.Keys.Count() != c2.Keys.Count())
			{
				Console.WriteLine("key count {0} {1}", c1.Keys.Count(), c2.Keys.Count());
				//return false;
			}
			foreach (var key in c1.Keys)
			{
				if (!c1.Get(key).Equals(c2.Get(key)))
				{
					Console.WriteLine(key + " " + c1.Get(key) + " " + c2.Get(key));
					return false;
				}
			}
			return true;
		}

		[Test]
		public void TestRead()
		{
			c_.Put("hoge", "1");
			c_.Commit();

			var c2 = new Cabinet(storage_.Dump());
			Assert.IsTrue(compareCabinet(c_, c2));

			c_.Put("fuga", "2");
			c_.Commit();

			c2 = new Cabinet(storage_.Dump());
			Assert.IsTrue(compareCabinet(c_, c2));

			c_.Delete("hoge");
			c_.Commit();

			c2 = new Cabinet(storage_.Dump());
			Assert.IsTrue(compareCabinet(c_, c2));
		}

		[Test]
		public void TestRestruct()
		{
			c_ = new Cabinet(44);
			storage_ = (Cabinet.MemoryStorage)c_.Storage;
			c_.Put("hoge1", "1");
			c_.Put("hoge2", "2");
			c_.Put("hoge3", "3");
			Assert.IsTrue(storage_.CanCommit());
			c_.Commit();

			c_.Put("hoge1", "1");
			c_.Put("hoge2", "2");
			c_.Put("hoge3", "3");
			Assert.IsFalse(storage_.CanCommit());
			c_.Commit();

			storage_.Rebuild();
			Assert.IsTrue(storage_.CanCommit());
			c_.Commit();
		}

		[Test]
		public void TestGetPrefixed()
		{
			c_.Put("hoge1", "1");
			c_.Put("hoge2", "2");
			c_.Put("hoge3", "3");
			c_.Put("hoge", "4");
			c_.Put("fuga", "5");
			c_.Put("ho", "6");

			Assert.AreEqual(4, c_.GetPrefixed(new CabinetKey("hoge")).Count());
			Assert.AreEqual(5, c_.GetPrefixed(new CabinetKey("ho")).Count());
			Assert.AreEqual(6, c_.GetPrefixed(new CabinetKey("")).Count());
		}

		[Test]
		public void TestReadChunks()
		{
			c_.Put("hoge1", "1");
			c_.Commit();
			c_.Put("hoge2", "2");
			c_.Put("hoge3", "3");
			c_.Commit();

			var chunks = Cabinet.SplitChunks(storage_.Dump());
			Assert.AreEqual(2, chunks.Count());
		}

		void iterateAccess(Cabinet c, int accessNum, int columnNum, int seed = 1234)
		{
			var rand = new System.Random(seed);
			for (int i = 0; i < accessNum; i++)
			{
				var n = rand.Next(columnNum);
				var del = rand.Next(3) == 0;
				var key = "test" + n;
				if (del)
				{
					c.Delete(key);
				}
				else
				{
					c.Put(key, "val" + i);
				}
				if (i % 100 == 0)
				{
					Console.WriteLine($"commit {i}");
					c.Commit();
				}
			}

			c.Commit();
		}

		[Test]
		public void TestManyWriting()
		{
			iterateAccess(c_, 10000, 10000);

			var c2 = new Cabinet(storage_.Dump());
			Assert.IsTrue(compareCabinet(c_, c2));

			var c3 = new Cabinet(1024 * 1024 * 128);
			iterateAccess(c3, 10000, 10000);
			Assert.IsTrue(compareCabinet(c_, c3));
		}

		[Test]
		public void TestLongKey()
		{
			c_.Put("shortkey", "1");
			c_.Put("longkey123456789", "2");

			Assert.AreEqual(s("2"), c_.Get("longkey123456789"));

			var c2 = new Cabinet(storage_.Dump());
			Assert.IsTrue(compareCabinet(c_, c2));
		}

		[Test]
		public void TestFileStorage()
		{
			var file = Path.Combine(Path.GetTempPath(), "TestFileStorage.tc");
			File.Delete(file);
			var storage = new Cabinet.FileStorage(file, factor: 8);
			c_ = new Cabinet(storage);

			iterateAccess(c_, 10000, 10000);

			storage.Rebuild();
			storage.Dispose();

			storage = new Cabinet.FileStorage(file, factor: 8);
			c_ = new Cabinet(storage);

			iterateAccess(c_, 1000, 10000);

			storage.Dispose();

			var c3 = new Cabinet(1024 * 1024 * 128);
			iterateAccess(c3, 10000, 10000);
			iterateAccess(c3, 1000, 10000);
			Assert.IsTrue(compareCabinet(c_, c3));

			var buf = File.ReadAllBytes(file);
			Console.WriteLine("buf size {0}", buf.Length);
			var c2 = new Cabinet(buf);
			Assert.IsTrue(compareCabinet(c_, c2));
		}

		[Test]
		public void TestFileStorageOnCommit()
		{
			var file = Path.Combine(Path.GetTempPath(), "TestFileStorageOnCommit.tc");
			File.Delete(file);
			var storage = new Cabinet.FileStorage(file, factor: 8);
			c_ = new Cabinet(storage);
			storage.OnCommit = (n, buf, len) =>
			{
				Console.WriteLine($"OnCommit {len}");
			};

			iterateAccess(c_, 10000, 10000);

			storage.Dispose();

		}
	}
}
