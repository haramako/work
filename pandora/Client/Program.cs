﻿﻿﻿﻿﻿﻿using System;
using CommandLine;
using System.IO;
using System.Linq;
using System.Diagnostics;
using System.Collections.Generic;
using ToydeaCabinet;

namespace DfzConsole
{

	public class Options
	{
		[Option('v', "verbose", HelpText = "詳細なログを表示")]
		public bool Verbose { get; set; }

		[Option('q', "quiet", HelpText = "ログを表示しない")]
		public bool Quiet { get; set; }

		[Option("seed", Default = 1234, HelpText = "ランダムシード")]
		public int Seed { get; set; }

	}

	[Verb("bench")]
	public class Bench : Options
	{
		[Option('s', "storage", Default = "m", HelpText = "ストレージ")]
		public string Storage { get; set; }

		[Option("flash", Default = false, HelpText = "ファイルへのFlashを毎回行う")]
		public bool ForceFlash { get; set; }

		[Option("factor", Default = 8, HelpText = "ファイルリビルドの閾値の、初期サイズに対する倍率")]
		public int Factor { get; set; }

		[Option('n', "num", Default = 10000, HelpText = "繰り返し回数")]
		public int Number { get; set; }

		[Option('c', "count", Default = 1000, HelpText = "レコード数")]
		public int RecordCount { get; set; }

		[Option('r', "record-size", Default = 256, HelpText = "レコードの大きさ[byte]")]
		public int RecordSize { get; set; }

		[Option('k', "record-size", Default = 8, HelpText = "キーの大きさ[byte]")]
		public int KeySize { get; set; }

		[Option("commit", Default = 100, HelpText = "何回に一回コミットするか")]
		public int CommitFreq { get; set; }

		[Value(0)]
		public IEnumerable<string> Files { get; set; }
	}

	[Verb("open")]
	public class Open : Options
	{
		[Option('a', "apos", HelpText = "apos")]
		public bool Quiet2 { get; set; }
	}

	class MainClass
	{
		public static bool WaitForKey = true;

		public static void Main(string[] args)
		{

			var parseResult = CommandLine.Parser.Default.ParseArguments<Bench, Open>(args)
							  .MapResult(
								  (Bench opt) => RunBench(opt),
								  (Open opt) => RunOpen(opt),
								  er => 1
							  );
			waitKey();
		}

		/// <summary>
		/// デバッガがアタッチされている場合は、キーの入力を待つ
		///
		/// Windowsの開津環境で、コンソールがすぐに閉じてしまうのの対策として使用している
		/// </summary>
		static void waitKey()
		{
			if (Debugger.IsAttached && WaitForKey)
			{
				Console.ReadKey();
			}
		}

		public static int RunBench(Bench opt)
		{
			ToydeaCabinet.Logger.LogEnabled = false;

			var start = System.DateTime.Now;
			Cabinet.IStorage storage = null;
			if( opt.Storage == "m")
			{
				storage = new Cabinet.MemoryStorage(1024);
			}
			else
			{
				storage = new Cabinet.FileStorage(System.IO.Path.GetTempFileName(), factor: opt.Factor, flashOnCommit: opt.ForceFlash);
			}

			Console.WriteLine("Storage      {0,10}", storage.GetType().Name);
			Console.WriteLine("Force flush  {0,10}", opt.ForceFlash);
			Console.WriteLine("Factor       {0,10}", opt.Factor);
			Console.WriteLine("Repeat       {0,10}", opt.Number);
			Console.WriteLine("DB size      {0,10}", opt.RecordCount);
			Console.WriteLine("Record size  {0,10}", opt.RecordSize);
			Console.WriteLine("Key size  {0,10}", opt.KeySize);
			Console.WriteLine("Commit / Put {0,10}", opt.CommitFreq);
			var rand = new Random(opt.Seed);
			var c = new Cabinet(storage);

			var buf = new byte[opt.RecordSize];
			rand.NextBytes(buf);

			var dot = opt.Number / 50;
			var kb = new CabinetKeyBuilder();
			var keyprefix = new byte[opt.KeySize - 8];
			for (int i = 0; i < opt.Number; i++)
			{
				kb.Clear();
				kb.Store(keyprefix);
				kb.Store(8, (ulong)rand.Next(opt.RecordCount));
				var l = kb.Length;

				c.Put(kb.Build(), buf);
				if( i % opt.CommitFreq == 0)
				{
					c.Commit();
				}
				if( i % dot == 0)
				{
					Console.Write(".");
				}
			}
			Console.WriteLine("Finish");

			var end = System.DateTime.Now;
			var time = (end - start).TotalMilliseconds;

			Console.WriteLine("Time       {0,10}ms", time);
			Console.WriteLine("Key count  {0,10}", c.Count);
			if (opt.Storage == "m")
			{
				var ms = storage as Cabinet.MemoryStorage;
				ms.Rebuild();
				var dump = ms.Dump();
				Console.WriteLine("Dump size  {0,10} KB", dump.Count() / 1024);
			}
			else
			{
				var fs = storage as Cabinet.FileStorage;
				fs.Rebuild();
				Console.WriteLine("Dump size  {0,10} KB", fs.Stream.Length / 1024);
			}

			return 0;
		}

		public static int RunOpen(Open opt)
		{
			Console.WriteLine("v {0}", opt.Verbose);
			return 0;
		}
	}
}
