using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.CompilerServices;

namespace ToydeaCabinet
{
    /// <summary>
    /// キャビネットのキー。
    /// また、その合成を便利にするためのビルダーを兼ねる。
    ///
    /// この構造体は、Value Object、つまり、生成時から変更されることはない。
    /// 変更するようなメソッドは、かならず新しいCabinetKeyを返す。
    ///
    /// キャビネットのキーは、UInt64なので、基本的には Value のみが値を表す。
    /// ただし、キーに値を詰め込むために Position をもっている
    ///
    /// キーに数値を埋め込んでいく場合、MSB（つまり左側のビット）から使用される。
    /// これにより、先に埋め込まれたキーが、ソート時に優先されたキーとして利用される
    ///
    /// 使用例:
    /// <code>
    /// </code>
    /// </summary>
    public struct CabinetKey : IEquatable<CabinetKey>, IComparable<CabinetKey>, IComparable
    {
        /// <summary>
        /// キーの値（IsEmbededの場合）
        /// </summary>
        readonly UInt64 val_;

        /// <summary>
        /// キーの値（IsEmbededでない場合のみ有効）
        /// </summary>
        readonly byte[] buf_;

        /// <summary>
        /// Valueの長さ[byte]
        /// </summary>
        readonly int len_;

        /// <summary>
        /// UInt64の内部表現を持つか
        /// </summary>
        bool IsEmbeded => (buf_ == null);

        /// <summary>
        /// キーの値（IsEmbeded==trueの場合のみ有効）
        /// </summary>
        public UInt64 EmbededValue => val_;

        /// <summary>
        /// byte配列で表現した場合の、byte単位の長さ
        /// </summary>
        /// <returns>byte長を返す</returns>
        public int Length => IsEmbeded ? len_ : buf_.Length;

        public CabinetKey(UInt64 v, int pos)
        {
            val_ = v;
            len_ = pos;
            buf_ = null;
        }

        public CabinetKey(string src)
        {
            val_ = 0;
            len_ = 0;
            buf_ = System.Text.Encoding.UTF8.GetBytes(src);
        }

        public CabinetKey(byte[] src)
        {
            val_ = 0;
            len_ = 0;
            buf_ = src;
        }

        public CabinetKey(byte[] src, int start, int len)
        {
            val_ = 0;
            len_ = 0;
            buf_ = new byte[len];
            for (int i = 0; i < len; i++)
            {
                buf_[i] = src[start + i];
            }
        }

        /// <summary>
        /// UInt64のbyte単位の長さ
        /// </summary>
        public const int UInt64MaxLength = 8;

        /// <summary>
        /// 特定のプレフィックスを持っているかを返す
        /// </summary>
        /// <param name="key">プレフィックスのID</param>
        /// <returns>keyがthisのプレフィックスであれば、trueを返す</returns>
        public bool IsPrefixOf(CabinetKey key)
        {
            if (IsEmbeded && key.IsEmbeded)
            {
                if (len_ == 0)
                {
                    return true;
                }
                var rest = 64 - len_;
                return (key.val_ >> rest) == (val_ >> rest);
            }
            else
            {
                var data = key.AsBytes();
                var prefix = AsBytes();
                var len = prefix.Length;

                if (data.Length < len)
                {
                    return false;
                }

                for (int i = 0; i < len; i++)
                {
                    if (data[i] != prefix[i])
                    {
                        return false;
                    }
                }
                return true;
            }
        }

        /// <summary>
        /// 文字列の表現に変換する
        /// </summary>
        /// <returns></returns>
        public string AsString()
        {
            return Encoding.UTF8.GetString(AsBytes());
        }

        /// <summary>
        /// byte[]に変換する
        ///
        /// 内部のバッファを直接返すので、帰り値の内容を変更してはならない。
        ///
        /// Embededの場合は、内部でバッファを作成するので、バッファを作成されたくない場合は、Valueと使い分けること
        /// </summary>
        /// <returns></returns>
        public byte[] AsBytes()
        {
            if (IsEmbeded)
            {
                var len = Length;
                var bytes = new byte[len];
                for (int i = 0; i < len; i++)
                {
                    bytes[i] = getByte(i);
                }
                return bytes;
            }
            else
            {
                return buf_;
            }
        }

        /// <summary>
        /// プレフィックスの終わりのキーを返す
        /// </summary>
        public CabinetKey EndOfPrefix()
        {
            if (IsEmbeded)
            {
                return new CabinetKey(this.val_ + ((UInt64)1 << ((UInt64MaxLength - len_) * 8)), len_);
            }
            else
            {
                // TODO: 能率がわるいので、Rangeではなく、Prefixで直接サーチできるようにすること
                var next = new byte[buf_.Length];
                Array.Copy(buf_, next, next.Length);
                next[next.Length - 1] = (byte)(next[next.Length - 1] + 1);
                return new CabinetKey(next);
            }
        }

        /// <summary>
        /// Embededの場合のbyte表現を取得する
        /// </summary>
        /// <param name="pos">位置[byte]</param>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        byte getByte(int pos)
        {
            return (byte)(val_ >> ((UInt64MaxLength - 1 - pos) * 8));
        }

        public int WriteTo(byte[] buf, int pos, int start = 0)
        {
            var len = Length - start;
            if (IsEmbeded)
            {
                for (int i = 0; i < len; i++)
                {
                    buf[pos++] = getByte(i + start);
                }
            }
            else
            {
                for (int i = 0; i < len; i++)
                {
                    buf[pos++] = buf_[i + start];
                }
            }
            return len;
        }

        public int CompareTo(CabinetKey other)
        {
            if (IsEmbeded && other.IsEmbeded)
            {
                // 両方Embededの場合
                return val_.CompareTo(other.val_);
            }
            else if (!IsEmbeded && other.IsEmbeded)
            {
                // 相手がEmbededで、自分がEmbededでない場合（相手のCompareToに任せて、値を逆転させる）
                return -other.CompareTo(this);
            }
            else if (IsEmbeded && !other.IsEmbeded)
            {
                // 自分がEmbededで相手がEmbededでない場合
                var b = other.buf_;
                var len = Math.Min(len_, b.Length);
                for (int i = 0; i < len; i++)
                {
                    int comp = getByte(i) - b[i];
                    if (comp != 0)
                    {
                        return comp;
                    }
                }
                return len_.CompareTo(b.Length);
            }
            else
            {
                // 両方Embededでない場合
                var a = this.buf_;
                var b = other.buf_;
                var len = Math.Min(a.Length, b.Length);
                for (int i = 0; i < len; i++)
                {
                    int comp = a[i] - b[i];
                    if (comp != 0)
                    {
                        return comp;
                    }
                }
                return a.Length.CompareTo(b.Length);
            }
        }

        public override bool Equals(object obj)
        {
            if (obj is CabinetKey)
            {
                return CompareTo((CabinetKey)obj) == 0;
            }
            else
            {
                throw new InvalidOperationException();
            }
        }

        public int CompareTo(object obj)
        {
            if (obj is CabinetKey)
            {
                return CompareTo((CabinetKey)obj);
            }
            else
            {
                throw new InvalidOperationException();
            }
        }

        public bool Equals(CabinetKey other)
        {
            return CompareTo(other) == 0;
        }
    }

    public class CabinetKeyBuilder
    {
        public byte[] buf_;

        /// <summary>
        /// 長さ（byte)
        /// </summary>
        public int Length { get; private set; }

        public byte[] Data => buf_;

        public CabinetKeyBuilder()
        {
            buf_ = new byte[256];
        }

        public CabinetKeyBuilder Clear()
        {
            Length = 0;
            return this;
        }

        /// <summary>
        /// キーに数値を埋めこんだCabinetKeyを返す
        ///
        /// キーに数値を埋め込んでいく場合、MSB（つまり左側のビット）から使用される。
        /// これにより、先に埋め込まれたキーが、ソート時に優先されたキーとして利用される
        ///
        /// 長さ制限を超えた場合は、例外を投げる
        ///
        /// <code>
        /// var b = new CabinetKeyBuilder();
        /// b = b.Store(2, 0xff); // => 0xff00000000000000
        /// b = b.Store(1, 0x01); // => 0xff01000000000000
        /// </code>
        /// </summary>
        /// <param name="len">使用するbyte数</param>
        /// <param name="num">数値</param>
        /// <returns>数値を埋め込んだあとのCabietKeyを返す</returns>
        public CabinetKeyBuilder Store(int len, UInt64 num)
        {
            if (len < 1 || len > 64)
            {
                throw new ArgumentException("Bits must 1~64");
            }
            for (int i = 0; i < len; i++)
            {
                var shift = (len - 1 - i) * 8;
                Data[Length++] = (byte)((num >> shift) & 0xff);
            }
            return this;
        }

        public CabinetKeyBuilder Store(byte[] key)
        {
            for (int i = 0; i < key.Length; i++)
            {
                Data[Length++] = key[i];
            }
            return this;
        }

        public CabinetKey Build()
        {
            if (Length <= CabinetKey.UInt64MaxLength)
            {
                UInt64 num = 0;
                for (int i = 0; i < Length; i++)
                {
                    num |= ((UInt64)Data[i]) << ((CabinetKey.UInt64MaxLength - 1 - i) * 8);
                }
                return new CabinetKey(num, Length);
            }
            else
            {
                var key = new byte[Length];
                for (int i = 0; i < Length; i++)
                {
                    key[i] = Data[i];
                }
                return new CabinetKey(key, 0, Length);
            }
        }
    }
}
