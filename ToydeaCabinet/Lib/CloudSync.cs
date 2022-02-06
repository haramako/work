using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.IO;
using System.Runtime.Serialization;

#if !UNITY_2017_OR_NEWER
using System.Runtime.Serialization.Json;
#endif

namespace ToydeaCabinet
{
	public sealed class CloudSync : IDisposable
	{
		public enum StatusType
		{
			/// 初期化待ち
			Initializing,
			/// 同期済み
			Synchronized,
			/// エラーなどで接続が切られた状態
			Disconnected,
		}

		enum ResultError
		{
			Success,
			UnknownError,
			InvalidStatus,
		}

		Cabinet.FileStorage storage_;

		List<byte> sendBuffer = new List<byte>();
		StatusType status_;
		string sessionKey_;
		INetworkAdaptor networkAdaptor_;

		string url_;

		bool disposed_;
		int userId_;

		public StatusType Status => status_;

		public static int TimeoutMsec = 5000;

		public CloudSync(string url, int userId, Cabinet.FileStorage storage, INetworkAdaptor networkAdaptor = null)
		{
			url_ = url;
			userId_ = userId;
			storage_ = storage;
			storage_.OnCommit = OnCommit;
			storage_.OnRebuild = OnRebuild;
			if ( networkAdaptor == null )
			{
				networkAdaptor_ = new HttpNetworkAdaptor();
			}
			else
			{
				networkAdaptor_ = networkAdaptor;
			}
		}

		public void OnCommit(int commitId, byte[] buf, int bufLen)
		{
			if (disposed_)
			{
				return;
			}

			commitBuffer_.AddRange(buf.Take(bufLen));
		}

		List<byte> commitBuffer_ = new List<byte>();

		public void Sync()
		{
			var buf = commitBuffer_.ToArray();
			SyncCommit(buf, buf.Length);
			commitBuffer_.Clear();
		}

		public void OnRebuild(int commitId, byte[] buf, int bufLen, string prevFile)
		{
			if (disposed_)
			{
				return;
			}

			SyncDump(buf, bufLen);
		}

		void check()
		{
			if (disposed_)
			{
				throw new Exception("CloudSync already disposed");
			}
		}

		public void Dispose()
		{
			if (!disposed_)
			{
				disposed_ = true;
				status_ = StatusType.Disconnected;
			}
		}

		[DataContract]
		[Serializable]
		class LoginApiResult
		{
#pragma warning disable 649
			[DataMember(Name = "sessionKey")]
			public string sessionKey;
			[DataMember(Name = "lastCommit")]
			public int lastCommit;
#pragma warning restore 649
		}

		static public T parseJson<T>(byte[] data)
		{
			return (T)ParseJsonFunc(typeof(T), data);
		}

		#if UNITY_2017_OR_NEWER
		public static Func<Type, byte[], object> ParseJsonFunc = null;
		#else
		public static Func<Type, byte[], object> ParseJsonFunc = parseJsonInner;

		static public object parseJsonInner(Type type, byte[] data)
		{
			var serializer = new DataContractJsonSerializer(type);
			return serializer.ReadObject(new MemoryStream(data));
		}
		#endif

		public void StartSync()
		{
			check();
			if( status_ != StatusType.Initializing && status_ != StatusType.Disconnected)
			{
				throw new Exception("Invalid status " + status_);
			}

			// 現在のファイルの情報を取得する
			List<Cabinet.Chunk> chunks = null;
			if (File.Exists(storage_.Path))
			{
				var s = storage_.Stream;
				s.Seek(0, SeekOrigin.Begin);
				var buf = new byte[s.Length];
				s.Read(buf, 0, buf.Length);
				chunks = Cabinet.SplitChunks(buf);
			}

			// loginして、セッション確立と現在の状態を取得する
			int lastCommit = 0;
			try
			{
				sessionKey_ = null;
				var body = post(string.Format("/api/u/{0}/login", userId_), null);
				var res = parseJson<LoginApiResult>(body);
				sessionKey_ = res.sessionKey;
				Logger.Log("lastCommitId {0}", res.lastCommit);
				lastCommit = res.lastCommit;
			}
			catch (WebException)
			{
				status_ = StatusType.Disconnected;
				throw;
			}

			// 同期されていないコミットを同期
			if (chunks != null && chunks.Count > 0)
			{
				var chunksLastCommit = chunks[chunks.Count - 1].CommitId;
				if (lastCommit < chunksLastCommit)
				{
					var commits = chunks.Where(c => c.CommitId > lastCommit).ToArray();
					var buf = commits.SelectMany(c => c.Data.ToBytes()).ToArray();
					syncCommit(buf, buf.Length, statusCheck: false);
				}
			}

			status_ = StatusType.Synchronized;
		}

		public static void DeleteHistory(string url, int userId, INetworkAdaptor na = null)
		{
			Logger.Log("Delete");
			if (na == null)
			{
				na = new HttpNetworkAdaptor();
			}
			na.Post(string.Format("{0}/api/u/{1}/delete", url, userId), null, null);
		}

		public void StopSync()
		{
			status_ = StatusType.Disconnected;
		}

		public void SyncCommit(byte[] buf, int len)
		{
			syncCommit(buf, len, statusCheck: true);
		}

		void syncCommit(byte[] buf, int len, bool statusCheck)
		{
			if (statusCheck)
			{
				check();
				if (status_ != StatusType.Synchronized)
				{
					throw new Exception("Invalid status " + status_);
				}
			}

			var buf2 = new byte[len + Cabinet.GetHeaderSize()];
			Cabinet.PutHeader(buf2, 0);
			Buffer.BlockCopy(buf, 0, buf2, 3, len);

			try
			{
				var result = post(string.Format("/api/u/{0}/commit", userId_), buf2);
			}
			catch (Exception)
			{
				status_ = StatusType.Disconnected;
				throw;
			}
		}

		public void SyncDump(byte[] buf, int len)
		{
			check();
			if (status_ != StatusType.Synchronized)
			{
				throw new Exception("Invalid status " + status_);
			}

			var buf2 = new byte[len];
			Buffer.BlockCopy(buf, 0, buf2, 0, len);

			try
			{
				var result = post(string.Format("/api/u/{0}/dump", userId_), buf2);
			}
			catch (Exception)
			{
				status_ = StatusType.Disconnected;
				throw;
			}
		}

		public byte[] post(string path, byte[] body = null)
		{
			return networkAdaptor_.Post(url_ + path, body, sessionKey_);
		}


		public interface INetworkAdaptor
		{
			byte[] Post(string url, byte[] body, string SessionKey);
		}

		public class DummyNetworkAdaptor : INetworkAdaptor
		{
			public byte[] Post(string url, byte[] body, string SessionKey)
			{
				if (url.Contains("/login"))
				{
					return System.Text.Encoding.UTF8.GetBytes("{\"settionKey\":\"1234\"}");
				}
				else
				{
					return null;
				}
			}
		}

		public class HttpNetworkAdaptor : INetworkAdaptor
		{
			public HttpNetworkAdaptor()
			{
			}

			public byte[] Post(string url, byte[] body, string SessionKey)
			{
				byte[] resultBuffer = null;
				try
				{
					var req = WebRequest.Create(url);
					req.Timeout = CloudSync.TimeoutMsec;
					req.Method = "POST";
					req.ContentType = "application/octet-stream";
					if (SessionKey != null)
					{
						req.Headers.Add("X-Tc-Session-Key", SessionKey);
					}
					if (body != null)
					{
						req.ContentLength = body.Length;
						using (var s = req.GetRequestStream())
						{
							s.Write(body, 0, body.Length);
						}
					}
					else
					{
						req.ContentLength = 0;
					}

					using (var res = req.GetResponse())
					{
						var rs = res.GetResponseStream();
						resultBuffer = new byte[res.ContentLength];
						var len = rs.Read(resultBuffer, 0, resultBuffer.Length);
					}
				}
				catch (WebException ex)
				{
					Logger.Log("{0}", ex);
					throw;
				}

				return resultBuffer;
			}
		}

	}
}
