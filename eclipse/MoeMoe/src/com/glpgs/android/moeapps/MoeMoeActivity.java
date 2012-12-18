package com.glpgs.android.moeapps;

import static com.glpgs.android.moeapps.config.EnvironmentProvider.APP_PACKAGE;
import static com.glpgs.android.moeapps.config.EnvironmentProvider.GOOGLE_PLAY_URL;
import static com.glpgs.android.moeapps.config.EnvironmentProvider.REVIEW_NUM;

import java.util.Date;
import java.util.Random;
import java.util.Timer;
import java.util.TimerTask;

import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.StrictMode;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.LoaderManager;
import android.support.v4.content.Loader;
import android.support.v4.view.ViewPager;
import android.util.DisplayMetrics;
import android.view.Display;
import android.view.KeyEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.WindowManager;
import android.webkit.WebView;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;

import com.glpgs.android.moeapps.adapter.MenuAdapter;
import com.glpgs.android.moeapps.adapter.RankingAdapter;
import com.glpgs.android.moeapps.adapter.TimeLineAdapter;
import com.glpgs.android.moeapps.config.EnvironmentProvider;
import com.glpgs.android.moeapps.flagment.TimeLineFragment;
import com.glpgs.android.moeapps.http.MoeMoeAsyncTaskLoader;
import com.glpgs.android.moeapps.http.MoeMoeHttpClientManager;
import com.glpgs.android.moeapps.http.MoeMoeHttpClientManager.ResultData;
import com.glpgs.android.moeapps.util.Balloon;
import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;
import com.glpgs.android.moeapps.view.MoeMoeWebView;
import com.viewpagerindicator.PageIndicator;
import com.viewpagerindicator.TitlePageIndicator;

/**
 * @author hiroyuki.takaya
 *
 */
public class MoeMoeActivity extends FragmentActivity implements LoaderManager.LoaderCallbacks<ResultData> {
	private static final String TAG = "MoeMoeActivity";

	//新着のViewPager
	public TimeLineAdapter tmlnAdapter;
	ViewPager latestViewPager;
	public static MoeMoeWebView appinfoWebView;

	//ランキングのViewPager
	public RankingAdapter rnkAdapter;
	ViewPager rankingViewPager;

	PageIndicator mIndicator;
	public int timeLinePageName;

	public static AccordionSet slideMenu;
	public static LinearLayout parentLayout;
	public static LinearLayout settingView;
	public static LinearLayout coverLayout;
	public LinearLayout progressLayout;
	public static Button backButton;
	public static Button menuButton;
	public TextView titleNameView;
	public static String timelineTitleName;

	public MoeMoeWebView mopuritanWebView;
	public MoeMoeWebView MyMoeWebView;
	public MoeMoeWebView singleWebView;
	public ImageView mopuritan;

	public Balloon balloon;

	//アプリ終了は判定する
	public boolean appFinish = false;

	@SuppressLint("NewApi")
	@TargetApi(9)
	@Override
	public void onCreate(Bundle savedInstanceState) {
		MyLog.d(TAG, TAG + " start!");
		super.onCreate(savedInstanceState);
		setContentView(R.layout.moe_main);

		//起動回数の測定
		MoeMoeUtil.setTracker(this);
		MoeMoeUtil.pageViewTracker("/MoeApps");
		MoeMoeUtil.dispatchTracker();

		MoeMoeUtil.activity = this;

		MoeMoeUtil.getUUID();
		MoeMoeUtil.getGCMRegistId();

		//もプリたん初期化
		balloon = Balloon.getInstance(this);
		mopuritan = (ImageView) findViewById(R.id.character);
		blinkMopuritan();

		//WebViewロード用プログレス
		progressLayout = (LinearLayout) findViewById(R.id.progress_view);

		if(android.os.Build.VERSION.SDK_INT > 9) {
			StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
			StrictMode.setThreadPolicy(policy);
		}

		//ネットワークの状態を調べる
		if(!MoeMoeUtil.checkNetwork()) {
			//エラーメッセージ
			MoeMoeUtil.showToast(getString(R.string.error_toast_network));
		} else {
			//最新バージョンかチェックします
			if(!checkLatestVersion(savedInstanceState)) {
				//最新バージョンでないとき処理終了
				return;
			}
		}

		//画面サイズ取得
		WindowManager wm = (WindowManager)getSystemService(Context.WINDOW_SERVICE);
		Display disp = wm.getDefaultDisplay();
		MoeMoeUtil.setDispConfig(disp);

		DisplayMetrics metrics = new DisplayMetrics();
		getWindowManager().getDefaultDisplay().getMetrics(metrics);
		MoeMoeUtil.setRatio(metrics.densityDpi);

		//メニュー表示作成
		final LinearLayout menuFrame = (LinearLayout) findViewById(R.id.menu_frame);
		ListView menuListView = (ListView) findViewById(R.id.menu_list);
		// フォーカスが当たらないようにする
		menuListView.setItemsCanFocus(false);

		MenuAdapter adapter = new MenuAdapter();
		menuListView.setAdapter(adapter.init(this));
		menuListView.setOnItemClickListener(adapter);

		menuFrame.layout(-MoeMoeUtil.slideX, 0, (MoeMoeUtil.width - MoeMoeUtil.slideX), MoeMoeUtil.height);

		//もどるボタン
		backButton = (Button) findViewById(R.id.do_back);
		backButton.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				MyLog.d(TAG, "戻るボタンが押されました");
				backView();
			}
		});

		titleNameView = (TextView)findViewById(R.id.navbar_title);
		MoeMoeUtil.changeTitle(R.string.pname_latest_moe);
		timelineTitleName = (String) titleNameView.getText();

		//PageViewの初期化
		initPageView();

		MyMoeWebView = (MoeMoeWebView) ((LinearLayout) findViewById(R.id.mymoe_webview_layout)).findViewById(R.id.moemoe_webview);
		singleWebView = (MoeMoeWebView) ((LinearLayout) findViewById(R.id.setting_webview_layout)).findViewById(R.id.moemoe_webview);
		settingView = (LinearLayout)findViewById(R.id.setting_view);

		parentLayout = (LinearLayout) findViewById(R.id.parent_view);
		coverLayout = (LinearLayout) findViewById(R.id.cover);

		menuButton = (Button) findViewById(R.id.do_menu);
		//メニュー開閉処理
		slideMenu = new AccordionSet(menuButton, parentLayout);
	}

	@Override
	protected void onResume() {
		super.onResume();
		MyLog.d(TAG, "onResume");
		//TODO バージョンチェック処理
	}

	@Override
	protected void onPause() {
		super.onPause();
		MyLog.d(TAG, "onPause");
	}

	/**
	 * ハードキーの入力を受け付けます。
	 * バックボタンがタップされた場合はアプリを終了します。
	 */
	@Override
	public boolean onKeyDown(int keyCode, KeyEvent event) {
		// 戻るボタンが押された場合の終了処理
		if(keyCode == KeyEvent.KEYCODE_BACK) {
			//MyLog.d(TAG, "onKeyDown バックボタンが押されました！！");
			if(!balloon.getShowVersionBalloon()) {
				if(slideMenu.getOpened()) {
					slideMenu.callIvent();
				} else {
					backView();
				}
			} else {
				balloon.closeBalloon();
				finish();
			}
			return true;
		} else if(keyCode == KeyEvent.KEYCODE_MENU && slideMenu != null/* && !progressEnable*/) {
			//MyLog.d(TAG, "onKeyDown メニューボタンがおされたよ");
			if(menuButton.getVisibility() == 0 && !balloon.getOpened()) {
				slideMenu.callIvent();
			}
			return false;
		} else {
			//MyLog.d(TAG, "onKeyDown なんかボタンが押されました！！");
			return false;
		}
	}

	@Override
	public Loader<ResultData> onCreateLoader(int id, Bundle bundle) {
		return new MoeMoeAsyncTaskLoader(this, id);
	}

	@Override
	public void onLoadFinished(Loader<ResultData> arg0, ResultData rd) {
		if(rd != null && rd.statusCode == 200) {
			//起動回数をカウントする
			final int count = MoeMoeUtil.getLaunchCount();

//			if(EnvironmentProvider.isDevelopment()) {
//				TextView tv = (TextView) findViewById(R.id.launch_count);
//				tv.setText(String.valueOf(count));
//				tv.setVisibility(View.VISIBLE);
//			}
			//Random rndm = new Random(new Date().getTime());
			if(count >= REVIEW_NUM && (count % REVIEW_NUM == 0) /*&& rndm.nextInt(REVIEW_NUM) > 3*/) {
				//レビュー催促
				balloon.setBalloon(getString(R.string.balloon_review), Balloon.BALLOON_REVIEW);
			}
		}
	}

	@Override
	public void onLoaderReset(Loader<ResultData> arg0) {}

	@Override
	public void finish() {
		MyLog.d(TAG, "<---- MoeApps FINISH ---->");
		appFinish = true;
		super.finish();
	}

	@Override
	public void onUserLeaveHint() {
		//MyLog.d(TAG, "アプリから離れます");
		if(!MoeMoeUtil.isLatestVersion()) {
			balloon.closeBalloon();
			finish();
		} else if(balloon.getOpened()) {
			balloon.closeBalloon();
		}
	}

	/**
	 * PageViewの初期化を行います
	 */
	public void initPageView() {
		tmlnAdapter = new TimeLineAdapter(getSupportFragmentManager());
		rnkAdapter = new RankingAdapter(getSupportFragmentManager());
		latestViewPager = (ViewPager)findViewById(R.id.latest_app_view);
		latestViewPager.setOffscreenPageLimit(tmlnAdapter.mCount);
		rankingViewPager = (ViewPager)findViewById(R.id.ranking_app_view);
		rankingViewPager.setOffscreenPageLimit(rnkAdapter.mCount);
		mIndicator = (TitlePageIndicator)findViewById(R.id.indicator);
		mIndicator.setOnPageChangeListener(new ViewPager.OnPageChangeListener() {
			@Override
			public void onPageSelected(int position) {}
			@Override
			public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {}
			@Override
			public void onPageScrollStateChanged(int state) {}
		});

		latestViewPager.setAdapter(tmlnAdapter);
		rankingViewPager.setAdapter(rnkAdapter);
		appinfoWebView = (MoeMoeWebView) ((LinearLayout) findViewById(R.id.appinfo_webview_layout)).findViewById(R.id.moemoe_webview);
		mIndicator.setViewPager(latestViewPager);
		//PageViewのタイトルを更新する
		mIndicator.notifyDataSetChanged();
	}

	/**
	 * 新着とランキングの表示を切り替える
	 */
	public void changePageView(int titleId) {
		if(titleId == R.string.pname_latest_moe) {
			//新着アプリを表示
			rankingViewPager.setVisibility(View.INVISIBLE);
			mIndicator.setViewPager(latestViewPager);
			mIndicator.onPageSelected(latestViewPager.getCurrentItem());
			latestViewPager.setVisibility(View.VISIBLE);
		} else if(titleId == R.string.pname_ranking) {
			//ランキングを表示
			latestViewPager.setVisibility(View.INVISIBLE);
			mIndicator.setViewPager(rankingViewPager);
			mIndicator.onPageSelected(rankingViewPager.getCurrentItem());
			rankingViewPager.setVisibility(View.VISIBLE);
		}
		mIndicator.notifyDataSetChanged();
	}

	/**
	 * タイトルバーがタップされると背後のViewのクリックイベントが実行されるため
	 * 何もしない処理をタイトルバーのクリックイベントにセットする。
	 * このメソッドはレイアウトファイルで定義する。
	 * @param View view
	 */
	public void onClickEmpty(View view) {}

	/**
	 * 吹き出しが表示されているときのクリック処理。
	 * 吹き出しを閉じる。
	 * @param View view
	 */
	public void onClickMopuritan(View view) {
		balloon.openBalloon();
	}

	/**
	 * MoeMoeWebViewのリロード処理
	 * @param View view
	 */
	public void onClickWebViewReload(View view) {
		FrameLayout frameLayout = (FrameLayout) ((LinearLayout) view.getParent()).getParent();
		MoeMoeWebView webView = (MoeMoeWebView) frameLayout.findViewById(R.id.moemoe_webview);
		webView.reload();
	}

	/**
	 * バックボタン、戻るボタンがタップされたときの処理
	 */
	public void backView() {
		if(balloon.getOpened()) {
			balloon.closeBalloon();
			return;
		}

		int tiitleId = 0;
		boolean appClose = false;

		switch (MoeMoeUtil.titleId) {
			case R.string.pname_latest_moe: {
				appClose = true;
				break;
			}
			case R.string.pname_ranking: {
				appClose = true;
				break;
			}
			case R.string.pname_app_info: {
				if(timeLinePageName == R.string.pname_latest_moe) {
					//新着萌えアプリへ戻る
					tiitleId = R.string.pname_latest_moe;
				} else if(timeLinePageName == R.string.pname_ranking) {
					//ランキングへ戻る
					tiitleId = R.string.pname_ranking;
				} else if(timeLinePageName == R.string.pname_mymoeapp) {
					//マイ萌えアプリへ戻る
					tiitleId = R.string.pname_mymoeapp;
				}

				MoeMoeUtil.setVisible(menuButton);
				MoeMoeUtil.setInvisible(backButton);
				MoeMoeUtil.setInvisible(appinfoWebView);
				break;
			}
			case R.string.pname_moplitan: {
				appClose = true;
				break;
			}
			case R.string.pname_mymoeapp: {
				appClose = true;
				break;
			}
			case R.string.pname_other: {
				appClose = true;
				break;
			}
			case R.string.pname_notice: {
				//その他画面へ戻る
				tiitleId = R.string.pname_other;

				MoeMoeUtil.setVisible(menuButton);
				MoeMoeUtil.setInvisible(backButton);
				MoeMoeUtil.setInvisible(singleWebView);
				break;
			}
			default: {
				//なんもしない
				break;
			}
		}

		if(appClose) {
			//アプリ終了確認吹き出し表示
			balloon.setBalloon(getString(R.string.balloon_close_app), Balloon.BALLOON_APP_CLOSE);
			return;
		}
		MoeMoeUtil.changeTitle(tiitleId);
	}

	final Handler handler = new Handler();
	private static boolean blinkFlag = true;
	private static int idolTime = 1000;
	private static final int IDOL_BASE_TIME = 3000;
	private static final int IDOL_RANDOM_TIME = 4500;
	private static final int BLINKTIME = 120;
	private Random rndm;

	/**
	 * もプリたんに瞬きをさせます
	 */
	private void blinkMopuritan() {
		final Timer timer = new Timer();

		final TimerTask task = new TimerTask() {
			@Override
			public void run() {
				rndm = new Random(new Date().getTime());
				//次に閉じるまでの時間
				if (rndm.nextInt(10) >= 8) {
					idolTime = BLINKTIME;
				} else {
					idolTime = IDOL_BASE_TIME + rndm.nextInt(IDOL_RANDOM_TIME);
				}

				handler.post(new Runnable() {
					public void run() {
						if (blinkFlag) {
							//目を閉じる
							mopuritan.setImageResource(R.drawable.mopuritan_blink);

							//閉じてから開くまでの時間
							idolTime = BLINKTIME;
						} else {
							//見開く
							mopuritan.setImageResource(R.drawable.mopuritan);
						}
					}
				});
				blinkFlag = (blinkFlag ? false : true);
				blinkMopuritan();
			}
		};
		timer.schedule(task, idolTime);
	}

	/**
	 * google playアプリを起動してアプリページを表示します
	 */
	public void showStore(boolean finish) {
		Intent intent = new Intent(Intent.ACTION_VIEW);
		intent.setData(Uri.parse(GOOGLE_PLAY_URL + APP_PACKAGE));
		startActivity(intent);
		if(finish) {
			finish();
		}
	}

	private final Handler pHandler = new Handler();
	private Thread timeOutProcess = new Thread();
	public boolean timeout = true;

	/**
	 * 読み込み中の表示
	 */
	public void loadProgress(final WebView webView) {
		MyLog.d(TAG, "タイムアウト処理実行します");

		final MoeMoeActivity activity = this;

		timeOutProcess = new Thread(new Runnable() {
			@Override
			public void run() {
				try {
					Thread.sleep(EnvironmentProvider.WEBVIEW_TIMEOUT);
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
				if(!appFinish) {
					if(timeout) {
						MyLog.e(TAG, "タイムアウトしましたよん。");
						pHandler.post(new Runnable() {
							public void run() {
								TimeLineFragment.webpageReloadView(activity, webView);
							}
						});
					} else {
						MyLog.d(TAG, "タイムアウトしませんでしたよん。");
					}
				}
			}
		});
		timeOutProcess.start();
	}

	/**
	 * アプリが最新バージョンか確認します。
	 * サーバから、リリースされているアプリの最新バージョン情報を取得します。
	 * 取得できなかった場合は端末がオフライン状態とみなして処理を中断します。
	 * @param budle
	 * @return boolean アプリが最新バージョンであればtrueを返します。
	 */
	private boolean checkLatestVersion(Bundle budle) {
		//JSonデータを取得
		ResultData versionRd = MoeMoeHttpClientManager.getVersion();
		if(versionRd != null) {
			String response = versionRd.value;
			//MyLog.d(TAG, "Version（JSONData） : " + response);

			try {
				//サーバから最新バージョン情報を取得する
				MoeMoeUtil.latestVersion = new JSONObject(response).getString("android");
			} catch (JSONException e) {
				e.printStackTrace();
			}
		} else {
			MyLog.e(TAG, "サーバのバージョンを確認できませんでした（現在のバージョン : " + MoeMoeUtil.getVersion() + "）");
		}

		if(!MoeMoeUtil.isLatestVersion()) {
			//最新バージョンのインストール催促
			balloon.setBalloon(getResources().getString(R.string.balloon_check_version), Balloon.BALLOON_VERSION);
			return false;
		} else {
			//通常処理
			getSupportLoaderManager().initLoader(0, budle, this);
			MoeMoeUtil.setVisible(progressLayout);
			return true;
		}
	}
}