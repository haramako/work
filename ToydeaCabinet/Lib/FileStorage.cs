using System;
using System.IO;

namespace ToydeaCabinet
{
	public partial class Cabinet
	{
		public sealed class FileStorage: IStorage, IDisposable
		{
			Cabinet c_;
			int minSize_;
			int rebuildThreshold_;
			float factor_;
			bool flashOnCommit_;

			byte[] buf_;
			Writer writer_;

			FileStream stream_;

			string path_;

			bool disposed_;

			public string Path => path_;
			public string PrevFilePath => path_ + ".prev";
			public Stream Stream => stream_;

			public Action<int, byte[], int> OnCommit;
			public Action<int, byte[], int, string> OnRebuild;
			public bool EnableRebuild = true;

			public FileStorage(string path, int bufSize = 1024 * 1024, int minSize = 1024, float factor = 8.0f, bool flashOnCommit = false)
			{
				path_ = path;
				minSize_ = minSize;
				factor_ = factor;
				buf_ = new byte[bufSize];
				flashOnCommit_ = flashOnCommit;
			}


			public void Connect(Cabinet c)
			{
				if( c_ != null)
				{
					throw new InvalidOperationException();
				}
				c_ = c;

				stream_ = new FileStream(path_, FileMode.OpenOrCreate);
				if (stream_.Length == 0)
				{
					writeHeader();
				}
				else
				{
					var buf = new byte[stream_.Length];
					stream_.Read(buf, 0, buf.Length);
					var reader = new Reader(c_, buf);
					if (!reader.ReadHeader())
					{
						c_.recoveryInfo_ = new RecoveryInfo { CommitId = 0, Message = "Invalid file header", LastValidCommitPosition = 0 };
					}
					else
					{
						c_.recoveryInfo_ = reader.ReadWithRecovery(shareAllSpan: false);
					}
				}
				rebuildThreshold_ = Math.Max((int)(stream_.Length * factor_), minSize_);

				writer_ = new Writer(c_, buf_);
			}

			void writeHeader()
			{
				var buf = new byte[Cabinet.GetHeaderSize()];
				Cabinet.PutHeader(buf, 0);
				stream_.Write(buf, 0, buf.Length);
			}

			void check()
			{
				if( c_ == null)
				{
					throw new InvalidOperationException("No cabinet connected");
				}
				if( disposed_ )
				{
					throw new InvalidOperationException("FileStorage already disposed");
				}
			}

			public void Rebuild()
			{
				check();

				var tmpFile = path_ + ".tmp";

				File.Delete(tmpFile);

				byte[] dumpBuf = null;
				using (var s = new FileStream(tmpFile, FileMode.Create))
				{

					var dumpSize = writer_.GetDumpSize(withHeader: true);
					Logger.Log("FileStorage.Rebuild size={0}", dumpSize);
					dumpBuf = new byte[dumpSize];
					var w = new Writer(c_, dumpBuf);
					w.WriteHeader();
					w.Dump();
					s.Write(dumpBuf, 0, dumpBuf.Length);
					rebuildThreshold_ = Math.Max((int)(dumpSize * factor_), minSize_);
				}

				stream_.Dispose();

				File.Replace(tmpFile, path_, PrevFilePath);

				var newStream = new FileStream(path_, FileMode.Append);
				stream_ = newStream;

				if (OnRebuild != null)
				{
					OnRebuild(c_.commitId_, dumpBuf, dumpBuf.Length, PrevFilePath);
				}
			}

			public void Commit()
			{
				check();

				writer_.Reset();
				if( !writer_.Commit())
				{
					return;
				}
				stream_.Write(writer_.Buf, 0, writer_.Position);

				stream_.Flush(flashOnCommit_);

				if (OnCommit != null)
				{
					OnCommit(c_.commitId_, writer_.Buf, writer_.Position);
				}

				if (EnableRebuild && stream_.Length > rebuildThreshold_)
				{
					Rebuild();
				}
			}

			public void Dispose()
			{
				if( stream_ != null && !disposed_)
				{
					stream_.Close();
					disposed_ = true;
				}
			}
		}
	}
}
