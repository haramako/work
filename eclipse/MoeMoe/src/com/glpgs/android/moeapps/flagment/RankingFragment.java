package com.glpgs.android.moeapps.flagment;

import java.util.List;

import org.apache.http.cookie.Cookie;

import android.graphics.Bitmap;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.LinearLayout;

import com.glpgs.android.moeapps.MoeMoeActivity;
import com.glpgs.android.moeapps.R;
import com.glpgs.android.moeapps.config.EnvironmentProvider;
import com.glpgs.android.moeapps.http.MoeMoeHttpClientManager;
import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;
import com.glpgs.android.moeapps.view.MoeMoeWebView;

public final class RankingFragment extends Fragment {
	private static final String TAG = "RankingFragment";

	private static final String WEBPATH = EnvironmentProvider.getWebBase();
	private static final String GETURL_KEY = "URL";

	private MoeMoeActivity activity;
	private MoeMoeWebView webView;
	private String urlPath = "";

	public static RankingFragment newInstance(String _urlPath) {
		RankingFragment fragment = new RankingFragment();
		fragment.activity = MoeMoeUtil.activity;
		fragment.urlPath = _urlPath;

		return fragment;
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		MyLog.d(TAG, "onCreate start!");
		if(savedInstanceState != null) {
			urlPath = savedInstanceState.getString(GETURL_KEY);
		}
		super.onCreate(savedInstanceState);
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
		//MyLog.d(TAG, TAG + " onCreateView start!");

		LinearLayout layout = new LinearLayout(getActivity());

		View v = inflater.inflate(R.layout.webview_applist, layout, false);
		layout.addView(v);

		webView = (MoeMoeWebView)v.findViewById(R.id.moemoe_webview);
		webView.setWebViewClient(new RankingAppWebViewClient());
		webView.setReloadUrl(WEBPATH + urlPath);
		webView.loadUrl(WEBPATH + urlPath);
		//webView.loadUrl("file:///android_asset/ranking.html");

		return layout;
	}

	@Override
	public void onSaveInstanceState(Bundle outState) {
		//MyLog.d(TAG, TAG + " onSaveInstanceState start!");
		if(!urlPath.equals("")) {
			outState.putString(GETURL_KEY, urlPath);
		}
		super.onSaveInstanceState(outState);
	}

	/**
	 * ランキングページのweb操作を処理します
	 */
	private class RankingAppWebViewClient extends WebViewClient {
		private static final String TAG = "RankingAppWebViewClient";
		private static final String PATH_APPINFO = EnvironmentProvider.MOE_APPINFO_KEYWORD;

		private int errorCode = 0;

		@Override
		public boolean shouldOverrideUrlLoading(WebView view, String url) {
			MyLog.d(TAG, "shouldOverrideUrlLoading() \nURL : " + url);

			//ネットワークの状態を調べる
			if(MoeMoeUtil.checkNetwork() || !view.getUrl().equals(url)) {
				if(url.indexOf(WEBPATH+PATH_APPINFO) == -1) {
					MoeMoeUtil.setInvisible(webView);
				}

				//アプリ情報のURLの場合
				if(url.indexOf(WEBPATH+PATH_APPINFO) != -1) {
					MoeMoeUtil.setVisible(MoeMoeActivity.backButton);
					MoeMoeUtil.setInvisible(MoeMoeActivity.menuButton);
					MoeMoeActivity.appinfoWebView.clearView();
					MoeMoeActivity.appinfoWebView.loadUrl(url);
					MoeMoeUtil.setVisible(MoeMoeActivity.appinfoWebView);
					//MoeMoeActivity.titleName = (String) activity.titleNameView.getText();
					//activity.titleNameView.setText(getResources().getString(R.string.pname_app_info));
					MoeMoeUtil.changeTitle(R.string.pname_app_info);
				}
			}
			return true;
		}

		@Override
		public void onPageStarted(WebView view, String url, Bitmap favicon) {
			//MyLog.d(TAG, "onPageStarted() 読み込みはじめたよ～ \nURL : " + url);
		}

		@Override
		public void onPageFinished(WebView view, String url) {
			//MyLog.d(TAG, "onPageFinished() 読み込みおわったよ～ \nURL : " + url);

			//エラーの場合は処理終了
			if(errorCode != 0) {
				errorCode = 0;
				return;
			}

			//ネットワークの状態を調べる
			if(MoeMoeUtil.checkNetwork()) {
				LinearLayout connectErrorView = (LinearLayout) ((FrameLayout)view.getParent().getParent()).findViewById(R.id.network_error_view);
				if(connectErrorView.getVisibility() == 0) {
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
						CookieManager.getInstance().setCookie(EnvironmentProvider.getWebBase(), cookieString);
						CookieSyncManager.getInstance().sync();
					}
				}
			}

			if(url.indexOf(WEBPATH+PATH_APPINFO) != -1) {
			} else {
				MoeMoeUtil.setVisible(webView);
			}
		}

		@Override
		public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
			MyLog.e(TAG, "onReceivedError errorCode : " + errorCode);
			view.loadUrl("file:///android_asset/error.html");
			this.errorCode = errorCode;
			LinearLayout connectErrorView = (LinearLayout) ((FrameLayout) view.getParent().getParent()).findViewById(R.id.network_error_view);
			MoeMoeUtil.setVisible(connectErrorView);
		}

		@Override
		public void doUpdateVisitedHistory(WebView view, String url, boolean isReload) {
			super.doUpdateVisitedHistory(view, url, isReload);
			//MyLog.d(TAG, "doUpdateVisitedHistory : " + url);
		}
	}
}
