using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ToydeaCabinet;

using Message = MapperSampleUtil.Message;

public abstract class MapperBase
{
	protected Cabinet c_;

	public Cabinet Cabinet => c_;

	public void Connect(Cabinet c)
	{
		c_ = c;
		LoadFromCabinet(c);
	}

	public void Commit()
	{
		c_.Commit();
	}

	public abstract void LoadFromCabinet(Cabinet c);

	public static class Serializer
	{
		static Cabinet.Writer w = new Cabinet.Writer(null, new byte[1024 * 64]);

		// Serialize

		static public ByteSpan Serialize(string val)
		{
			return new ByteSpan(val);
		}

		static public ByteSpan Serialize(bool val)
		{
			w.Reset();
			w.writeInt(val ? 1 : 0);
			return new ByteSpan(w.Buf, 0, w.Position).Unshare();
		}

		static public ByteSpan Serialize(int val)
		{
			w.Reset();
			w.writeInt(val);
			return new ByteSpan(w.Buf, 0, w.Position).Unshare();
		}

		static public ByteSpan Serialize<T>(T val) where T : Message
		{
			return val.Dump();
		}

		// Deserialize

		static public int DeserializeInt32(ByteSpan span)
		{
			var r = new Cabinet.Reader(null, span.RawData, span.Start);
			return r.readInt();
		}

		static public String DeserializeString(ByteSpan span)
		{
			return Encoding.UTF8.GetString(span.RawData, span.Start, span.Length);
		}

		static public T DeserializeMessage<T>(ByteSpan span) where T: Message, new()
		{
			var t = new T();
			t.MergeFrom(span.ToBytes());
			return t;
		}

	}
}

