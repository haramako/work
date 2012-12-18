package com.glpgs.android.moeapps.flagment;

import java.util.List;

import org.apache.http.cookie.Cookie;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.WebSettings.PluginState;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.Toast;

import com.glpgs.android.moeapps.MoeMoeActivity;
import com.glpgs.android.moeapps.R;
import com.glpgs.android.moeapps.config.EnvironmentProvider;
import com.glpgs.android.moeapps.http.MoeMoeHttpClientManager;
import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;
import com.glpgs.android.moeapps.view.MoeMoeWebView;

public final class TimeLineFragment extends Fragment {
	private static final String TAG = "TimeLineFragment";

	private static final String WEBPATH = EnvironmentProvider.getWebBase();
	private static final String GETURL_KEY = "URL";

	private MoeMoeActivity activity;
	private MoeMoeWebView webView;
	private String urlPath = "";

	public static TimeLineFragment newInstance(String _urlPath) {
		TimeLineFragment fragment = new TimeLineFragment();
		fragment.urlPath = _urlPath;
		fragment.activity = MoeMoeUtil.activity;
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
		MyLog.d(TAG, TAG + " onCreateView start!");

		LinearLayout layout = new LinearLayout(getActivity());
		View v = inflater.inflate(R.layout.webview_applist, layout, false);
		layout.addView(v);

		webView = (MoeMoeWebView)v.findViewById(R.id.moemoe_webview);
		webView.setWebViewClient(new LatestAppWebViewClient());
		MoeMoe moemoe = new MoeMoe(getActivity());
		webView.addJavascriptInterface(moemoe, "android");
		//再起動時にprogressが終了しない問題の対策
		webView.getSettings().setPluginState(PluginState.ON);
		webView.setReloadUrl(WEBPATH + urlPath);
		webView.loadUrl(WEBPATH + urlPath);

		return layout;
	}

	@Override
	public void onSaveInstanceState(Bundle outState) {
		MyLog.d(TAG, TAG + " onSaveInstanceState start!");
		if(!urlPath.equals("")) {
			outState.putString(GETURL_KEY, urlPath);
		}
		super.onSaveInstanceState(outState);
	}

	/**
	 * 新着アプリページのweb操作を処理します
	 */
	private class LatestAppWebViewClient extends WebViewClient {
		private static final String TAG = "LatestAppWebViewClient";

		private static final String PATH_APPINFO = EnvironmentProvider.MOE_APPINFO_KEYWORD;

		private MoeMoeActivity activity = (MoeMoeActivity)getActivity();
		private int errorCode = 0;

		/**
		 * @param view
		 * @param url
		 * @return boolean
		 */
		@Override
		public boolean shouldOverrideUrlLoading(WebView view, String url) {
			MyLog.d(TAG, "shouldOverrideUrlLoading() \nURL : " + url);

			//ネットワークの状態を調べる
			if(MoeMoeUtil.checkNetwork() || !view.getUrl().equals(url)) {
				if(url.indexOf(WEBPATH+PATH_APPINFO) == -1) {
					MoeMoeUtil.setInvisible(view);
				}

				//アプリ情報のURLの場合
				if(url.indexOf(WEBPATH+PATH_APPINFO) != -1) {
					MoeMoeUtil.setInvisible(MoeMoeActivity.menuButton);
					MoeMoeUtil.setVisible(MoeMoeActivity.backButton);
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
			MyLog.d(TAG, "onPageStarted() 読み込みはじめたよ～ \nURL : " + url);

			//activityが終了したとき、エラーを検知したとき、『全て』でないときは処理しない
			if(!activity.appFinish && url.indexOf(EnvironmentProvider.LATEST_ALL) != -1) {
				//MyLog.d(TAG, "ページロード完了までプログレスを表示");
				activity.loadProgress(view);
			}
			//onPageFinished()が呼ばれる
		}

		@Override
		public void onPageFinished(WebView view, String url) {
			MyLog.d(TAG, "onPageFinished() 読み込みおわったよ～ \nURL : " + url);
			//アプリが終了している、エラーの場合は処理終了
			if(activity.appFinish) {
				errorCode = 0;
				return;
			}

			if(url.indexOf(EnvironmentProvider.LATEST_ALL) != -1 && activity.timeout) {
				activity.timeout = false;
				if(activity.progressLayout.getVisibility() == 0) {
					MyLog.d(TAG, "ページロード完了しプログレスを非表示");
					MoeMoeUtil.setInvisible(activity.progressLayout);
				}
			}

			//ネットワークの状態を調べる
			if(MoeMoeUtil.checkNetwork()) {
				LinearLayout connectErrorView = (LinearLayout) ((FrameLayout)view.getParent().getParent()).findViewById(R.id.network_error_view);
				if(connectErrorView.getVisibility() == 0) {
					//ネットワークエラーが表示されていれば非表示にする
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

			if(url.indexOf(WEBPATH+PATH_APPINFO) == -1) {
				MoeMoeUtil.setVisible(view);
			}
		}

		@Override
		public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
			MyLog.e(TAG, "onReceivedError errorCode : " + errorCode);
			view.loadUrl("file:///android_asset/error.html");
			this.errorCode = errorCode;
			webpageReloadView(activity, view);
		}

		@Override
		public void doUpdateVisitedHistory(WebView view, String url, boolean isReload) {
			super.doUpdateVisitedHistory(view, url, isReload);
			//MyLog.d(TAG, "doUpdateVisitedHistory : " + url);
		}
	}

	/**
	 * ネットワークエラーやタイムアウトでページを表示できなかったとき
	 * ネットワークエラービューを表示します。
	 * このときプログレスが表示されていれば非表示にします。
	 * @param activity
	 * @param view
	 * @param visible
	 */
	public static void webpageReloadView(MoeMoeActivity activity, View view) {
		if(activity != null) {
			if(activity.progressLayout.getVisibility() == View.VISIBLE) {
				MoeMoeUtil.setInvisible(activity.progressLayout);
			}

			LinearLayout connectErrorView = (LinearLayout) ((FrameLayout) view.getParent().getParent()).findViewById(R.id.network_error_view);
			MoeMoeUtil.setVisible(connectErrorView);
		}
	}

	/**
	 * @author hiroyuki.takaya
	 * 新着萌えアプリのJavaScriptで呼ばれる関数のクラス
	 *
	 */
	public class MoeMoe {
		private Context con;

		public MoeMoe(Context con) {
			this.con = con;
		}

		public void appearToast(String message) {
			Toast.makeText(con, message, Toast.LENGTH_LONG).show();
		}

		public void endProgress() {
			new Handler().post(new Runnable() {
				public void run() {
					//MoeMoeActivity.flag = true;
				}
			});
		}
	}
}
