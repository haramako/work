using System;
using ToydeaCabinet;
using System.Collections.Generic;

using System.Linq;
using System.Text;

namespace ToydeaCabinet.Indexer
{
    public static class Range
    {
        public static Range<int> Between(int start, int end)
        {
            return new Range<int>(start, end);
        }

        public static Range<int> Eq(int n)
        {
            return new Range<int>(n, n+1);
        }

        public static Range<int> Greater(int n)
        {
            return new Range<int>(n + 1, Int32.MaxValue);
        }

        public static Range<int> GreaterEq(int n)
        {
            return new Range<int>(n, Int32.MaxValue);
        }

        public static Range<int> Less(int n)
        {
            return new Range<int>(0, n);
        }

        public static Range<int> LessEq(int n)
        {
            return new Range<int>(0, n - 1);
        }
    }

    public struct Range<T>
    {
        public T Start;
        public T End;

        public Range(T s, T e)
        {
            Start = s;
            End = e;
        }
    }

    public static class CabinetKeyBuilderExtension
    {
        public static CabinetKeyBuilder Cleared(this CabinetKeyBuilder kb)
        {
            kb.Clear();
            return kb;
        }

        public static CabinetKeyBuilder Store(this CabinetKeyBuilder kb, byte n)
        {
            kb.Store(1, (ulong)n);
            return kb;
        }

        public static CabinetKeyBuilder Store(this CabinetKeyBuilder kb, short n)
        {
            kb.Store(2, (ulong)n);
            return kb;
        }

        public static CabinetKeyBuilder Store(this CabinetKeyBuilder kb, ushort n)
        {
            kb.Store(2, (ulong)n);
            return kb;
        }

        public static CabinetKeyBuilder Store(this CabinetKeyBuilder kb, int n)
        {
            kb.Store(4, (ulong)n);
            return kb;
        }

        public static CabinetKeyBuilder Store(this CabinetKeyBuilder kb, uint n)
        {
            kb.Store(4, (ulong)n);
            return kb;
        }

        public static CabinetKeyBuilder Store(this CabinetKeyBuilder kb, string s)
        {
            kb.Store(Encoding.UTF8.GetBytes(s));
            kb.Store((byte)0); // '\0' terminated.
            return kb;
        }
    }

    public static class MyBitConverter
    {
        // .NETはintは32bitという風にサイズが固定で変化しない

        // 共通化できるものは処理を移譲する
        public static char Reverse(char value) => (char)Reverse((ushort)value);
        public static short Reverse(short value) => (short)Reverse((ushort)value);
        public static int Reverse(int value) => (int)Reverse((uint)value);
        public static long Reverse(long value) => (long)Reverse((ulong)value);

        // 伝統的な16ビット入れ替え処理16bit
        public static ushort Reverse(ushort value)
        {
            return (ushort)((value & 0xFF) << 8 | (value >> 8) & 0xFF);
        }

        // 伝統的な32ビット入れ替え処理
        public static uint Reverse(uint value)
        {
            return (value & 0xFF) << 24 |
                    ((value >> 8) & 0xFF) << 16 |
                    ((value >> 16) & 0xFF) << 8 |
                    ((value >> 24) & 0xFF);
        }

        // 伝統的な64ビット入れ替え処理
        public static ulong Reverse(ulong value)
        {
            return (value & 0xFF) << 56 |
                    ((value >> 8) & 0xFF) << 48 |
                    ((value >> 16) & 0xFF) << 40 |
                    ((value >> 24) & 0xFF) << 32 |
                    ((value >> 32) & 0xFF) << 24 |
                    ((value >> 40) & 0xFF) << 16 |
                    ((value >> 48) & 0xFF) << 8 |
                    ((value >> 56) & 0xFF);
        }

        // 浮動小数点はちょっと効率悪いけどライブラリでできる操作でカバーする
        public static float Reverse(float value)
        {
            byte[] bytes = BitConverter.GetBytes(value); // これ以上いい処理が思いつかない
            Array.Reverse(bytes);
            return BitConverter.ToSingle(bytes, 0);
        }

        public static double Reverse(double value)
        {
            byte[] bytes = BitConverter.GetBytes(value);
            Array.Reverse(bytes);
            return BitConverter.ToDouble(bytes, 0);
        }
    }
}

