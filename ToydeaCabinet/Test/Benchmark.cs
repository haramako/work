using System;
using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;

namespace ToydeaCabinet
{
	class Benchmark
	{
		bool Enabled = true;

		void iterateAccess(Cabinet c, int accessNum, int columnNum, int seed = 1234)
		{
			var kb = new CabinetKeyBuilder();
			var rand = new System.Random(seed);
			for (int i = 0; i < accessNum; i++)
			{
				var n = rand.Next(columnNum);
				var del = rand.Next(3) == 0;
				var key = kb.Clear().Store(4, (ulong)i).Build();
				if (del)
				{
					c.Delete(key);
				}
				else
				{
					c.Put(key, new byte[] { (byte)i });
				}
				if (i % 100 == 0)
				{
					c.Commit();
				}
			}

			c.Commit();
		}

		void fillCabinet(Cabinet c, int num)
		{
			var kb = new CabinetKeyBuilder();
			for (int i = 0; i < num; i++)
			{
				kb.Clear();
				var key = kb.Store(2, (ulong)i).Build();
				c.Put(key, "val" + i);
			}

			c.Commit();
		}

		[SetUp]
		public void SetUp()
		{
			if(!Enabled)
			{
				Assert.Ignore();
			}
		}

		[Test]
		public void TestManyWriting()
		{
			var c = new Cabinet(1024 * 1024 * 64);

			iterateAccess(c, 200000, 10000);
		}


		[Test]
		public void TestPrefixSearch()
		{
			Logger.LogEnabled = false;

			var c = new Cabinet(1024 * 1024 * 64);

			fillCabinet(c, 65536);

			for (int n = 0; n < 4; n++)
			{
				for (int i = 0; i <= 256; i++)
				{
					c.GetPrefixed(new CabinetKeyBuilder().Store(8, (ulong)i).Build()).Count();
				}
			}
		}

	}
}
