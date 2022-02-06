using System;
using ToydeaCabinet;

namespace MapperSampleUtil
{
	public abstract class Message
	{
		public abstract byte[] Dump();
		public abstract void MergeFrom(byte[] data);
	}

	// テスト用に手で実装している
	// 実際には、ProtocolBufferのオブジェクトを利用する
	public class Item : Message
	{
		public int Id;
		public int ItemType;

		public override byte[] Dump()
		{
			var w = new Cabinet.Writer(null, null);
			var size = w.sizeInt(Id) + w.sizeInt(ItemType);
			var buf = new byte[size];
			var w2 = new Cabinet.Writer(null, buf);
			w2.writeInt(Id);
			w2.writeInt(ItemType);
			return buf;
		}

		public override void MergeFrom(byte[] data)
		{
			var r = new Cabinet.Reader(null, data);
			Id = r.readInt();
			ItemType = r.readInt();
		}
	}
}
