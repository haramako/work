using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ToydeaCabinet
{
	public sealed partial class Cabinet
	{
		/// <summary>
		/// リカバリ可能なエラー
		/// </summary>
		public class RecoverableException : Exception
		{
			public RecoverableException(string message) : base(message) { }
		}

		/// <summary>
		/// CRCが一致しないエラー（リカバリ可能）
		/// </summary>
		public class InvalidCrcException : RecoverableException
		{
			public InvalidCrcException(string message) : base(message) { }
		}

		/// <summary>
		/// キャビネットのデータをバイナリデータから読み込むクラス
		///
		/// バイナリデータの構成については、Cabinet.Writer を参照
		/// </summary>
		public struct Reader
		{
			/// <summary>
			/// 接続されているキャビネット
			/// </summary>
			Cabinet c_;

			byte[] buf_;
			int pos_;

			/// <summary>
			/// 最後にコミットを読み終えた場所
			/// データ破損時のリカバリに利用する
			/// </summary>
			int lastSucceededPos_;

			public Reader(Cabinet c, byte[] buf, int pos = 0)
			{
				c_ = c;
				buf_ = buf;
				pos_ = pos;
				lastSucceededPos_ = 0;
			}

			public uint readFixedInt()
			{
				pos_ += 4;
				return ((uint)buf_[pos_ - 4]) | ((uint)buf_[pos_ - 3] << 8) | ((uint)buf_[pos_ - 2] << 16) | ((uint)buf_[pos_ - 1] << 24);
			}

			public int readInt()
			{
				int r = 0;
				byte c;

				c = buf_[pos_++];
				r |= (int)(c & 0x7f);
				if (c < 0x80)
				{
					return r;
				}

				c = buf_[pos_++];
				r |= (int)(c & 0x7f) << 7;
				if (c < 0x80)
				{
					return r;
				}

				c = buf_[pos_++];
				r |= (int)(c & 0x7f) << 14;
				if (c < 0x80)
				{
					return r;
				}

				c = buf_[pos_++];
				r |= (int)(c & 0x7f) << 21;
				if (c < 0x80)
				{
					return r;
				}

				throw new RecoverableException("Invalid number");
			}

			ByteSpan readSpan()
			{
				var len = readInt() - 1;
				if (len < 0)
				{
					throw new RecoverableException("Invalid span length");
				}
				pos_ += len;
				return new ByteSpan(buf_, pos_ - len, len, frozen: true);
			}

			CabinetKey readKey()
			{
				var len = readInt() - 1;
				if (len <= CabinetKey.UInt64MaxLength)
				{
					UInt64 key = 0;
					for (int i = 0; i < len; i++)
					{
						key |= ((UInt64)buf_[pos_++]) << ((7 - i) * 8);
					}
					return new CabinetKey(key, len);
				}
				else
				{
					byte[] key = new byte[len];
					Array.Copy(buf_, pos_, key, 0, len);
					pos_ += len;
					return new CabinetKey(key);
				}
			}

			void readBlock(bool shareSpan)
			{
				var key = readKey();
				var deleted = (buf_[pos_] == 0);
				if (deleted)
				{
					// 削除フラグがついてる
					c_.data_.Remove(key);
					pos_++;
				}
				else
				{
					var data = readSpan();
					if (!shareSpan)
					{
						data = data.Unshare();
					}
					c_.data_.Insert(key, data);
				}
			}

			/// <summary>
			/// ファイルヘッダを読み込み、正しいかを返す
			///
			/// バイト配列の時点で、ファイルヘッダがついてるかどうかは状況によるため、この関数だけを先に必要に応じて呼ぶこと
			///
			/// ヘッダが不正の場合は、falseを返す
			/// また、bufが長さ３以下の場合も、新規作成のファイルとして扱うため、問題ないものとして扱われtrueを返す
			/// </summary>
			/// <returns>ヘッダが正しいかどうか（もしくは、ファイルが空）</returns>
			public bool ReadHeader()
			{
				// ヘッダがないのはOK
				if( buf_.Length < 3)
				{
					return true;
				}

				if (buf_[pos_++] != (byte)'T')
				{
					return false;
				}
				if (buf_[pos_++] != (byte)'C')
				{
					return false;
				}
				if (buf_[pos_++] != (byte)Cabinet.Version)
				{
					return false;
				}
				return true;
			}

			/// <summary>
			/// ファイルからキャビネットにデータを読み込む
			///
			/// shareAllSpan == true を指定することによって、アロケーションをしないようにすることができる。
			/// </summary>
			/// <param name="shareAllSpan">レコードのデータをバッファと共有するかどうか</param>
			/// <param name="endPos">読み込み終了の位置（データ破損時の再読込のために必要）</param>
			/// <returns>現在の位置</returns>
			public int Read(bool shareAllSpan, int endPos)
			{
				bool isFirstChunk = true;
				while (pos_ < endPos)
				{
					int size;
					try
					{
						size = readInt();
					}
					catch (IndexOutOfRangeException)
					{
						// このIndexOutOfRangeExceptionは、ファイルが途中で切断されると起こるので、リカバリを行う
						throw new RecoverableException("Invalid chunk size");
					}

					if (size == 0)
					{
						break;
					}

					var crcPos = pos_;
					int crcSize = 4; // size of fixed int
					if (size - crcSize < 0 || pos_ + size > endPos)
					{
						throw new RecoverableException($"Invalid chunk size");
					}

					var savedCrc = readFixedInt();
					if ( pos_ + size - crcSize > buf_.Length)
					{
						throw new InvalidCrcException($"Invalid CRC errir, buffer over");
					}
					var crc = Crc32.Calc(buf_, pos_, size - crcSize);
					if( savedCrc != crc)
					{
						throw new InvalidCrcException($"Invalid CRC error, saved {savedCrc} but {crc}");
					}

					var origPos = pos_;
					var commitId = readInt();
					if (c_.commitId_ != 0)
					{
						if (c_.commitId_ + 1 != commitId)
						{
							throw new RecoverableException($"Invalid commit ID, expect {c_.commitId_ + 1} but {commitId}");
						}
					}
					c_.commitId_ = commitId;

					Logger.Log("Read commit={0}, size={1}, range={2}~{3}", commitId, size, crcPos, crcPos + size);
					while (pos_ - crcPos < size)
					{
						//Logger.Log("Read pos {0}", pos_);
						readBlock(isFirstChunk || shareAllSpan);
					}
					if (pos_ - crcPos != size)
					{
						throw new RecoverableException($"Read size inconsit, expect {size} but {pos_ - crcPos}");
					}
					isFirstChunk = false;

					lastSucceededPos_ = pos_; // リカバリ用にどこまで正常に読めたかを保存する
				}
				return pos_;
			}

			/// <summary>
			/// リカバリ付きのRead
			/// </summary>
			/// <returns>データが壊れていて、リカバリが行われた場合は、RecoveryInfoを返す。正常に読み込まれた場合はnullを返す</returns>
			public RecoveryInfo ReadWithRecovery(bool shareAllSpan)
			{
				var startPos = pos_; // 再び読み込むために、現在の位置を保存する
				try
				{
					Read(shareAllSpan, buf_.Length);
				}
				catch (RecoverableException ex)
				{
					// 最後に正常に読み込めた場所までで読み込み直す
					c_.clearAllRecords();
					pos_ = startPos;

					Read(shareAllSpan, lastSucceededPos_);

					Logger.Log("Read failed and recovered. {0}", ex);
					return new RecoveryInfo { CommitId = c_.CommitId, Message = ex.Message, LastValidCommitPosition = lastSucceededPos_};
				}
				return null;
			}

			/// <summary>
			/// データをコミットのチャンクごとに分解する
			/// </summary>
			/// <returns>コミットのチャンクのリスト</returns>
			public List<Chunk> SplitChunk()
			{
				if (!ReadHeader())
				{
					throw new Exception("Invalid header");
				}

				var list = new List<Chunk>();
				var lastCommitId = 0;
				while (pos_ < buf_.Length)
				{
					var chunk = new Chunk();
					var headPos = pos_;
					var size = readInt();

					var crcPos = pos_;
					var crc = readFixedInt();

					var origPos = pos_;
					if (size == 0)
					{
						break;
					}

					var commitId = readInt();
					if (lastCommitId != 0)
					{
						if (lastCommitId + 1 != commitId)
						{
							throw new Exception($"Invalid commit ID, expect {c_.commitId_ + 1} but {commitId}");
						}
					}
					lastCommitId = commitId;
					chunk.CommitId = commitId;

					chunk.Data = new ByteSpan(buf_, headPos, (crcPos + size) - headPos);
					list.Add(chunk);

					pos_ = crcPos + size;
				}
				return list;
			}
		}

		/// <summary>
		/// コミット単位のバイナリの塊
		///
		/// これらは、特定のコミット単位でデータを扱う際に使用する
		/// </summary>
		public class Chunk
		{
			/// <summary>
			/// コミットID
			/// </summary>
			public int CommitId;

			/// <summary>
			/// DataのCRC32
			/// </summary>
			public int Crc32;

			/// <summary>
			/// レコードが複数されたデータのバイナリ表現
			/// </summary>
			public ByteSpan Data;
		}

		/// <summary>
		/// データをコミットごとのChunkに分割する
		/// </summary>
		/// <param name="buf">対象のバイト配列（ファイルヘッダ付きのもの）</param>
		/// <returns>読み込まれたChunkのリスト</returns>
		public static List<Chunk> SplitChunks(byte[] bufWithHeader)
		{
			return new Reader(null, bufWithHeader).SplitChunk();
		}
	}
}
