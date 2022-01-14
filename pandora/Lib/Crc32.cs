using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ToydeaCabinet
{
	public static class Crc32
	{
		const int TableLength = 256;
		static uint[] crcTable;

		static void buildCrc32Table()
		{
			if( crcTable != null)
			{
				return;
			}

			crcTable = new uint[256];
			for (uint i = 0; i < 256; i++)
			{
				var x = i;
				for (var j = 0; j < 8; j++)
				{
					x = (uint)((x & 1) == 0 ? x >> 1 : -306674912 ^ x >> 1);
				}
				crcTable[i] = x;
			}
		}

		public static uint Calc(byte[] buf, int start, int len)
		{
			if( buf == null)
			{
				throw new ArgumentException("buf must not be null");
			}

			if( len < 0 || (start + len) > buf.Length)
			{
				throw new ArgumentException($"Invalid argument buflen={buf.Length}, start = {start}, len={len}");
			}

			buildCrc32Table();

			uint num = uint.MaxValue;
			for (var i = 0; i < len; i++)
			{
				num = crcTable[(num ^ buf[start + i]) & 255] ^ num >> 8;
			}

			return (uint)(num ^ -1);
		}
	}
}
