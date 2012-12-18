package com.glpgs.android.moeapps.config;

public class EnvironmentProvider {
	//private static Mode mode = Mode.PRODUCTION;
	private static Mode mode = Mode.DEVELOPMENT;
	//ログ表示
	public static final boolean LOG = true;

	//パッケージ名
	public static final String APP_PACKAGE = "com.glpgs.android.moeapps";
	//お問い合わせのメールアドレス
	public static final String MAIL_ADDRESS = "info@moe-apps.com";
	//お問い合わせのメールアドレス
	public static final String GOOGLE_PLAY_URL = "market://details?id=";
	//レビュー催促の起動回数
	public static final int REVIEW_NUM = 10;

	//新着 - 全て
	public static final String LATEST_ALL = "latest/all";
	//新着 - 有料
	public static final String LATEST_PAID = "latest/paid";
	//新着 - 無料
	public static final String LATEST_FREE = "latest/free";
	//ランキング - 人気
	public static final String RANKING_POPULAR = "ranking/popular";
	//ランキング - 萌え
	public static final String RANKING_MOE = "ranking/moe";

	//もプリたんについて
	public static final String MENU_MOPURITAN = "moplitan.html";
	//マイ萌えアプリ
	public static final String MENU_MYMOE_APP = "mymoe";
	//よくあるご質問
	public static final String MENU_FAQ = "faq.html";
	//利用上のご注意
	public static final String MENU_NOTICE = "notice.html";

	//アプリ情報のURLパス
	public static final String MOE_APPINFO_KEYWORD = "appli/";
	//アプリダウンロードカウント用URL
	public static final String MOE_APP_DOWNLOAD = "appli/install/";
	//マーケット
	public static final String MOE_APP_MARKET = "market://details?id=";
	//スクリーンショット
	public static final String MOE_APP_SCREENSHOT = "appli/screenshot/";

	//最新バージョン情報を取得するURLパス
	public static final String MOE_GET_VERSION = "version";
	public static final String MOE_PUSH = "change_option?push=";

	//WebViewのキャッシュの保存場所
	public static final String CACHE_PATH = "/com.glpgs.android.moeapps/cache/";

	//文字コードのタイプ
	public static final String ENCODING_TYPE = "UTF-8";


	//google anarytics のアカウントID
	public static final String GA_ACCOUNT_ID  = "UA-7768431-15";

	//WebViewのタイムアウト時間
	public static final int WEBVIEW_TIMEOUT = 30000;

	public static boolean isDevelopment() {
		if(mode == Mode.DEVELOPMENT) {
			return true;
		}
		else {
			return false;
		}
	}

	public static boolean isLogging() {
		return isDevelopment();
	}

	public static String getWebBase() {
		return mode.web_path;
	}

	private enum Mode {
		PRODUCTION(
				"本番",
				"http://api.moe-apps.com/",
				GA_ACCOUNT_ID
				),
		DEVELOPMENT(
				"テスト",
				"http://219.94.246.227/moe_web/",
				GA_ACCOUNT_ID
				);

		private final String status;
		private final String web_path;
		private final String gaAccountId;

		Mode(String status, String _web_path, String gaId) {
			this.status = status;
			this.web_path = _web_path;
			this.gaAccountId = gaId;
		}
	}
}
