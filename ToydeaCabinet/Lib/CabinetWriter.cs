using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace ToydeaCabinet
{
	public sealed partial class Cabinet
	{

		/// <summary>
		/// キャビネットのデータをバイナリデータに保存するクラス
		///
		/// キャビネットは、下記のようにバイナリに記録される。
		///
		/// <code>
		///
		/// ファイルは、下記のような構造で記録される
		/// [ヘッダ?]
		/// [コミットサイズ][コミットID][レコード][レコード]...
		/// [コミットサイズ][コミットID][レコード][レコード]...
		/// ...
		/// (0 もしくは ファイルの終端)
		///
		///
		///
		/// 疑似Cのstruct的表現をすると、下記のようになる
		///
		/// struct File {
		///    uint8_t[3] ヘッダ?; // ['T','C',1]、メモリ内のバイナリの時点ではヘッダはない場合もある
		///    Commit[...] コミット;
		///  }
		///
		/// struct Commit {
		///   varnum コミットサイズ; // この構造体の、コミットサイズ自体を含まないサイズ
		///   uint32_t CRC32; // この構造体の、このフィールドよりあとのbyte配列のCRC32の値
		///   varnum コミットID;
		///   Record[レコード数] 記録されたレコード;
		/// }
		///
		/// struct Record {
		///   ByteSpan Recordのキー;
		///   ByteSpan Recordの値; // Recordの値の長さが-1の場合は、削除マークとして扱われる。
		///                        // ダンプ時は、単にレコード自体が書き込まれないので、削除マークは記録されない。
		/// }
		///
		/// // 可変長のバイト配列
		/// struct ByteSpan {
		///   varnum 長さ+1; // 長さ+1"となっているのは、"-1"を削除マークとして利用するため（記録されている値が0なら、長さは-1となる）
		///   uint8_t[長さ] データ;
		/// }
		///
		/// // 可変長の数値
		/// // 値によって 1~4バイトに可変する符号なし数値.
		/// // 0~127(0x7f)は1byte, 0x80~0x3ffは2byte, ... となり、最大 0x0fffffff(28bit) まで使用できる
		/// struct varnum {
		///   uint8_t[1~4] 数値の可変長表現;
		/// }
		///
		/// </code>
		///
		/// 固定長のファイルを扱えるように、コミットの切れ目のあとに 0 が記録されていたら、終端として扱う。
		/// つまり、データの後部が0で埋まっているファイルは正常に読み込める。
		///
		/// また、ファイルの終端にちょうど達した場合も、終端として扱う。
		/// これにより、ファイルの追記でコミットの追加ができる。
		///
		/// ヘッダは、扱う内容によっては、記録されない。
		/// これは、作成されたバイナリがファイルに書くこまれるものかどうかなどがわからないためである。
		/// 基本的に、ファイルに書き込む、もしくは、ネットワークで送信されるときにヘッダは追記される。
		///
		/// ヘッダが必要なのは、ファイルのバージョンによるマイグレーションが必要な可能性がある場所である。
		/// また、空のファイルの状態では、ヘッダーがない状態のものも許される
		/// </summary>
		public class Writer
		{
			/// <summary>
			/// 接続されているキャビネット
			/// </summary>
			Cabinet c_;

			byte[] buf_;
			int pos_;

			/// <summary>
			/// 書き込み先のバッファ
			/// </summary>
			public byte[] Buf => buf_;

			/// <summary>
			/// 現在の書き込み位置
			/// </summary>
			public int Position => pos_;

			public Writer(Cabinet c, byte[] buf, int pos = 0)
			{
				c_ = c;
				buf_ = buf;
				pos_ = pos;
			}

			public int sizeFixedInt()
			{
				return 4;
			}

			public void writeFixedInt(uint n)
			{
				buf_[pos_++] = (byte)n;
				buf_[pos_++] = (byte)(n >> 8);
				buf_[pos_++] = (byte)(n >> 16);
				buf_[pos_++] = (byte)(n >> 24);
			}

			/// <summary>
			/// 数値のbyte長を取得する
			/// </summary>
			/// <param name="n">対象の数値</param>
			/// <returns>サイズ[byte]</returns>
			public int sizeInt(int n)
			{
				uint u = (uint)n;

				if (u < 0x7f)
				{
					return 1;
				}
				else if (u < 0x3fff)
				{
					return 2;
				}
				else if (u < 0x1fffff)
				{
					return 3;
				}
				else if (u < 0x0fffffff)
				{
					return 4;
				}
				else
				{
					throw new ArgumentOutOfRangeException("too long");
				}
			}

			/// <summary>
			/// 数値を書き込む
			/// </summary>
			public void writeInt(int n)
			{
				uint u = (uint)n;

				if (u < 0x7f)
				{
					buf_[pos_++] = (byte)u;
				}
				else if (u < 0x3fff)
				{
					buf_[pos_++] = (byte)((u & 0x7f) | 0x80);
					buf_[pos_++] = (byte)(u >> 7);
				}
				else if (u < 0x1fffff)
				{
					buf_[pos_++] = (byte)((u & 0x7f) | 0x80);
					buf_[pos_++] = (byte)(((u >> 7) & 0x7f) | 0x80);
					buf_[pos_++] = (byte)(u >> 14);
				}
				else if (u < 0x0fffffff)
				{
					buf_[pos_++] = (byte)((u & 0x7f) | 0x80);
					buf_[pos_++] = (byte)(((u >> 7) & 0x7f) | 0x80);
					buf_[pos_++] = (byte)(((u >> 14) & 0x7f) | 0x80);
					buf_[pos_++] = (byte)(u >> 21);
				}
				else
				{
					throw new ArgumentOutOfRangeException("too long");
				}
			}

			/// <summary>
			/// キーのbyte長を取得する
			/// </summary>
			/// <param name="key">多指症のキー</param>
			/// <returns>キーのサイズ[byte]</returns>
			int sizeKey(CabinetKey key)
			{
				var len = key.Length;
				return sizeInt(len + 1) + len;
			}

			/// <summary>
			/// キーを書き込む
			/// </summary>
			void writeKey(CabinetKey key)
			{
				var len = key.Length;
				writeInt(len + 1);
				pos_ += key.WriteTo(buf_, pos_);
			}

			/// <summary>
			/// ByteSpanのbyte長を取得する
			/// </summary>
			/// <param name="span">対象のByteSpan</param>
			/// <returns>サイズ[byte]</returns>
			int sizeSpan(ref ByteSpan span)
			{
				return sizeInt(span.Length + 1) + span.Length;
			}

			/// <summary>
			/// ByteSpanを書き込む
			///
			/// refresh == true の場合、現在のバッファへの参照にデータを変更する。
			/// この場合、bufは変更されないように注意する必要がある。
			///
			/// これにより、ファイルの読み込みをした場合、データに関しては最初に読み込んだバッファと共有されることで、
			/// メモリ使用量を減らし、アロケーション回数をへらすことができる。
			/// </summary>
			/// <param name="span">対象のByteSpan</param>
			/// <param name="refresh">データを現在のバッファの部分配列とするかどうか</param>
			void writeSpan(ref ByteSpan span, bool refresh)
			{
				writeInt(span.Length + 1);
				span.ValidateUnchanged();
				Buffer.BlockCopy(span.RawData, span.Start, buf_, pos_, span.Length);
				if( refresh)
				{
					span = new ByteSpan(buf_, pos_, span.Length, frozen: true);
				}
				pos_ += span.Length;
			}


			/// <summary>
			/// レコード（キー＋値）のバイト長を取得する
			///
			/// ダンプの場合、削除されたレコードをは記録されない。
			/// ダンプでない場合、削除されたレコードは削除マークが記録される。
			/// </summary>
			/// <param name="record">対象のレコード</param>
			/// <param name="dump">ダンプかどうか</param>
			/// <returns>サイズ[byte]</returns>
			int sizeRecord(Record record, bool dump)
			{
				if (record.IsDeleted)
				{
					if (dump)
					{
						return 0;
					}
					else
					{
						return sizeKey(record.Key) + sizeInt(0);
					}
				}
				else
				{
					return sizeKey(record.Key) + sizeSpan(ref record.Data);
				}
			}

			/// <summary>
			/// レコードを書き込む
			///
			/// ダンプの場合、削除されたレコードをは記録されない。
			/// ダンプでない場合、削除されたレコードは削除マークが記録される。
			///
			/// また、ダンプの場合、参照がリフレッシュされて、今回書き込んだバッファの部分配列がデータから参照される。
			/// これにより、メモリ使用量を減らし、アロケーション回数をへらすことができる。
			/// </summary>
			/// <param name="record">対象のレコード</param>
			/// <param name="dump">ダンプかどうか</param>
			void writeRecord(Record record, bool dump)
			{
				if (record.IsDeleted)
				{
					if (!dump)
					{
						writeKey(record.Key);
						writeInt(0);
					}
				}
				else
				{
					writeKey(record.Key);
					writeSpan(ref record.Data, dump);
				}
			}

			/// <summary>
			/// バッファのいちをリセットする
			/// </summary>
			public void Reset()
			{
				pos_ = 0;
			}

			/// <summary>
			/// ダンプ時のバイト長を取得する
			/// </summary>
			/// <param name="withHeader">ファイルヘッダーを含むかどうか</param>
			/// <returns></returns>
			public int GetDumpSize(bool withHeader = false)
			{
				return GetCommitSize(dump: true, withHeader: withHeader);
			}

			/// <summary>
			/// ダンプする
			/// </summary>
			public void Dump()
			{
				Commit(dump: true);
			}

			/// <summary>
			/// コミット時のサイズを取得する
			/// </summary>
			/// <param name="dump">ダンプかどうか</param>
			/// <param name="withHeader">ファイルヘッダーを含むかどうか</param>
			/// <returns></returns>
			public int GetCommitSize(bool dump, bool withHeader)
			{
				int size = sizeInt(c_.commitId_ + (dump ? 0 : 1));
				size += sizeFixedInt(); // CRC32

				if (dump)
				{
					foreach (var cur in c_.data_)
					{
						size += sizeRecord(cur, dump: true);
					}
				}
				else
				{
					for (var cur = c_.dirtyRecordHead_; cur != null; cur = cur.Next)
					{
						size += sizeRecord(cur, dump: false);
					}
				}

				if( withHeader)
				{
					if( withHeader)
					{
						size += Writer.GetHeaderSize();
					}
					size += sizeInt(size);
				}
				return size;
			}

			/// <summary>
			/// ヘッダーを書き込む
			/// </summary>
			public void WriteHeader()
			{
				pos_ = PutHeader(buf_, pos_);
			}

			/// <summary>
			/// コミットを書き込む
			///
			/// </summary>
			/// <param name="dump">ダンプかどうか</param>
			/// <returns>コミットする内容があったかどうか(変更がなければ、falseを返す）</returns>
			public bool Commit(bool dump = false)
			{
				if (!dump && c_.dirtyRecordHead_ == null)
				{
					return false;
				}

				int size = GetCommitSize(dump: dump, withHeader: false);
				int headSize = sizeInt(size);
				if( pos_ + size + headSize > buf_.Length)
				{
					throw new Exception("Buffer size over");
				}
				writeInt(size);

				var crcPos = pos_;
				writeFixedInt(0); // hashの位置を確保

				var origPos = pos_;

				if( !dump )
				{
					c_.commitId_++;
				}

				writeInt(c_.commitId_);

				if( dump )
				{
					foreach (var cur in c_.data_)
					{
						writeRecord(cur, dump: true);
					}
				}
				else
				{
					//Logger.Log("commit");
					for (var cur = c_.dirtyRecordHead_; cur != null; cur = cur.Next)
					{
						writeRecord(cur, dump: false);
					}
				}

				//Logger.Log("Write {0}", size);

				if ( pos_ - crcPos != size)
				{
					throw new Exception($"Write size inconsist, expedt {size} buf {pos_- crcPos}");
				}

				// ハッシュを書き込む
				var crc = Crc32.Calc(buf_, origPos, pos_ - origPos);
				var backupPos = pos_;
				pos_ = crcPos;
				writeFixedInt(crc);
				pos_ = backupPos;

				return true;
			}

			/// <summary>
			/// ヘッダを配列の特定の位置に書き込む
			/// </summary>
			/// <param name="buf">対象のバッファ</param>
			/// <param name="pos">書き込む位置</param>
			/// <returns>書き込んだファイルヘッダーのサイズ[byte]</returns>
			public static int PutHeader(byte[] buf, int pos)
			{
				buf[pos++] = (byte)'T';
				buf[pos++] = (byte)'C';
				buf[pos++] = (byte)Cabinet.Version;
				return pos;
			}

			/// <summary>
			/// ファイルヘッダーのサイズを取得する
			/// </summary>
			/// <returns>サイズ[byte]</returns>
			public static int GetHeaderSize()
			{
				return 3;
			}
		}
	}
}
