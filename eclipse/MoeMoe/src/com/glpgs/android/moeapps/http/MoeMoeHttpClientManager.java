package com.glpgs.android.moeapps.http;

import static com.glpgs.android.moeapps.config.EnvironmentProvider.MOE_GET_VERSION;
import static com.glpgs.android.moeapps.config.EnvironmentProvider.MOE_PUSH;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.List;

import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.NameValuePair;
import org.apache.http.client.CookieStore;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.params.HttpParams;
import org.apache.http.util.EntityUtils;

import com.glpgs.android.moeapps.config.EnvironmentProvider;
import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;


/**
 * @author hiroyuki.takaya
 *
 */
public class MoeMoeHttpClientManager {
	private static final String TAG = "MoeMoeHttpClientManager";

	//POSTアクセスで使うクッキー
	static private CookieStore cookieStore;

	private static final String WEBPATH = EnvironmentProvider.getWebBase();

	private MoeMoeHttpClientManager() {}

	public static class ResultData {
		public String value;
		public int statusCode;

		private void printDebug() {
			MyLog.d(TAG, "レスポンスコード : " + statusCode);
		}
	}

	public static class NetworkException extends Exception {
		private static final long serialVersionUID = 3654560230238061768L;
	}

	public static class HttpErrorException extends NetworkException {
		private static final long serialVersionUID = 7857802406032508655L;

		private int _statusCode;

		public HttpErrorException(int statusCode) {
			_statusCode = statusCode;
		}

		public int getStatusCode(){
			return _statusCode;
		}
	}

	public static CookieStore getCookieStore(){
		return cookieStore;
	}

	private static final String ENCODING = EnvironmentProvider.ENCODING_TYPE;

	/**
	 * ハッシュ値生成用文字列を受け取り、SHA-256 でハッシュ値を生成して16進数文字列で返します。
	 * @param str ハッシュ値生成用文字列
	 * @throws NoSuchAlgorithmException
	 * @return 16進数文字列
	 */
//	public static String getHash(String str) {
//		return getHash(str, "");
//	}

	/**
	 * ハッシュ値生成用文字列を受け取り、SHA-256 でハッシュ値を生成して16進数文字列で返します。
	 * @param str ハッシュ値生成用文字列
	 * @param key ハッシュ値生成用キーワード
	 * @throws NoSuchAlgorithmException
	 * @return 16進数文字列
	 */
//	private static String getHash(String str, String key) {
//		MessageDigest md = null;
//
//		try {
//			md = MessageDigest.getInstance("SHA-256");
//
//		} catch(NoSuchAlgorithmException e){
//			return null;
//		}
//
//		md.reset();
//		// ハッシュ値生成
//		md.update((key + str).getBytes());
//		byte[] hash = md.digest();
//
//		// ハッシュ値を16進数文字列に変換
//		StringBuffer sb= new StringBuffer();
//		int cnt = hash.length;
//
//		for(int i = 0; i < cnt; i++) {
//			sb.append(Integer.toHexString( (hash[i]>> 4) & 0x0F ) );
//			sb.append(Integer.toHexString( hash[i] & 0x0F ) );
//		}
//
//		//MyLog.d(TAG, "hash : " + sb.toString());
//		return sb.toString();
//	}





	/**
	 * 登録とログイン処理を行います。
	 * @return ResultData rd ログイン処理の結果を返します。通信に失敗した場合nullを返します。
	 */
	public static ResultData apiLogin() {
		MyLog.d(TAG, "ユーザを登録します");
		ResultData rd1 = api1();
		ResultData rd2 = null;

		if(MoeMoeUtil.uuid != null || rd1.statusCode == 401) {
		//if(MoeMoeUtil.uuid != null || !MoeMoeUtil.GCMRegistId.equals("")) {
			MyLog.d(TAG, "ログインします");
			rd2 = api2();
		}
		return rd2;
	}

	/**
	 * 登録処理を行います。
	 * @return ResultData rd 登録処理の結果を返します。通信に失敗した場合nullを返します。
	 * @throws NetworkException
	 */
	private static ResultData api1() {
		ResultData rd = null;
		try {
			MyLog.d(TAG, "とりあえず登録");
			rd = MoeMoeHttpClientManager.get(WEBPATH + apiRegist(MoeMoeUtil.uuid, "android", MoeMoeUtil.GCMRegistId));
		} catch (NetworkException e) {
			MyLog.d(TAG, "ユーザ登録に失敗しました。：\n" + e.toString());
			e.printStackTrace();
		}
		return rd;
	}

	/**
	 * 登録とログイン処理を行います
	 * @return ResultData rd ログイン処理の結果を返します。通信に失敗した場合nullを返します。
	 * @throws NetworkException
	 */
	private static ResultData api2() {
		ResultData rd = null;
		try {
			MyLog.d(TAG, "ログイン");
			rd = MoeMoeHttpClientManager.get(WEBPATH + apiLogin(MoeMoeUtil.uuid));
		} catch (NetworkException e) {
			MyLog.d(TAG, "ログインに失敗しました。：\n" + e.toString());
			e.printStackTrace();
		}
		return rd;
	}

	/**
	 * 登録用パス作成
	 * @param uiid
	 * @param platform
	 * @param push_token
	 * @return String URLパス文字列
	 */
	private static String apiRegist(String uiid, String platform, String push_token) {
		String key1 = "regist?uiid=";
		String key2 = "&platform=";
		String key3 = "&push_token=";
		String key4 = "&desc=";
		String key5 = "&debug=";

		String desc = MoeMoeUtil.API_REGIST_DESK;

		if(!EnvironmentProvider.isDevelopment()) {
			return key1 + uiid + key2 + platform + key3 + push_token;
		} else {
			return key1 + uiid + key2 + platform + key3 + push_token + key4 + MoeMoeUtil.toEncodeURL(desc) + key5;
		}
	}

	/**
	 * ログイン用パス作成
	 * @param uiid
	 * @return
	 * String URLパス文字列
	 */
	private static String apiLogin(String uiid) {
		return "login?uiid=" + uiid;
	}

	/**
	 * get通信を行います
	 * @param String url ドメインを除いたパス文字列
	 * @return
	 * @throws NetworkException
	 */
	public static ResultData get(String url) throws NetworkException {
		DefaultHttpClient httpClient = new DefaultHttpClient();
		//クッキーをセット
		httpClient.setCookieStore(cookieStore);

		MyLog.d(TAG, "GET URL ： " + url);
		HttpGet httpGet = new HttpGet(url);
		//httpGet.setHeader("Connection", "Keep-Alive");

		try {
			HttpResponse response = httpClient.execute(httpGet);

			ResultData result = new ResultData();
			result.statusCode = response.getStatusLine().getStatusCode();
			result.value = EntityUtils.toString(response.getEntity(), "UTF-8");
			result.printDebug();

			// Cookie取得
			cookieStore = httpClient.getCookieStore();
			MyLog.d(TAG, "Cookie : " + cookieStore);

			return result;
		} catch(IOException e) {
			MyLog.d(TAG, "通信に失敗：" + e.toString());
			throw new NetworkException();
		}
	}

	/**
	 * 最新バージョン情報を取得します
	 * @return String バージョン情報
	 * @throws NetworkException
	 */
	public static ResultData getVersion() {
		DefaultHttpClient httpClient = new DefaultHttpClient();
		//クッキーをセット
		httpClient.setCookieStore(cookieStore);

		HttpGet httpGet = new HttpGet(WEBPATH + MOE_GET_VERSION);

		try {
			return getResultData(httpClient, httpClient.execute(httpGet));
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}

	/**
	 *
	 * @param String url push通知設定情報取得用URL
	 * @return String push設定
	 * @throws NetworkException
	 */
	public static ResultData getPush(boolean param) throws NetworkException {
		DefaultHttpClient httpClient = new DefaultHttpClient();
		//クッキーをセット
		httpClient.setCookieStore(cookieStore);

		HttpGet httpGet = new HttpGet(WEBPATH + MOE_PUSH + param);
		//httpGet.setHeader("Connection", "Keep-Alive");

		try {
			return getResultData(httpClient, httpClient.execute(httpGet));
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}

	/**
	 * POST通信を行います。サーバから必ず文字列のレスポンスを受けとり、メソッドの呼び出し元に返します。
	 * 第二引数のパラメータ配列が空の場合はHttpPostにセットしません。
	 * @param url 接続先URL
	 * @param params パラメータの配列
	 * @throws 色々
	 * @return レスポンス文字列
	 * @throws NetworkException
	 */
	public static ResultData post(String url, List<NameValuePair> params) throws NetworkException {
		// POSTパラメータ付きでPOSTリクエストを構築
		HttpPost request = new HttpPost(url);

		if(params.size() > 0) {
			try {
				// 送信パラメータのエンコードを指定
				request.setEntity(new UrlEncodedFormEntity(params, ENCODING));
				MyLog.d(TAG, "パラメータ：" + params);
			} catch (UnsupportedEncodingException e1) {
				e1.printStackTrace();
			}
		}

		// POSTリクエストを実行
		DefaultHttpClient  httpClient = new DefaultHttpClient();
		//クッキーをセット
		httpClient.setCookieStore(cookieStore);
		HttpParams httpParamsObj = httpClient.getParams();
		//User Agentの設定
		httpParamsObj.setParameter("http.useragent", "hoge");

		try {
			final ResultData result = new ResultData();

			//POST開始
			result.value = httpClient.execute(request, new ResponseHandler<String>() {
				@Override
				public String handleResponse(HttpResponse response) throws IOException {
					result.statusCode = response.getStatusLine().getStatusCode();

					// 正常に受信できた場合は200
					switch (response.getStatusLine().getStatusCode()) {
					case HttpStatus.SC_OK:
						MyLog.d(TAG, "レスポンス取得に成功");

						// レスポンスデータをエンコード済みの文字列として取得する
						return EntityUtils.toString(response.getEntity(), ENCODING);

					case HttpStatus.SC_NOT_FOUND:
						MyLog.d(TAG, "データが存在しない");
						return String.valueOf(result.statusCode);

					default:
						MyLog.e(TAG, "通信エラー");
						return String.valueOf(result.statusCode);
					}
				}
			});

			// Cookie取得
			cookieStore = httpClient.getCookieStore();

			return result;
		} catch (IOException e) {
			MyLog.e(TAG, "通信に失敗：" + e.toString());
			throw new NetworkException();
		} finally {
			// shutdownすると通信できなくなる
			httpClient.getConnectionManager().shutdown();
		}
	}

	/**
	 *
	 * @param レスポンスデータを返します。
	 * @return
	 * @throws NetworkException
	 */
	public static ResultData getResultData(DefaultHttpClient httpClient, HttpResponse resp) {
		ResultData result = new ResultData();
		try {
			result.statusCode = resp.getStatusLine().getStatusCode();
			result.value = EntityUtils.toString(resp.getEntity(), "UTF-8");
			// Cookie取得
			cookieStore = httpClient.getCookieStore();
			//MyLog.d(TAG, "Cookie : " + cookieStore);
		} catch(IOException e) {
			MyLog.d(TAG, "通信に失敗：" + e.toString());
		}
		return result;
	}
}
