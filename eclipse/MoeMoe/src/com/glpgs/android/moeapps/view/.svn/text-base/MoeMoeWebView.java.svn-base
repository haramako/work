package com.glpgs.android.moeapps.view;

import static com.glpgs.android.moeapps.config.EnvironmentProvider.CACHE_PATH;

import java.util.List;

import org.apache.http.cookie.Cookie;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.net.Uri;
import android.util.AttributeSet;
import android.view.GestureDetector;
import android.view.View;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.LinearLayout;

import com.glpgs.android.moeapps.MoeMoeActivity;
import com.glpgs.android.moeapps.R;
import com.glpgs.android.moeapps.ScreenshotActivity;
import com.glpgs.android.moeapps.config.EnvironmentProvider;
import com.glpgs.android.moeapps.http.MoeMoeHttpClientManager;
import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;

@SuppressLint("SetJavaScriptEnabled")
public class MoeMoeWebView extends WebView {
	private static final String TAG = "MoeMoeWebView";
	private static final String WEBPATH = EnvironmentProvider.getWebBase();

	private Context context = getContext();

	//WebViewの上下のフェードのサイズ
	private static final int FADINGLENGTH = 15;

	GestureDetector gestureDetector;
	private String reloadUrl = "";
	//リロードかどうか
	public boolean checkReload = false;

	public MoeMoeWebView(Context context, AttributeSet attrs) {
		super(context, attrs);
		MyLog.d(TAG, TAG + " start!!");

		//gestureDetector = new GestureDetector(getContext(), this);

		//JavaScreiptを有効にする
		getSettings().setJavaScriptEnabled(true);
		//キャッシュに存在する場合はそちらを使用。cacheに無い or expireした場合はネットワーク経由でデータを取得
		getSettings().setCacheMode(WebSettings.LOAD_NORMAL);
		//getSettings().setCacheMode(WebSettings.LOAD_NO_CACHE);
		getSettings().setAppCacheMaxSize(1 * 1024 * 1024);
		getSettings().setAppCachePath(CACHE_PATH);
		getSettings().setUseWideViewPort(true);
		getSettings().setLoadWithOverviewMode(true);
		//ウェブサイトをアプリ内で表示
		setWebViewClient(new MoeMoeWebViewClient());
		//スクロールバー部分の隙間を消す
		setVerticalScrollbarOverlay(true);
		//スクロールバー領域をブラウザ領域の内側に表示させる
		setScrollBarStyle(View.SCROLLBARS_INSIDE_OVERLAY);
		//タップしたときにフォーカスをあてる
		requestFocus(View.FOCUS_DOWN);
		setVerticalFadingEdgeEnabled(true);
		//上限のフェードの幅
		setFadingEdgeLength(MoeMoeUtil.getDpiPixcelSize(FADINGLENGTH));

		CookieSyncManager.createInstance(getContext());
		CookieSyncManager.getInstance().startSync();
		CookieManager.getInstance().setAcceptCookie(true);
		CookieManager.getInstance().removeExpiredCookie();
	}

	@Override
	public void reload() {
		MyLog.d(TAG, "リロードします\n" + reloadUrl);
		checkReload = true;
		loadUrl(reloadUrl);
		//super.reload();
	}

	/*
	 * @see android.view.View#getSolidColor()
	 * WebViewの上下にグラデーションを表示
	 */
	@Override
	public int getSolidColor() {
		return Color.argb(255, 255, 255, 255);
	}

	public void setReloadUrl(String url) {
		reloadUrl = url;
	}

	/**
	 * WebViewClientをカスタムしてWebViewの操作に必要な機能を実装する
	 */
	private class MoeMoeWebViewClient extends WebViewClient {
		private static final String TAG = "MoeMoeWebViewClient";

		private static final String PATH_APPINFO = EnvironmentProvider.MOE_APPINFO_KEYWORD;
		private static final String PATH_MOPURITAN = EnvironmentProvider.MENU_MOPURITAN;
		private static final String PATH_MYMOE_APP = EnvironmentProvider.MENU_MYMOE_APP;
		//private static final String PATH_FAQ = EnvironmentProvider.MENU_FAQ;
		private static final String PATH_NOTICE = EnvironmentProvider.MENU_NOTICE;

		private static final String PATH_MARKET = EnvironmentProvider.MOE_APP_MARKET;
		private static final String PATH_SCREENSHOT = EnvironmentProvider.MOE_APP_SCREENSHOT;
		private static final String PATH_DOWNLOAD = EnvironmentProvider.MOE_APP_DOWNLOAD;

		private LinearLayout webViewParent = null;

		private int errorCode = 0;

		@Override
		public boolean shouldOverrideUrlLoading(WebView view, String url) {
			MyLog.d(TAG, "shouldOverrideUrlLoading() \nURL : " + url);

			if(!view.getUrl().equals(url)) {
				//ネットワークの状態を調べる
				if(MoeMoeUtil.checkNetwork()) {
					if(url.indexOf(WEBPATH + PATH_SCREENSHOT) != -1) {
						MyLog.d(TAG, "Displays Screenshot.");
						final Intent intent = new Intent(getContext(), ScreenshotActivity.class);
						intent.putExtra("screenshot", url);
						getContext().startActivity(intent);
					} else if(url.indexOf(WEBPATH + PATH_DOWNLOAD) != -1) {
						MyLog.d(TAG, "リダイレクト");
						//リダイレクト
						return super.shouldOverrideUrlLoading(view, url);
					} else if(url.indexOf(PATH_MARKET) != -1) {
						MyLog.d(TAG, "リダイレクト２ google store");
						Intent intent = new Intent(Intent.ACTION_VIEW);
						intent.setData(Uri.parse(url));
						context.startActivity(intent);
						MoeMoeUtil.pageViewTracker("/install/" + url);
						MoeMoeUtil.dispatchTracker();
					} else if(url.indexOf(WEBPATH+PATH_APPINFO) != -1) {
						MyLog.d(TAG, "アプリ情報");
						//アプリ情報のURLの場合
						//MoeMoeUtil.setInvisible(view);
						MoeMoeActivity.appinfoWebView.clearView();
						MoeMoeActivity.appinfoWebView.loadUrl(url);
						MoeMoeUtil.setVisible(MoeMoeActivity.appinfoWebView);
						MoeMoeUtil.changeTitle(R.string.pname_app_info);
					} else {
						MyLog.d(TAG, "非表示");
						MoeMoeUtil.setInvisible(view);
					}
				} else {
					if(url.indexOf(WEBPATH + PATH_SCREENSHOT) != -1) {
						//スクリーンショトのとき
						MoeMoeUtil.showToast(getResources().getString(R.string.error_toast_screenshot));
					} else {
						MoeMoeUtil.showToast(getResources().getString(R.string.error_toast_network));
					}
				}
			}
			return true;
		}

		@Override
		public void onPageStarted(WebView view, String url, Bitmap favicon) {
			MyLog.d(TAG, "onPageStarted() 読み込みはじめたよ～ \nURL : " + url);

			setWebViewParent(view);

			//アプリ情報と利用上の注意
			if(url.indexOf(WEBPATH+PATH_APPINFO) != -1 || url.indexOf(WEBPATH+PATH_NOTICE) != -1) {
				MoeMoeUtil.setVisible(MoeMoeActivity.backButton);
				MoeMoeUtil.setInvisible(MoeMoeActivity.menuButton);
			}

			if(url.indexOf("error.html") == -1) {
				//ネットワークエラー時のリロード用URLをセット
				reloadUrl = url;
			}

			if(errorCode == 0) {
				if(url.indexOf(WEBPATH + PATH_DOWNLOAD) != -1 || url.indexOf(PATH_MARKET) != -1 || url.indexOf(WEBPATH+PATH_APPINFO) != -1) {
					return;
				}
			}
			view.clearView();
		}

		@Override
		public void onPageFinished(WebView view, String url) {
			MyLog.d(TAG, "onPageFinished() 読み込みおわったよ～ \nURL : " + url);
			//エラーの場合は処理終了
			if(errorCode != 0) {
				errorCode = 0;
				view.clearView();
				return;
			}

			//ネットワークの状態を調べる
			if(MoeMoeUtil.checkNetwork()) {
				LinearLayout connectErrorView = (LinearLayout) ((FrameLayout) view.getParent().getParent()).findViewById(R.id.network_error_view);
				if(connectErrorView.getVisibility() == 0 && checkReload) {
					checkReload = false;
					MoeMoeUtil.setInvisible(connectErrorView);
				}
			}

			if(MoeMoeHttpClientManager.getCookieStore() != null) {
				Cookie cookie = null;
				if (MoeMoeHttpClientManager.getCookieStore() != null ) {
					List<Cookie> cookies = MoeMoeHttpClientManager.getCookieStore().getCookies();
					if (!cookies.isEmpty()) {
						for (int i = 0; i < cookies.size(); i++) {
							cookie = cookies.get(i);
						}
					}
					if (cookie != null) {
						String cookieString = cookie.getName() + "=" + cookie.getValue() + "; domain=" + cookie.getDomain();
						//CookieManager.getInstance().setCookie(url, CookieManager.getInstance().getCookie(url));
						CookieManager.getInstance().setCookie(EnvironmentProvider.getWebBase(), cookieString);
						CookieSyncManager.getInstance().sync();
					}
				}
			}
		}

		@Override
		public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
			MyLog.e(TAG, "onReceivedError errorCode : " + errorCode);
			view.loadUrl("file:///android_asset/error.html");
			reloadUrl = failingUrl;
			this.errorCode = errorCode;
			LinearLayout connectErrorView = (LinearLayout) ((FrameLayout) view.getParent().getParent()).findViewById(R.id.network_error_view);
			MoeMoeUtil.setVisible(connectErrorView);
			checkReload = false;
		}

		@Override
		public void doUpdateVisitedHistory(WebView view, String url, boolean isReload) {
			super.doUpdateVisitedHistory(view, url, isReload);
			//MyLog.d(TAG, "doUpdateVisitedHistory : " + url);
		}

		/**
		 * WebViewの表示/非表示を実際に行う親のViewをセットします
		 */
		private void setWebViewParent(WebView view) {
			if(webViewParent == null) {
				webViewParent = (LinearLayout) view.getParent();
			}
		}
	}
}
