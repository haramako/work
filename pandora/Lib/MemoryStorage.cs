using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ToydeaCabinet
{
	public partial class Cabinet
	{
		public sealed class MemoryStorage: IStorage
		{
			Cabinet c_;
			int minSize_;
			int maxSize_;
			byte[] buf_;
			bool hasInitialData_;
			Writer writer_;

			public int BinarySize => writer_.Position;
			public byte[] BinaryBuffer => writer_.Buf;

			public MemoryStorage(int minSize = 1024, int maxSize = 1024 * 1024 * 32, byte[] initialBuf = null)
			{
				minSize_ = minSize;
				maxSize_ = maxSize;
				if( initialBuf == null)
				{
					buf_ = new byte[minSize_];
				}
				else
				{
					if (initialBuf.Length > maxSize)
					{
						throw new ArgumentException("Invalid buffer size");
					}
					else if (initialBuf.Length < minSize_ )
					{
						buf_ = new byte[minSize_];
						Buffer.BlockCopy(initialBuf, 0, buf_, 0, initialBuf.Length);
					}
					else
					{
						buf_ = initialBuf;
					}
					hasInitialData_ = true;
				}
			}

			public void Connect(Cabinet c)
			{
				if( c_ != null)
				{
					throw new InvalidOperationException();
				}
				c_ = c;
				if( hasInitialData_ && buf_.Length != 0)
				{
					var reader = new Reader(c_, buf_);
					if (!reader.ReadHeader())
					{
						c_.recoveryInfo_ = new RecoveryInfo { CommitId = 0, Message = "Invalid file header", LastValidCommitPosition = 0 };
					}
					else
					{
						c_.recoveryInfo_ = reader.ReadWithRecovery(shareAllSpan: true);
					}
				}
				writer_ = new Writer(c_, buf_);
				if (!hasInitialData_)
				{
					writer_.WriteHeader();
				}
			}

			void check()
			{
				if( c_ == null)
				{
					throw new InvalidOperationException("No cabinet connected");
				}
			}

			public void Rebuild()
			{
				var dumpSize = writer_.GetDumpSize(withHeader: true);
				var bufSize = (int)Math.Pow(2, Math.Ceiling(Math.Log(dumpSize * 2, 2)));
				var newSize = buf_.Length;
				if (bufSize > buf_.Length)
				{
					newSize = bufSize;
				}

				buf_ = new byte[newSize];
				writer_ = new Writer(c_, buf_);
				writer_.WriteHeader();
				writer_.Dump();
			}

			public bool CanCommit()
			{
				// コミットできる領域が残っていない場合は、再構築する
				var commitSize = writer_.GetCommitSize(false, true);
				return (writer_.Position + commitSize <= writer_.Buf.Length);
			}

			public void Commit()
			{
				// コミットできる領域が残っていない場合は、再構築する
				if (!CanCommit())
				{
					Rebuild();
					// throw new Exception("Not enough buf size");
				}

				writer_.Commit(dump: false);
			}

			public byte[] Dump()
			{
				c_.Commit();
				var buf = new byte[writer_.Position];
				Buffer.BlockCopy(writer_.Buf, 0, buf, 0, writer_.Position);
				return buf;
			}
		}
	}
}
