using System;
using System.Collections.Generic;
using NUnit.Framework;
using System.IO;

namespace ToydeaCabinet
{
	class CloudSyncTest
	{
		Cabinet c_;
		Cabinet.FileStorage storage_;
		CloudSync cs_;
		CloudSync.INetworkAdaptor na_;

		int userId_ = 0;

		static ByteSpan s(string src) => new ByteSpan(src);

		static CabinetKey k(string src) => new CabinetKey(src);

		[SetUp]
		public void SetUp()
		{
			na_ = null;
			if (true)
			{
				na_ = new CloudSync.DummyNetworkAdaptor();
			}

			userId_++;

			Console.WriteLine($"User ID {userId_}");

			CloudSync.DeleteHistory("http://localhost:4567", userId_, na_);

			var file = Path.Combine(Path.GetTempPath(), "cloudsync.tc");
			File.Delete(file);
			storage_ = new Cabinet.FileStorage(file);
			c_ = new Cabinet(storage_);

			cs_ = new CloudSync("http://localhost:4567", userId_, storage_, na_);
			cs_.StartSync();
		}

		[TearDown]
		public void TereDown()
		{
			if (storage_ != null)
			{
				storage_.Dispose();
			}
			if (cs_ != null)
			{
				cs_.Dispose();
			}
		}

		[Test]
		public void TestSync()
		{
			c_.Put(k("hoge"), s("1"));
			c_.Commit();
			cs_.Sync();
			Assert.AreEqual(CloudSync.StatusType.Synchronized, cs_.Status);

			c_.Put(k("fuga"), s("2"));
			c_.Commit();
			cs_.Sync();
			Assert.AreEqual(CloudSync.StatusType.Synchronized, cs_.Status);

			storage_.Rebuild();

			c_.Put(k("fuga"), s("3"));
			c_.Commit();
			c_.Put(k("fuga"), s("4"));
			c_.Commit();
			cs_.Sync();
			Assert.AreEqual(CloudSync.StatusType.Synchronized, cs_.Status);
		}

		[Test]
		public void TestRestartSync()
		{
			c_.Put(k("hoge"), s("1"));
			c_.Commit();
			cs_.Sync();
			Assert.AreEqual(CloudSync.StatusType.Synchronized, cs_.Status);

			cs_.StopSync();
			Assert.AreEqual(CloudSync.StatusType.Disconnected, cs_.Status);

			c_.Put(k("fuga"), s("2"));
			c_.Commit();

			storage_.Dispose();
			cs_.Dispose();

			storage_ = new Cabinet.FileStorage(storage_.Path);
			c_ = new Cabinet(storage_);
			cs_ = new CloudSync("http://localhost:4567", userId_, storage_, na_);
			cs_.StartSync();

			c_.Put(k("fuga"), s("3"));
			c_.Commit();
			cs_.Sync();
			storage_.Rebuild();
			Assert.AreEqual(CloudSync.StatusType.Synchronized, cs_.Status);
		}

	}
}
