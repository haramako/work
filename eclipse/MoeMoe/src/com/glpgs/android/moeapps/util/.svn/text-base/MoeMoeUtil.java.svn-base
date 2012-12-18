package com.glpgs.android.moeapps.util;

import static com.glpgs.android.moeapps.GCMIntentService.SENDER_ID;
import static com.glpgs.android.moeapps.config.EnvironmentProvider.GA_ACCOUNT_ID;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.security.NoSuchAlgorithmException;
import java.util.UUID;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.graphics.Point;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Build;
import android.view.Display;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.Toast;

import com.glpgs.android.moeapps.MoeMoeActivity;
import com.glpgs.android.moeapps.R;
import com.glpgs.android.moeapps.config.EnvironmentProvider;
import com.glpgs.android.moeapps.view.MoeMoeWebView;
import com.google.android.apps.analytics.GoogleAnalyticsTracker;
import com.google.android.gcm.GCMRegistrar;

/**
 * @author hiroyuki.takaya
 */
public class MoeMoeUtil {
	private static final String TAG = "MoeMoeUtil";

	//端末情報
	//ブランド名
	public static final String BRAND = Build.BRAND;
	//ユーザへ表示するモデル名
	public static final String MODEL = Build.MODEL;
	//バージョン番号
	public static final String VERSION_RELEASE = Build.VERSION.RELEASE;
	public static final String API_REGIST_DESK = "BRAND:" + BRAND + ",MODEL:" + MODEL + "VERSION_RELEASE:" + VERSION_RELEASE;

	private static final String SPNAME = "moemoePreferences";
	private static final String TAG_UUID = "UUID";
	private static final String TAG_UUID_DEF = "NOT_UULD";
	private static final String TAG_PUSH = "PUSH";
	private static final boolean TAG_PUSH_DEF = true;

	private static final float RATIO_X = 0.7f;

	public static ConnectivityManager connectivity;

	public static int width;
	public static int slideWidth;
	public static int height;
	public static int slideX;
	public static int dpi;
	public static float ratio;

	public static MoeMoeActivity activity;
	public static int titleId;
	//マイ萌えアプリからアプリ情報へ遷移したか
	public static boolean isMymoeApp = false;

	public static String GCMRegistId;
	public static String uuid;

	public static String version;
	public static String latestVersion;
	//最新バージョンか
	private static boolean isLatestVersion = false;

	private static GoogleAnalyticsTracker tracker = null;

	/**
	 * 起動回数を取得します。
	 * @return int launchCount
	 */
	public static int getLaunchCount() {
		final SharedPreferences settings = activity.getSharedPreferences(SPNAME, 0);
		final int launchCount = settings.getInt("launch_count", 0);
		setLaunchCount(launchCount);
		return launchCount;
	}

	/**
	 * 起動回数をセットします。
	 * Preferences から前回の起動回数を取得し、インクリメントして保存します。
	 */
	public static void setLaunchCount(int count) {
		MyLog.e(TAG, "起動回数 : " + count);
		final SharedPreferences settings = activity.getSharedPreferences(SPNAME, 0);
		final SharedPreferences.Editor editor = settings.edit();
		editor.putInt("launch_count", ++count).commit();
	}

	/**
	 * ネットワークの状態を調べる
	 */
	public static boolean checkNetwork() {
		if(connectivity == null) {
			connectivity = (ConnectivityManager)activity.getApplicationContext().getSystemService(Context.CONNECTIVITY_SERVICE);
		}

		NetworkInfo network = connectivity.getActiveNetworkInfo();
		if (network == null) {
			//ネットワーク情報が存在しない
			MyLog.e(TAG, "no network");
			return false;
		} else {
			if (!network.isAvailable()) {
				//ネットワークが利用可能でない
				MyLog.e(TAG, "not isAvailable");
				return false;
			} else if (!network.isConnectedOrConnecting()) {
				//接続済みまたは接続中でない
				MyLog.e(TAG, "not isConnectedOrConnecting");
				return false;
			}
		}
		return true;
	}

	/**
	 * アプリのバージョンを取得します
	 */
	public static String getVersion() {
		if(version != null) {
			return version;
		}

		PackageInfo packageInfo = null;
		try {
			packageInfo = activity.getPackageManager().getPackageInfo(EnvironmentProvider.APP_PACKAGE, PackageManager.GET_META_DATA);
		} catch (NameNotFoundException e) {
			e.printStackTrace();
		}
		version = packageInfo.versionName;
		return version;
	}

	/**
	 * アプリが最新バージョンかどうか判定します。
	 * 最新バージョンであればtrue、そうでない場合はfalseを返します。
	 * @return boolean
	 */
	public static boolean isLatestVersion() {
		checkVersion();

		MyLog.d(TAG, "version(" + version + ") = latestVersion(" + latestVersion + ")");

		if(isLatestVersion) {
			MyLog.d(TAG, "あなたのアプリは最新版です");
		} else {
			MyLog.d(TAG, "あなたのアプリは最新版ではないようです");
		}
		return isLatestVersion;
	}

	/**
	 * インストールされているアプリが最新バージョンかチェックします
	 * @param latestVersion
	 * @return boolean
	 */
	private static boolean checkVersion() {
		if(version == null) {
			getVersion();
		}

		isLatestVersion = true;

		if(latestVersion == null || latestVersion.equals("")) {
		} else {
			int[] latestVersionArray = toInteger(latestVersion.split("\\."));
			int[] versionArray = toInteger(version.split("\\."));
			int latestVersionLength = latestVersionArray.length;
			int versionLength = versionArray.length;

			if(latestVersionLength == versionLength) {
				for(int i = 0; i < latestVersionLength; i++) {
					//最新版のほうが数字が多い場合はfalseを返す
					if(latestVersionArray[i] > versionArray[i]) {
						isLatestVersion = false;
					}
				}
			} else {
				//最新バージョンの配列数が多い場合はture
				boolean bool = (latestVersionLength > versionLength) ? true : false;
				//配列数の多い方を代入
				int length1 = (latestVersionLength > versionLength) ? latestVersionLength : versionLength;
				//配列数の少ない方を代入
				int length2 = (latestVersionLength > versionLength) ? versionLength : latestVersionLength;
				//配列数の多い配列を代入
				int[] array1 = (latestVersionLength > versionLength) ? latestVersionArray : versionArray;
				//配列数の少ない配列を代入
				int[] array2 = (latestVersionLength > versionLength) ? versionArray : latestVersionArray;
				int[] array3 = new int[length1];

				//桁が足りない場合は0で埋める
				for(int i = 0; i < length1; i++) {
					if(i < length2) {
						array3[i] = array2[i];
					} else {
						array3[i] = 0;
					}
				}

				for(int x = 0; x < length1; x++) {
					//最新版のほうが数字が多い場合はfalseを返す
					if(array1[x] > array3[x] && bool) {
						isLatestVersion = false;
					}
				}
			}
		}
		return isLatestVersion;
	}

	/**
	 * UUIDを永続化する
	 * @param String uuid
	 */
	public static void setUUID(SharedPreferences settings, String _uuid) {
		MyLog.d(TAG, "uuid : " + _uuid);

		//UUIDを保存します
		SharedPreferences.Editor editor = settings.edit();
		editor.putString(TAG_UUID, _uuid);
		editor.commit();
	}

	/**
	 * 永続化したUUIDを取得
	 */
	public static String getUUID() {
		//端末に保存したUUIDを取得する
		final SharedPreferences settings = activity.getSharedPreferences(SPNAME, 0);
		final String uuid_back = settings.getString(TAG_UUID, TAG_UUID_DEF);
		MyLog.d(TAG, "uuid_back : " + uuid_back);

		uuid = uuid_back;

		if(uuid_back.equals(TAG_UUID_DEF)) {
			uuid = UUID.randomUUID().toString();

			//存在しない場合はUUIDを発行する
			setUUID(settings, uuid);
		}
		return uuid;
	}

	/**
	 * 画面タイトルを変更します
	 */
	public static void changeTitle(int stringId) {
		if(stringId == R.string.pname_latest_moe || stringId == R.string.pname_ranking || stringId == R.string.pname_mymoeapp) {
			activity.timeLinePageName = stringId;
		}
		titleId = stringId;
		activity.titleNameView.setText(titleId);
	}

	/**
	 * push通知設定を永続化する
	 * @param String uuid
	 */
	public static void setPush(boolean _push) {
		MyLog.d(TAG, "set push : " + _push);

		//push通知設定を保存します
		final SharedPreferences settings = activity.getSharedPreferences(SPNAME, 0);
		final SharedPreferences.Editor editor = settings.edit();
		editor.putBoolean(TAG_PUSH, _push);
		editor.commit();
	}

	/**
	 * 永続化したpush通知設定を取得
	 */
	public static boolean getPush() {
		//端末に保存したpush通知設定を取得する
		final SharedPreferences settings = activity.getSharedPreferences(SPNAME, 0);
		final boolean p = settings.getBoolean(TAG_PUSH, TAG_PUSH_DEF);
				MyLog.d(TAG, "get push : " + p);
		return p;
	}

	/**
	 * google cloud messaging のRegistIdを取得
	 * @param String regId
	 */
	public static String getGCMRegistId() {
		GCMRegistrar.checkDevice(activity);
		GCMRegistrar.checkManifest(activity);
		final String regId = GCMRegistrar.getRegistrationId(activity);

		if(regId.equals("")) {
		  GCMRegistrar.register(activity, SENDER_ID);
		} else {}
		//MyLog.d(TAG, "GCM RegistrationId : " + regId);
		GCMRegistId = regId;
		return GCMRegistId;
	}

	/**
	 * 端末のディスプレイ情報を取得し、メニュー表示に必要なスライド位置を求める
	 * @param disp
	 */
	@SuppressWarnings("deprecation")
	public static void setDispConfig(Display disp) {
		width = disp.getWidth();
		height = disp.getHeight();
		slideX = (int)(width * RATIO_X);

		slideWidth = width - slideX;
	}

	/**
	 * 端末のdpiを取得し、ピクセルの倍率を算出する
	 * @param int dpi 端末のdpi
	 */
	public static void setRatio(int _dpi) {
		dpi = _dpi;
		ratio = dpi / 160;
		MyLog.d(TAG, "Your Device DPI Ratio is : " + ratio);
	}

	/**
	 * dpiを考慮したピクセルサイズを求める
	 * @param int w 幅
	 * @param int y 高さ
	 * @return point size 求めた位置を返す
	 */
	public static Point getDpiPoint(int w, int y) {
		Point size = new Point();
		size.x = (int)(w * ratio);
		size.y = (int)(y * ratio);

		MyLog.d(TAG, "width : " + size.x);
		MyLog.d(TAG, "height : " + size.y);

		return size;
	}

	/**
	 * dpiを考慮したピクセルサイズを求める
	 * @param int pix 元のピクセルサイズ
	 * @return int dpiPix dpiの倍率を反映させたピクセルサイズ
	 */
	public static int getDpiPixcelSize(int pix) {
		return (int)(pix * ratio);
	}

	/**
	 * viewを表示する
	 * @param View view
	 */
	public static void setVisible(View view) {
		View v;

		if(view instanceof MoeMoeWebView) {
			v = (View)view.getParent();
		} else {
			v = view;
		}
		v.setVisibility(View.VISIBLE);
	}

	/**
	 * viewを非表示にする
	 * @param View view
	 */
	public static void setInvisible(View view) {
		View v;
		if (view instanceof MoeMoeWebView) {
			LinearLayout connectErrorView = (LinearLayout) ((FrameLayout) view.getParent().getParent()).findViewById(R.id.network_error_view);
			v = (View)view.getParent();
			MoeMoeUtil.setInvisible(connectErrorView);
		} else {
			v = view;
		}
		v.setVisibility(View.INVISIBLE);
	}

	/**
	 * ビューの表示状態をint型で返します。
	 * MoeMoeWebViewクラスであった場合は親のビューの状態を返します。
	 * @param View view
	 */
	public static int getVisibility(View view) {
		View v;

		if(view instanceof MoeMoeWebView) {
			v = (View)view.getParent();
		} else {
			v = view;
		}
		return v.getVisibility();
	}

	/**
	 * トーストを時間LONGで表示します。
	 * @param String mess メッセージ
	 */
	public static void showToast(String mess) {
		Toast.makeText(MoeMoeUtil.activity, mess, Toast.LENGTH_LONG).show();
	}

	/**
	 * アプリのインストール判定
	 *
	 * @param packageName パッケージ名
	 * @return boolean
	 */
	public static boolean isApplicationInstalled(Context context, String packageName){
		final PackageManager pm = context.getPackageManager();
		try {
			return pm.getApplicationInfo(packageName, 0) != null;
		} catch (NameNotFoundException e) {
			return false;
		}
	}

	/**
	 * 文字列配列を整数配列に変換します
	 * @param String[] value
	 * @return int[]
	 */
	private static int[] toInteger(final String[] value) {
		int length = value.length;
		int[] array = new int[length];
		for(int i = 0; i < length; i++) {
			array[i] = Integer.valueOf(value[i]);
		}
		return array;
	}

	private static final String ENCODING = EnvironmentProvider.ENCODING_TYPE;

	/**
	 * 文字列をURLエンコードします
	 * @param url URL文字列
	 * @throws NoSuchAlgorithmException
	 * @return String encoded_url URLエンコードされた文字列
	 */
	public static String toEncodeURL(String url) {
		String encoded_url = "";

		try {
			encoded_url = URLEncoder.encode(url, ENCODING);
			MyLog.d(TAG, "encoded_url = " + encoded_url);
		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
		}
		return encoded_url;
	}

	/**
	 * エンコードされたURLをデコードします
	 * @param url 遷移先URL文字列
	 * @throws NoSuchAlgorithmException
	 * @return decoded_url デコード処理されたURL文字列
	 */
	public static String toDecodeURL(String url) {
		String decoded_url = "";

		try {
			decoded_url = URLDecoder.decode(url, ENCODING);
			MyLog.e(TAG, "decoded_url = " + decoded_url);
		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
		}
		return decoded_url;
	}


	/**
	 * GoogleAnalyticsTrackerのセッションを開始します。
	 * インスタンスが無い場合は生成します。
	 * @param Context cnt
	 */
	public static void setTracker(Context cnt) {
		if(tracker == null) {
			tracker = GoogleAnalyticsTracker.getInstance();
		}

		//手動のディスパッチモードで追跡を開始する...
		tracker.startNewSession(GA_ACCOUNT_ID, cnt);
		//ディスパッチ間隔（秒）で指定して追跡を開始することも可能
		//tracker.start(GA_ACCOUNT_ID, 10, cnt);
		MyLog.d(TAG, "GoogleAnalyticsTracker start");
	}

	/**
	 * GoogleAnalyticsTrackerでページビューをカウントします。
	 * インスタンスが無い場合は生成します。
	 * @param String pageName カウントしたいページの名称
	 */
	public static void pageViewTracker(String pageName) {
		if(tracker == null) {
			MyLog.d(TAG, "GoogleAnalyticsTrackerが生成されていません。PageViewを行わず処理を終了します。");
			return;
		}

		if(!EnvironmentProvider.isDevelopment()) {
			tracker.trackPageView(pageName);
		} else {
			tracker.trackPageView(pageName + "_debug");
		}
		MyLog.d(TAG, "GoogleAnalyticsTracker PageView");
	}

	/**
	 * GoogleAnalyticsTrackerでページビューをカウントします。
	 * インスタンスが無い場合は生成します。
	 * @param String pageName カウントしたいページの名称
	 */
	public static void dispatchTracker() {
		tracker.dispatch();
		MyLog.d(TAG, "GoogleAnalyticsTracker dispatch");
	}
}
