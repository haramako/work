using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ToydeaCabinet
{
	/// <summary>
	/// 部分的に共有している可能性のある、byte配列のクラス
	///
	/// Span<byte>やSystem.ArraySegment<byte> とだいたい同じようなもの
	/// </summary>
	public struct ByteSpan : IEquatable<ByteSpan>, IComparable<ByteSpan>
	{
		/// <summary>
		/// 生データ
		///
		/// このデータは、基本的には変更してはいけないので、参照のみを行うように注意すること
		/// </summary>
		public byte[] RawData => data_;

		/// <summary>
		/// 開始位置
		/// </summary>
		public int Start => start_;

		/// <summary>
		/// 長さ
		/// </summary>
		public int Length => length_;

		/// <summary>
		/// 空かどうか
		/// </summary>
		public bool IsEmpty => length_ == 0;

		/// <summary>
		/// 変更されることがないかどうか
		///
		/// trueの場合、このByteSpanの内容は変更されないことが保証されている。
		/// つまり、RawDataを変更してはいけない
		///
		/// falseの場合、このByteSpanは変更される可能性があるので、
		/// いますぐ使うのでなければ、Freeze()して値をコピーする必要がある
		///
		/// 長さ０の場合は、常にtrue
		/// </summary>
		public bool IsFrozen => length_ == 0 || frozen_;

		/// <summary>
		/// 他のbyte[]やByteSpanと共有しているかどうか
		///
		/// 長さ０の場合は、常にtrue
		/// </summary>
		public bool IsShared => length_ != 0 && (!frozen_ || start_ != 0 || length_ != data_.Length);

		byte[] data_;
		int start_;
		int length_;
		int hash_;
		bool frozen_; // TODO: frozenは1ビットなので、start_などに埋め込める

		/// <summary>
		/// 文字列のUTF8のbyte配列から、ByteSpanを生成する
		///
		/// 常に、Freezeされている
		/// </summary>
		/// <param name="src">データの文字列</param>
		public ByteSpan(string src)
		{
			data_ = Encoding.UTF8.GetBytes(src);
			start_ = 0;
			length_ = src.Length;
			hash_ = 0;
			frozen_ = true;
			validate();
		}

		/// <summary>
		/// byte[]からByteSpanを生成する
		/// </summary>
		/// <param name="src">データ</param>
		/// <param name="frozen">このByteSpanのデータが変更されないことを保証するかどうか</param>
		public ByteSpan(byte[] src, bool frozen = false)
		{
			data_ = src;
			start_ = 0;
			length_ = src.Length;
			hash_ = 0;
			frozen_ = frozen;
			validate();
		}

		/// <summary>
		/// byte[]の一部からByteSpanを生成する
		/// </summary>
		/// <param name="src">データ</param>
		/// <param name="start">データの開始位置</param>
		/// <param name="length">データの長さ</param>
		/// <param name="frozen">このByteSpanのデータが変更されないことを保証するかどうか</param>
		public ByteSpan(byte[] src, int start, int length, bool frozen = false)
		{
			data_ = src;
			start_ = start;
			length_ = length;
			hash_ = 0;
			frozen_ = frozen;
			validate();
		}

		public static implicit operator ByteSpan(byte[] data)
		{
			return new ByteSpan(data);
		}

		public static implicit operator ByteSpan(string data)
		{
			return new ByteSpan(data);
		}

		/// <summary>
		/// 生成時のチェックを行う
		/// </summary>
		void validate()
		{
			if( length_ == 0)
			{
				frozen_ = true;
				data_ = null;
				return;
			}
			if( start_ < 0 || length_ < 0)
			{
				throw new Exception($"Invalid start or length");
			}
			if (data_ == null)
			{
				throw new Exception($"Data must not be null");
			}
			if ( start_ >= data_.Length)
			{
				throw new Exception($"Invalid start position {start_}, but data length {data_.Length}");
			}
			if (start_ + length_ > data_.Length)
			{
				throw new Exception($"Invalid end position {start_ + length_}, but data length {data_.Length}");
			}
			#if DEBUG
			GetHashCode(); // ValidateUnchanged()でチェックするためのハッシュを作成する
			#endif
		}

		/// <summary>
		/// ByteSpanが生成時点以降にで変更されていないかをチェックして、変更されていたら例外を投げる
		///
		/// デバッグ時のみ使用する
		/// </summary>
		[System.Diagnostics.Conditional("DEBUG")]
		public void ValidateUnchanged()
		{
			var oldHash = hash_;
			hash_ = 0;
			if( oldHash != GetHashCode())
			{
				throw new Exception($"Span changed! data={this}");
			}
		}

		/// <summary>
		/// 値が変更されない状態にしたコピーを作成する
		///
		/// すでに IsFrozen == true なら、なにもしないで自分を返す
		/// </summary>
		/// <returns>変更不可状態になったByteSpanを返す</returns>
		public ByteSpan Freeze()
		{
			if (IsFrozen)
			{
				return this;
			}
			else
			{
				//Logger.Log("Frozen: Duplicate ByteSpan");
				return new ByteSpan(ToBytes(), frozen: true);
			}
		}

		/// <summary>
		/// 配列の一部分を参照しているByteSpanを、一部分の参照ではなく全体が配列になっている状態にしたものを返す
		///
		/// IsShared == false なら、自分を返す
		///
		/// これは、メモリを無駄にしないために大きな配列のなかの小さな部分だけ参照しているものを排除するために使用する
		/// </summary>
		/// <returns>部分参照ではなくなったByteSpanを返す</returns>
		public ByteSpan Unshare()
		{
			if (!IsShared)
			{
				return this;
			}
			else
			{
				return new ByteSpan(ToBytes(), frozen: true);
			}
		}

		/// <summary>
		/// byte配列に変換する
		///
		/// IsFrozenかつIsSharedでなかった場合は、安全なので元のデータをそのまま返す
		/// </summary>
		/// <returns>byte[]配列</returns>
		public byte[] ToBytes()
		{
			if (IsFrozen && start_ == 0 && length_ == data_.Length)
			{
				return data_;
			}
			else
			{
				var result = new byte[length_];
				Buffer.BlockCopy(data_, start_, result, 0, length_);
				return result;
			}
		}

		public bool Equals(ByteSpan other)
		{
			if (length_ != other.length_)
			{
				return false;
			}

			var da = data_;
			var sa = start_;
			var db = other.data_;
			var sb = other.start_;

			if (da == db && sa == sb)
			{
				return true;
			}

			for (int i = 0; i < length_; i++)
			{
				if (da[sa + i] != db[sb + i])
				{
					return false;
				}
			}
			return true;
		}

		public override int GetHashCode()
		{
			if (hash_ != 0)
			{
				return hash_;
			}

			if (data_ == null)
			{
				return 0;
			}

			for (int i = 0, len = length_; i < len; i++)
			{
				hash_ = unchecked(hash_ * 457 + data_[start_ + i] * 389);
			}
			return hash_;
		}

		/// <summary>
		/// 特定のプレフィックスを持っているかどうかを返す
		/// </summary>
		/// <param name="prefix">プレフィックスを表すByteSpan</param>
		/// <returns>prefixがthisのプレフィックスであれば、trueを返す</returns>
		public bool HasPrefix(ByteSpan prefix)
		{
			if (length_ < prefix.Length)
			{
				return false;
			}

			var da = data_;
			var sa = start_;
			var db = prefix.data_;
			var sb = prefix.start_;

			if (da == db && sa == sb)
			{
				return true;
			}

			for (int i = 0, len = prefix.length_; i < len; i++)
			{
				if (da[sa + i] != db[sb + i])
				{
					return false;
				}
			}
			return true;
		}

		/// <summary>
		/// 文字列表現に変換する（デバッグ用）
		/// </summary>
		/// <returns>文字列表現</returns>
		public override string ToString()
		{
			if( length_ <= 0)
			{
				return string.Format("<ByteSpan len=0>");
			}
			else
			{
				return string.Format("<ByteSpan len={0} data=[{1}]>", length_, string.Join(",", ToBytes().Select(x => x.ToString("X2")).ToArray()));
			}
		}

		public int CompareTo(ByteSpan other)
		{
			// Length==0のときの特殊処理
			if(length_ <= 0)
			{
				if( other.length_ == 0)
				{
					return 0;
				}
				else if( other.length_ > 0)
				{
					return 1;
				}
			}
			else if(other.Length <= 0)
			{
				return -1;
			}

			var da = data_;
			var sa = start_;
			var db = other.data_;
			var sb = other.start_;

			if (da == db && sa == sb)
			{
				return 0;
			}

			for (int i = 0; i < length_; i++)
			{
				var ba = da[sa + i];
				var bb = db[sb + i];
				if( ba != bb)
				{
					//Logger.Log("comp {0} {1} {2} {3}", i, this, other, bb - ba);
					return (int)bb - (int)ba;
				}
			}
			return 0;
		}
	}
}
