using System;
using System.Diagnostics;

namespace ToydeaCabinet
{
	/// <summary>
	/// ログ出力用のユーティリティ
	///
	/// ToydeaCabinet.Logger.LogEnable = true を設定することで、ログが有効になる
	/// </summary>
	public static class Logger
	{
		public static bool LogEnabled = true;
		public static Action<string> LogFunc;

		[Conditional("DEBUG")]
		public static void Log(string format, params object[] args)
		{
			if (LogEnabled)
			{
				if (LogFunc != null)
				{
					LogFunc(string.Format(format, args));
				}
				else
				{
					Console.WriteLine(string.Format(format, args));
				}
			}
		}
	}
}
