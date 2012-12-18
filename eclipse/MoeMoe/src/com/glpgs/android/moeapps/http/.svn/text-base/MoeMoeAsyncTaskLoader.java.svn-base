package com.glpgs.android.moeapps.http;

import java.io.FileDescriptor;
import java.io.PrintWriter;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.content.res.Resources;
import android.support.v4.content.AsyncTaskLoader;

import com.glpgs.android.moeapps.http.MoeMoeHttpClientManager.ResultData;
import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;

/**
 * @author hiroyuki.takaya
 *
 */
public class MoeMoeAsyncTaskLoader extends AsyncTaskLoader<ResultData> {
	private static final String TAG = "MoeMoeAsyncTaskLoader";

	//最新バージョン確認
	//private static final int WORK_CHECK_LATEST_VERSION = 0;
	//登録とログイン処理
	private static final int WORK_LOGIN = 0;
	//push設定
	//private static final int WORK_PUSH_SETTING = 2;

	private int workId;
	private ResultData result;
	private Resources res = getContext().getResources();

	public MoeMoeAsyncTaskLoader(Context context, int id) {
		super(context);
		workId = id;
	}

	/*
	 * @see android.support.v4.content.AsyncTaskLoader#loadInBackground()
	 *
	 * ログイン処理を行います。
	 * UUIDが保存されていなければUUIDとGCMResultIdを取得し、登録処理を行います。
	 * レスポンスコード200 成功
	 * レスポンスコード401 登録済み
	 * レスポンスコード500 失敗
	 */
	@Override
	public ResultData loadInBackground() {
		//ResultData rd = null;

		switch (workId) {
			case WORK_LOGIN: {
//				//JSonデータを取得
//				ResultData versionRd = MoeMoeHttpClientManager.getVersion();
//				if(versionRd != null) {
//					String response = versionRd.value;
//					//MyLog.d(TAG, "Version（JSONData） : " + response);
//
//					try {
//						//サーバから最新バージョン情報を取得する
//						MoeMoeUtil.latestVersion = new JSONObject(response).getString("android");
//					} catch (JSONException e) {
//						e.printStackTrace();
//					}
//				} else {
//					MyLog.e(TAG, "サーバのバージョンを確認できませんでした（現在のバージョン : " + MoeMoeUtil.getVersion() + "）");
//				}
				//ログイン処理
				return MoeMoeHttpClientManager.apiLogin();
			}
		}
		return null;
	}

	@Override
	public void deliverResult(ResultData data) {
		if (isReset()) {
			if (this.result != null) {
				this.result = null;
			}
			return;
		}

		this.result = data;

		if (isStarted()) {
			super.deliverResult(data);
		}
	}

	@Override
	protected void onStartLoading() {
		if (this.result != null) {
			deliverResult(this.result);
		}
		if (takeContentChanged() || this.result == null) {
			forceLoad();
		}
	}

	@Override
	protected void onStopLoading() {
		super.onStopLoading();
		cancelLoad();
	}

	@Override
	protected void onReset() {
		super.onReset();
		onStopLoading();
	}

	@Override
	public void dump(String prefix, FileDescriptor fd, PrintWriter writer, String[] args) {
		super.dump(prefix, fd, writer, args);
	}
//
//	/**
//	 * 登録用パス作成
//	 * @param uiid
//	 * @param platform
//	 * @param push_token
//	 * @return String URLパス文字列
//	 */
//	private String apiRegist(String uiid, String platform, String push_token) {
//		String key1 = "regist?uiid=";
//		String key2 = "&platform=";
//		String key3 = "&push_token=";
//		String key4 = "&desc=";
//		String key5 = "&debug=";
//
//		String desc = MoeMoeUtil.API_REGIST_DESK;
//
//		if(!EnvironmentProvider.isDevelopment()) {
//			return key1 + uiid + key2 + platform + key3 + push_token;
//		} else {
//			return key1 + uiid + key2 + platform + key3 + push_token + key4 + MoeMoeUtil.toEncodeURL(desc) + key5;
//		}
//	}
//
//	/**
//	 * ログイン用パス作成
//	 * @param uiid
//	 * @return
//	 * String URLパス文字列
//	 */
//	private String apiLogin(String uiid) {
//		String key1 = "login?uiid=";
//		return key1 + uiid;
//	}
}