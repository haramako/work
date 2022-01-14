using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;

// MEMO: このコードは、 https://github.com/DanPristupov/SkipList をもとに作成された
namespace ToydeaCabinet
{

	public partial class Cabinet
	{

		sealed class RecordSkipList : IEnumerable<Record>
		{
			private const int MaxLevel = 20;

			private readonly Random _random;
			private readonly Record _head;

			private int _version = 0;
			private int _level = 0;

			public RecordSkipList()
			{
				_random = new Random();
				_head = new Record();
				_head.SetLevel(MaxLevel);
				_version = 0;

				for (var i = 0; i <= MaxLevel; i++)
				{
					_head.Forward[i] = null;
				}
			}

			internal Record FindNode(CabinetKey item)
			{
				var node = Search(item);
				return node;
			}

			public bool Remove(CabinetKey key)
			{
				// X This block of code can be extracted as method
				var node = _head;
				for (var i = _level; i >= 0; i--)
				{
					while (node.Forward[i] != null && node.Forward[i].Key.CompareTo(key) < 0)
					{
						node = node.Forward[i];
					}
					updateList[i] = node;
				}
				node = node.Forward[0];
				// /X

				if (node == null || node.Key.CompareTo(key) != 0)
				{
					return false;
				}

				for (var i = 0; i <= _level; i++)
				{
					if (updateList[i].Forward[i] != node)
					{
						break;
					}
					updateList[i].Forward[i] = node.Forward[i];
				}
				while (_level > 0 && _head.Forward[_level] == null)
				{
					_level--;
				}
				_version++;
				return true;
			}

			public bool IsReadOnly { get { return false; } }

			private IEnumerable<Record> Items
			{
				get
				{
					var version = _version;
					var node = _head.Forward[0];
					while (node != null)
					{
						if (version != _version)
						{
							throw new System.InvalidOperationException("Collection was modified after the enumerator was instantiated.");
						}
						yield return node;
						node = node.Forward[0];
					}
				}
			}

			IEnumerator IEnumerable.GetEnumerator()
			{
				return Items.GetEnumerator();
			}

			public IEnumerator<Record> GetEnumerator()
			{
				return Items.GetEnumerator();
			}

			public bool TryGetValue(CabinetKey key, out Record rec)
			{
				var node = Search(key);
				if (node == null)
				{
					rec = null;
					return false;
				}
				else
				{
					rec = node;
					return true;
				}
			}

			public void Clear()
			{
				_version = 0;

				for (var i = 0; i <= MaxLevel; i++)
				{
					_head.Forward[i] = null;
				}
			}

			private Record Search(CabinetKey key)
			{
				var node = _head;

				for (var i = _level; i >= 0; i--)
				{
					//                Contract.Assert(_comparer.Compare(node.Key, key) < 0);
					while (node.Forward[i] != null)
					{
						var cmpResult = node.Forward[i].Key.CompareTo(key);
						if (cmpResult > 0)
						{
							break;
						}
						if (cmpResult == 0)
						{
							return node.Forward[i];
						}
						node = node.Forward[i];
					}
				}

				//            Contract.Assert(_comparer.Compare(node.Key, key) < 0);
				Debug.Assert(node.Forward[0] == null || key.CompareTo(node.Forward[0].Key) <= 0);
				node = node.Forward[0];

				if (node != null && node.Key.CompareTo(key) == 0)
				{
					return node;
				}
				return null;
			}

			Record[] updateList = new Record[MaxLevel + 1];

			UInt32 randCache;
			int randCachePos = -1;

			bool nextRandBit()
			{
				if( randCachePos < 0)
				{
					randCache = (UInt32)_random.Next();
					randCachePos = 31;
				}
				var b = randCache & (((UInt32)1) << randCachePos);
				randCachePos--;
				return b != 0;
			}

			public Record Insert(CabinetKey key, ByteSpan data)
			{
				// TODO: May I can use the update list and assign it to new Node.Neightbours directly
				var node = _head;
				for (var i = _level; i >= 0; i--)
				{
					while (node.Forward[i] != null && node.Forward[i].Key.CompareTo(key) < 0)
					{
						node = node.Forward[i];
					}
					updateList[i] = node;
				}
				node = node.Forward[0];
				if (node != null && node.Key.CompareTo(key) == 0)
				{
					node.Data = data;
					return node;
				}

				var newLevel = 0;
				for (; nextRandBit() && newLevel < MaxLevel; newLevel++) ;
				if (newLevel > _level)
				{
					for (var i = _level + 1; i <= newLevel; i++)
					{
						updateList[i] = _head;
					}
					_level = newLevel;
				}

				node = new Record { Key = key, Data = data };
				node.SetLevel(newLevel);

				for (var i = 0; i <= newLevel; i++)
				{
					node.Forward[i] = updateList[i].Forward[i];
					updateList[i].Forward[i] = node;
				}
				_version++;

				return node;
			}

			/// <summary>
			/// Get a first node greater equal than key or null.
			/// </summary>
			/// <param name="start">key</param>
			/// <returns>return a first node greater equal than key, or return null if no node greater equals than key.</returns>
			internal IEnumerable<Record> SearchRange(CabinetKey start, CabinetKey end)
			{
				var node = _head;

				for (var i = _level; i >= 0; i--)
				{
					//                Contract.Assert(_comparer.Compare(node.Key, key) < 0);
					while (node.Forward[i] != null)
					{
						var cmpResult = node.Forward[i].Key.CompareTo(start);
						if (cmpResult >= 0)
						{
							break;
						}
						node = node.Forward[i];
					}
				}

				//            Contract.Assert(_comparer.Compare(node.Key, key) < 0);
				Debug.Assert(node.Forward[0] == null || start.CompareTo(node.Forward[0].Key) <= 0);
				node = node.Forward[0];

				while (node != null && node.Key.CompareTo(end) < 0)
				{
					yield return node;
					node = node.Forward[0];
				}
			}

		}
	}
}
