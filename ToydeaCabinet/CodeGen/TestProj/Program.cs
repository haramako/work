using System;
using ToydeaCabinet;
using System.Collections.Generic;

using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Linq;

public class BaseData
{
}

[Serializable]
public class Character : BaseData
{
    public int Id { get; set; }
    public string Name { get; set; }

    public byte[] Serialize()
    {
        return Encoding.UTF8.GetBytes(JsonSerializer.Serialize(this));
    }

    public static Character Deserialize(ByteSpan data)
    {
        return JsonSerializer.Deserialize<Character>(data.ToBytes());
    }
}

[Serializable]
public class Item : BaseData
{
    public int Id;

    public byte[] Serialize()
    {
        return Encoding.UTF8.GetBytes(JsonSerializer.Serialize(this));
    }
}

public struct IntRange
{
    public int Start;
    public int End;

    public IntRange(int s, int e)
    {
        Start = s;
        End = e;
    }

    public static IntRange Greater(int n)
    {
        return new IntRange(n + 1, Int32.MaxValue);
    }

    public static IntRange GreaterEq(int n)
    {
        return new IntRange(n, Int32.MaxValue);
    }

    public static IntRange Less(int n)
    {
        return new IntRange(0, n);
    }

    public static IntRange LessEq(int n)
    {
        return new IntRange(0, n - 1);
    }
}

public class Program
{
    public static void Main()
    {
        var c = new Cabinet();

        var rep = new Characters(c);
        rep.Save(new Character() { Id = 1, Name = "Tanjiro" });
        rep.Save(new Character() { Id = 2, Name = "Nezuko" });
        rep.Save(new Character() { Id = 3, Name = "Giyuu" });

        Console.WriteLine(rep.FindById(1).Name);

        foreach (var n in rep.SearchById(IntRange.Greater(1)))
        {
            Console.WriteLine(n.Name);
        }
    }
}

public partial class Characters
{
    CabinetKeyBuilder kb = new CabinetKeyBuilder();
    Cabinet c;
    public Characters(Cabinet _c)
    {
        c = _c;
    }

    public void Save(Character v)
    {
        var data = v.Serialize();

        kb.Clear();
        kb.Store(8, 1);
        kb.Store(32, (ulong)v.Id);
        c.Put(kb.Build(), data);
    }

    public Character FindById(int k)
    {
        kb.Clear();
        kb.Store(8, 1);
        kb.Store(32, (ulong)k);
        var data = c.Get(kb.Build());
        if (data.IsEmpty)
        {
            return null;
        }
        else
        {
            return Character.Deserialize(data);
        }
    }

    public IEnumerable<Character> SearchById(IntRange range)
    {
        kb.Clear();
        kb.Store(8, 1);
        kb.Store(32, (ulong)range.Start);
        var start = kb.Build();

        kb.Clear();
        kb.Store(8, 1);
        kb.Store(32, (ulong)range.End);
        var end = kb.Build();

        var found = c.GetRange(start, end);
        return found.Select(kv => Character.Deserialize(kv.Data));
    }
}
