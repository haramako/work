using System;
using NUnit.Framework;
using System.Linq;
using System.IO;

namespace ToydeaCabinet
{
	class CabinetRecoveryTest
	{
		Cabinet c_;
		Cabinet.MemoryStorage storage_;

		[SetUp]
		public void SetUp()
		{
			c_ = new Cabinet();
			storage_ = (Cabinet.MemoryStorage)c_.Storage;
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
				if (i % 2 == 0)
				{
					Console.WriteLine($"commit {i}");
					c.Commit();
				}
			}

			c.Commit();
		}

		[Test]
		public void TestRecoveryFromInvalidByte()
		{
			iterateAccess(c_, 220, 100);

			var bin = storage_.Dump();

			// ランダムに1byteずつ書き換える
			var rand = new System.Random(3456);
			for (var pos = 0; pos < bin.Length; pos ++)
			{
				var backup = bin[pos];
				//Console.WriteLine($"pos {pos}");

				// 1byteだけ書き換える
				while (bin[pos] == backup)
				{
					bin[pos] = (byte)rand.Next(256);
				}

				var c2 = new Cabinet(bin);
				Assert.IsTrue(c2.IsRecovered);
				var ri = c2.RecoveryInfo;
				Console.WriteLine($"pos {ri.LastValidCommitPosition}, commit={ri.CommitId}, mes={ri.Message}");

				bin[pos] = backup; // 次のためにもとにもどす
			}
		}

		[Test]
		public void TestRecoveryFromInvalidLength()
		{
			iterateAccess(c_, 220, 100);

			var bin = storage_.Dump();

			// ランダム１バイトずつ切る
			var rand = new System.Random(3456);
			for (var pos = 0; pos < bin.Length - 1; pos++)
			{
				var cutted = bin.Take(pos).ToArray();
				var c2 = new Cabinet(cutted);
				if (c2.IsRecovered)
				{
					var ri = c2.RecoveryInfo;
					Console.WriteLine($"pos {ri.LastValidCommitPosition}, commit={ri.CommitId}, mes={ri.Message}");
				}
				else
				{
					// たまたまいいところで切れた場合、読み込みは成功するけど、、、
					Assert.AreNotEqual(c_.CommitId, c2.CommitId);
				}
			}
		}

		[Test]
		public void TestRecoveryFileStorageFromInvalidByte()
		{
			var path = Path.Combine(Path.GetTempPath(), "TestRecoveryFileStorageFromInvalidByte.tc");
			File.Delete(path);
			var storage = new Cabinet.FileStorage(path);
			c_ = new Cabinet(storage);

			iterateAccess(c_, 10, 10);

			storage.Dispose();

			var bin = File.ReadAllBytes(path);

			// ランダムに1byteずつ書き換える
			var rand = new System.Random(3456);
			Console.WriteLine(bin.Length);
			for (var pos = 0; pos < bin.Length - 1; pos += 1)
			{
				var backup = bin[pos];

				// 1byteだけ書き換える
				while (bin[pos] == backup)
				{
					bin[pos] = (byte)rand.Next(256);
				}

				File.WriteAllBytes(path, bin);

				var storage2 = new Cabinet.FileStorage(path);
				var c2 = new Cabinet(storage2);
				Assert.IsTrue(c2.IsRecovered);
				var ri = c2.RecoveryInfo;

				storage2.Dispose();

				bin[pos] = backup; // 次のためにもとにもどす
			}
		}

		[Test]
		public void TestRecoveryFileStorageFromInvalidLength()
		{
			var path = Path.Combine(Path.GetTempPath(), "TestRecoveryFileStorageFromInvalidLength.tc");
			File.Delete(path);
			var storage = new Cabinet.FileStorage(path);
			c_ = new Cabinet(storage);

			iterateAccess(c_, 10, 10);

			storage.Dispose();

			var bin = File.ReadAllBytes(path);

			// ランダムに1byteずつ書き換える
			var rand = new System.Random(3456);
			Console.WriteLine(bin.Length);
			for (var pos = 1; pos < bin.Length - 1; pos += 1)
			{
				var newBin = bin.Take(pos).ToArray();

				File.WriteAllBytes(path, newBin);

				var storage2 = new Cabinet.FileStorage(path);
				var c2 = new Cabinet(storage2);
				if (c2.IsRecovered)
				{
					var ri = c2.RecoveryInfo;
					Console.WriteLine($"pos {ri.LastValidCommitPosition}, commit={ri.CommitId}, mes={ri.Message}");
				}
				else
				{
					// たまたまいいところで切れた場合、読み込みは成功するけど、、、
					Assert.AreNotEqual(c_.CommitId, c2.CommitId);
				}

				storage2.Dispose();
			}
		}

	}
}
