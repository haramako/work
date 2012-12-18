package com.glpgs.android.moeapps;

import java.util.ArrayList;
import java.util.List;

import org.json.JSONArray;
import org.json.JSONException;

import android.app.ProgressDialog;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.view.ViewPager;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

import com.glpgs.android.moeapps.adapter.ScreenshotAdapter;
import com.glpgs.android.moeapps.http.MoeMoeHttpClientManager;
import com.glpgs.android.moeapps.http.MoeMoeHttpClientManager.NetworkException;
import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;
import com.viewpagerindicator.CirclePageIndicator;
import com.viewpagerindicator.PageIndicator;

public class ScreenshotActivity extends FragmentActivity {
	private static final String TAG = "ScreenshotActivity";

	public ScreenshotAdapter scrAdapter;
	public PageIndicator mIndicator;

	private ViewPager imgPager;
	private Button closeButton;
	private String params;
	private String response;

	// プログレスダイアログの設定
	ProgressDialog waitDialog ;

	public List<Bitmap> bitmpArray = new ArrayList<Bitmap>();
	public String[] screenshotUrlArray;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		MyLog.d(TAG, TAG + " Start!!");
		super.onCreate(savedInstanceState);
		setContentView(R.layout.app_info_screenshot);

		if(savedInstanceState != null) {
			response = savedInstanceState.getString("response");
			Log.d(TAG, "■■response : " + response);
		}

		if(response == null || response.equals("")) {
			params = getIntent().getStringExtra("screenshot");

			if(params == null) {
				finish();
				return;
			} else {
				//JSonデータを取得
				try {
					response = MoeMoeHttpClientManager.get(params).value;
					MyLog.d(TAG, "response（JSONData） : " + response);

				} catch (NetworkException e) {
					e.printStackTrace();
					MoeMoeUtil.showToast(getResources().getString(R.string.error_toast_screenshot));
					finish();
					return;
				}
			}
		}

		try {
			setimageURLArray(new JSONArray(response));
		} catch (JSONException e) {
			e.printStackTrace();
			finish();
			return;
		}

		scrAdapter = ScreenshotAdapter.newInstance(this, screenshotUrlArray);

		imgPager = (ViewPager) findViewById(R.id.app_info_screenshot_view);
		imgPager.setOffscreenPageLimit(screenshotUrlArray.length);
		imgPager.setAdapter(scrAdapter);

		mIndicator = (CirclePageIndicator)findViewById(R.id.app_info_screenshot_indicator);
		mIndicator.setViewPager(imgPager);

		closeButton = (Button)findViewById(R.id.do_close);
		closeButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				finish();
			}
		});
	}

	@Override
	protected void onResume() {
		super.onResume();
		MyLog.d(TAG, "onResume");
	}

	@Override
	protected void onPause() {
		super.onPause();
		MyLog.d(TAG, "onPause");
	}


	@Override
	protected void onSaveInstanceState(Bundle outState) {
		super.onSaveInstanceState(outState);
		outState.putString("response", response);
	}

	@Override
	protected void onRestoreInstanceState(Bundle savedInstanceState) {
		super.onRestoreInstanceState(savedInstanceState);
		response = savedInstanceState.getString("response");
	}

	@Override
	public void onUserLeaveHint() {
		MyLog.d(TAG, "アプリから離れます");
	}

	/**
	 * ハードキーの入力を受け付けます。
	 * バックボタンがタップされた場合はアプリを終了します。
	 */
	@Override
	public boolean onKeyDown(int keyCode, KeyEvent event) {
		if(keyCode == KeyEvent.KEYCODE_BACK) {
			MyLog.d(TAG, "onKeyDown バックボタンが押されました！！");
			finish();
			return true;
		} else if(keyCode == KeyEvent.KEYCODE_MENU) {
			MyLog.d(TAG, "onKeyDown メニューボタンがおされたよ");
		} else {
			MyLog.d(TAG, "onKeyDown なんかボタンが押されました！！");
		}
		return false;
	}

	/**
	 * JSONArrayをString配列に変換します
	 * @param JSONArray ja urlが格納されたJSON配列
	 */
	private void setimageURLArray(JSONArray ja) {
		int urlCount = ja.length();
		if(urlCount == 0) {
			return;
		}

		//初期化
		if(screenshotUrlArray == null) {
			screenshotUrlArray = new String[urlCount];
		}

		for(int i = 0; i < urlCount; i++) {
			try {
				screenshotUrlArray[i] = ja.getString(i);
			} catch (JSONException e) {
				e.printStackTrace();
			}
		}
	}
}
