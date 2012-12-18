package com.glpgs.android.moeapps;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Bundle;
import android.os.Handler;
import android.view.KeyEvent;
import android.view.Window;

import com.glpgs.android.moeapps.util.MyLog;

/**
 * SplashActivity
 *
 * 起動時の内部処理を行います
 */
public class SplashActivity extends Activity {
	private static final String TAG = "SplashActivity";

	private boolean backButtonAppClose = false;

	/** スプラッシュ終了時のディレイ */
	private static final int DELAY_FINISH = 1000;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		MyLog.d(TAG, "<---- MoeApps START ---->");
		super.onCreate(savedInstanceState);

		requestWindowFeature(Window.FEATURE_NO_TITLE);
		setContentView(R.layout.splash);

		//ネットワークの状態を調べる
		ConnectivityManager connectivity = (ConnectivityManager)this.getApplicationContext().getSystemService(Context.CONNECTIVITY_SERVICE);
		NetworkInfo network = connectivity.getActiveNetworkInfo();
		boolean notConnected = false;
		if (network == null) {
			//ネットワーク情報が存在しない
			MyLog.e(TAG, "no network");
			notConnected = true;
		} else {
			if (!network.isAvailable()) {
				//ネットワークが利用可能でない
				MyLog.e(TAG, "not isAvailable");
				notConnected = true;
			} else if (!network.isConnectedOrConnecting()) {
				//接続済みまたは接続中でない
				MyLog.e(TAG, "not isConnectedOrConnecting");
				notConnected = true;
			}
		}

		//通信エラーのとき
		if(notConnected) {
			MyLog.e(TAG, "通信エラーだぴょん");
		}
		finishDelayed();
	}

	/**
	 * ハードキーの入力を受け付けます。
	 * バックボタンがタップされた場合はアプリを終了します。
	 */
	@Override
	public boolean onKeyDown(int keyCode, KeyEvent event) {
		// 戻るボタンが押された場合の終了処理
		if(keyCode == KeyEvent.KEYCODE_BACK) {
			backButtonAppClose = true;
			finish();
			return true;
		} else if(keyCode == KeyEvent.KEYCODE_MENU) {
		} else {}
		return false;
	}

	private void finishDelayed(){
		Handler hdl = new Handler();
		hdl.postDelayed(new splashHandler(), DELAY_FINISH);
	}

	class splashHandler implements Runnable {
		public void run() {
			if(!backButtonAppClose) {
				Intent i = new Intent(getApplication(), MoeMoeActivity.class);
				startActivity(i);
				overridePendingTransition(R.anim.splash_fadeout1, R.anim.splash_fadeout2);
				finish();
			}
		}
	}
}