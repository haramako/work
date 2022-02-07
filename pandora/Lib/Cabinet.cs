using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace ToydeaCabinet
{
	/// <summary>
	/// リカバリに関する情報
	/// </summary>
	public sealed class RecoveryInfo
	{
		public int CommitId;
		public string Message;
		public int LastValidCommitPosition;
	}

	/// <summary>
	/// データベース
	///
	///
	/// 使用例:
	/// <code>
	///
	///
	/// var c = new Cabinet(1024); // Cabinetの生成
	///
	/// c.Put("hoge", new byte[]{1,2,3}); // 値を格納
	///
	/// c.Get("hoge"); // => byte[]{1,2,3} 値を取得
	/// c.Exists("hoge"); // => true キーの存在を確認
	///
	/// c.Commit(); // 保存する
	///
	/// c.Delete("hoge"); // キーを削除
	///
	/// </code>
	///
	/// </summary>
	public sealed partial class Cabinet
	{
		/// <summary>
		/// ファイルバージョン
		/// </summary>
		public const int Version = 1;

		/// <summary>
		/// ストレージインターフェース
		///
		/// ファイルやオンメモリなどのストレージごとにこのインターフェースを実装する
		/// </summary>
		public interface IStorage
		{
			/// <summary>
			/// 初期化（Cabinetから呼ばれる）
			/// </summary>
			/// <param name="cabinet"></param>
			void Connect(Cabinet cabinet);
			/// <summary>
			/// 変更をコミットする
			/// </summary>
			void Commit();
		}

		/// <summary>
		/// 保存される
		/// </summary>
		public sealed class Record
		{
			/// <summary>
			/// キー
			/// </summary>
			public CabinetKey Key;

			/// <summary>
			/// データ
			///
			/// データは、共有されている場合があるので、扱いには注意すること
			/// </summary>
			public ByteSpan Data;

			/// <summary>
			/// 変更済みレコードリストの次の項目
			/// </summary>
			public Record Next;

			/// <summary>
			/// 変更/削除されていて、かつ、未コミット状態かどうか
			/// </summary>
			public bool IsDirty;

			/// <summary>
			/// 削除済みかどうか
			/// </summary>
			public bool IsDeleted;

			/// <summary>
			/// スキップリストのリンク
			/// </summary>
			public Record[] Forward;

			public void SetLevel(int level)
			{
				Forward = new Record[level + 1];
			}
		}

		/// <summary>
		/// 保持されているデータ
		/// </summary>
		RecordSkipList data_ = new RecordSkipList();

		/// <summary>
		/// 変更済みレコードリストの先頭
		///
		/// 変更済みレコードがなければ、null
		/// </summary>
		Record dirtyRecordHead_;

		int commitId_;

		/// <summary>
		/// 現在のコミットID
		/// </summary>
		public int CommitId => commitId_;

		/// <summary>
		/// リカバリの情報
		/// </summary>
		RecoveryInfo recoveryInfo_;

		/// <summary>
		/// 接続しているストレージ
		/// </summary>
		public IStorage Storage { get; }

		/// <summary>
		/// キーのリスト
		/// </summary>
		public IEnumerable<CabinetKey> Keys => data_.Where(i => !i.IsDeleted).Select(i => i.Key);

		/// <summary>
		/// 格納されているレコードの数
		/// </summary>
		public int Count => data_.Count(r => !r.IsDeleted);

		/// <summary>
		/// 値が変更されているレコードの数
		/// </summary>
		public int DirtyCount
		{
			get
			{
				int count = 0;
				for (Record cur = dirtyRecordHead_; cur != null; cur = cur.Next)
				{
					count++;
				}
				return count;
			}
		}

		/// <summary>
		/// リカバリされたかどうか？
		/// </summary>
		public bool IsRecovered => (recoveryInfo_ != null);

		public RecoveryInfo RecoveryInfo => recoveryInfo_;

		/// <summary>
		/// ストレージを指定して、生成する
		/// </summary>
		/// <param name="storage">使用するストレージ</param>
		public Cabinet(IStorage storage)
		{
			Storage = storage;
			Storage.Connect(this);
		}

		/// <summary>
		/// サイズを指定して、メモリ・ストレージに接続されたCabinetを生成する
		///
		/// これは、主にテストなどに使用する
		/// </summary>
		/// <param name="size"></param>
		public Cabinet(int size = 1024)
		{
			Storage = new MemoryStorage(size);
			Storage.Connect(this);
		}

		/// <summary>
		/// バッファを指定して、メモリ・ストレージに接続されたCabinetを生成する
		///
		/// バッファに、すでに保存された内容があれば、それを最初に読み込む
		/// </summary>
		/// <param name="buf"></param>
		public Cabinet(byte[] buf)
		{
			Storage = new MemoryStorage(initialBuf: buf);
			Storage.Connect(this);
		}

		/// <summary>
		/// キーをしてしてデータを取得する
		/// </summary>
		/// <param name="key">対象のキー</param>
		/// <returns>キーに対応したデータ。値が存在しない場合は、空のByteSpanを返す</returns>
		public ByteSpan Get(CabinetKey key)
		{
			Record found;
			if( data_.TryGetValue(key, out found))
			{
				if (found.IsDeleted)
				{
					return new ByteSpan();
				}
				else
				{
					return found.Data;
				}
			}
			else
			{
				return new ByteSpan();
			}
		}

		/// <summary>
		/// Get()の文字列バージョン
		/// </summary>
		public ByteSpan Get(string key) => Get(new CabinetKey(key));

		/// <summary>
		/// キーを指定して、値を格納する
		/// </summary>
		/// <param name="key">対象のキー</param>
		/// <param name="data">保存するデータ</param>
		public void Put(CabinetKey key, ByteSpan data)
		{
			Record found;
			if (data_.TryGetValue(key, out found))
			{
				//Logger.Log("Update {0}", key);
				found.Data = data.Freeze();
				found.IsDeleted = false;
				setDirty(found);
			}
			else
			{
				//Logger.Log("Insert {0}", key);
				Record newBlock = data_.Insert(key, data.Freeze());
				setDirty(newBlock);
			}
		}

		/// <summary>
		/// Put()の文字列バージョン
		/// </summary>
		public void Put(string key, ByteSpan data) => Put(new CabinetKey(key), data);

		/// <summary>
		/// キーを指定して、値を削除する
		/// </summary>
		/// <param name="key">対象のキー</param>
		/// <returns>キーがすでに存在していたかどうか</returns>
		public bool Delete(CabinetKey key)
		{
			Record found;
			if (data_.TryGetValue(key, out found))
			{
				//Logger.Log("Update {0}", key);
				found.Data = new ByteSpan();
				found.IsDeleted = true;
				setDirty(found);
				return true;
			}
			else
			{
				return false;
			}
		}

		/// <summary>
		/// Delete()の文字列バージョン
		/// </summary>
		public bool Delete(string key) => Delete(new CabinetKey(key));


		/// <summary>
		/// キー・値のペア
		///
		/// MEMO: .Net3.5に対応するため、Tupleは使っていない
		/// </summary>
		public struct KeyValuePair
		{
			public readonly CabinetKey Key;
			public readonly ByteSpan Data;
			public KeyValuePair(CabinetKey key, ByteSpan data)
			{
				Key = key;
				Data = data;
			}
		}

		/// <summary>
		/// すべてのキー・値を列挙する
		/// </summary>
		public IEnumerable<KeyValuePair> All()
		{
			return data_.Where(i => !i.IsDeleted).Select(i => new KeyValuePair(i.Key, i.Data));
		}

		/// <summary>
		/// 特定のプレフィックスをもつキーを列挙する
		/// </summary>
		/// <param name="prefix">キーのプレフィックス</param>
		/// <returns>指定されたプレフィックスのキー・値を返す</returns>
		public IEnumerable<KeyValuePair> GetPrefixed(CabinetKey prefix)
		{
			if (prefix.Length == 0)
			{
				// 空のプレフィックスだけは、ちょっと特別な処理が必要
				return data_.Where(i => !i.IsDeleted).Select(i => new KeyValuePair(i.Key, i.Data));
			}
			else
			{
				return data_.SearchRange(prefix, prefix.EndOfPrefix()).Where(i => !i.IsDeleted).Select(i => new KeyValuePair(i.Key, i.Data));
			}
		}

		/// <summary>
		/// 特定のプレフィックスの範囲
		/// </summary>
		/// <param name="prefix">キーのプレフィックス</param>
		/// <returns>指定されたプレフィックスのキー・値を返す</returns>
		public IEnumerable<KeyValuePair> GetRange(CabinetKey start, CabinetKey end)
		{
			return data_.SearchRange(start, end).Where(i => !i.IsDeleted).Select(i => new KeyValuePair(i.Key, i.Data));
		}

		/// <summary>
		/// キーを指定して、値が存在するかどうかを返す
		/// </summary>
		/// <param name="key">対象のキー</param>
		/// <returns>値が存在するかどうかを返す</returns>
		public bool Exist(CabinetKey key)
		{
			Record found;
			if (data_.TryGetValue(key, out found))
			{
				return !found.IsDeleted;
			}
			else
			{
				return false;
			}
		}

		/// <summary>
		/// Exist()の文字列バージョン
		/// </summary>
		public bool Exist(string key) => Exist(new CabinetKey(key));


		/// <summary>
		/// レコードを変更/削除済みにする
		/// </summary>
		/// <param name="r">対象のレコード</param>
		void setDirty(Record r)
		{
			if (!r.IsDirty)
			{
				r.IsDirty = true;
				r.Next = dirtyRecordHead_;
				dirtyRecordHead_ = r;
			}
		}

		// Dirty状態をクリアする
		void clearDirty()
		{
			for (var cur = dirtyRecordHead_; cur != null; )
			{
				if( cur.IsDeleted)
				{
					data_.Remove(cur.Key);
				}
				var next = cur.Next;
				cur.IsDirty = false;
				cur.Next = null;
				cur = next;
			}
			dirtyRecordHead_ = null;
		}

		/// <summary>
		/// 変更をコミットする
		/// </summary>
		public void Commit()
		{
			if( dirtyRecordHead_ == null)
			{
				return;
			}

			Storage.Commit();
			clearDirty();
		}

		/// <summary>
		/// すべてのレコードをクリアする
		/// データ破損時のリカバリの際のみ利用する
		/// </summary>
		void clearAllRecords()
		{
			commitId_ = 0;
			data_.Clear();
			dirtyRecordHead_ = null;
		}

		/// <summary>
		/// ヘッダを出力する
		/// </summary>
		/// <param name="buf">出力先のバッファ</param>
		/// <param name="pos">出力先の位置</param>
		/// <returns></returns>
		public static int PutHeader(byte[] buf, int pos) => Writer.PutHeader(buf, pos);

		/// <summary>
		/// ヘッダのバイナリサイズを取得する
		/// </summary>
		/// <returns>ヘッダのサイズ[byte]</returns>
		public static int GetHeaderSize() => Writer.GetHeaderSize();

	}

}
