package com.glpgs.android.moeapps.adapter;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import android.content.Context;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentTransaction;
import android.view.View;
import android.webkit.WebSettings;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.SimpleAdapter;

import com.glpgs.android.moeapps.MoeMoeActivity;
import com.glpgs.android.moeapps.R;
import com.glpgs.android.moeapps.config.EnvironmentProvider;
import com.glpgs.android.moeapps.flagment.SettingFragment;
import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;

public class MenuAdapter implements OnItemClickListener {
	private static final String TAG = "MenuAdapter";

	private static final String WEBPATH = EnvironmentProvider.getWebBase();
	private static final String PATH_MOPURITAN = EnvironmentProvider.MENU_MOPURITAN;
	private static final String PATH_MYMOE_APP = EnvironmentProvider.MENU_MYMOE_APP;

	private List<Map<String, Object>> listData = new ArrayList<Map<String, Object>>();
	private SimpleAdapter menuAdp;

	private MoeMoeActivity activity;

	private FragmentTransaction fragmentTransaction = null;
	private SettingFragment stgFragment = null;
	private Fragment lastFlagment;

	//現在選択されているメニューの番号
	public int prev_pos = 0;

	public MenuAdapter() {
		if(activity != null) {
			return;
		}
		activity = MoeMoeUtil.activity;
	}

	public SimpleAdapter init(Context context) {
		if (menuAdp != null) {
			return menuAdp;
		}

		listData.add(getMapData(R.drawable.menu_icon_new, "新着萌えアプリ"));
		listData.add(getMapData(R.drawable.menu_icon_rank, "ランキング"));
		listData.add(getMapData(R.drawable.menu_icon_moe, "もプリたんについて"));
		listData.add(getMapData(R.drawable.menu_icon_heart, "マイ萌えアプリ"));
		listData.add(getMapData(R.drawable.menu_icon_stg, "その他"));

		menuAdp = new SimpleAdapter(context, listData, R.layout.menu_cell,
				new String[] {
					item.icon.name,
					item.title.name },
				new int[] {
					item.icon.id,
					item.title.id
				});

		fragmentTransaction = activity.getSupportFragmentManager().beginTransaction();
		stgFragment = new SettingFragment();
		return menuAdp;
	}

	@Override
	public void onItemClick(AdapterView<?> adapterView, View view, int position, long arg3) {
		//MyLog.d(TAG, TAG + ".onItemClick start! position : " + position);

		if(MoeMoeActivity.slideMenu.getStarted()) {
			//メニューの開閉中のときは処理しない
			return;
		}

		if (prev_pos != position || position == 3 || MoeMoeUtil.getVisibility(MoeMoeActivity.appinfoWebView) == View.VISIBLE) {
			prev_pos = position;
			//アプリ情報からの遷移かどうか判定
			MoeMoeUtil.setInvisible(MoeMoeActivity.appinfoWebView);

			if (position == 0 && activity.timeLinePageName != R.string.pname_latest_moe) {
				MyLog.d(TAG, "新着アプリキターーーー");
				activity.changePageView(R.string.pname_latest_moe);
			} else if (position == 1 && activity.timeLinePageName != R.string.pname_ranking) {
				MyLog.d(TAG, "ランキングキターーーー");
				activity.changePageView(R.string.pname_ranking);
			} else if (position == 2) {
				MyLog.d(TAG, "もプリたんについてキターーーー");
				activity.singleWebView.loadUrl(WEBPATH + PATH_MOPURITAN);
			} else if (position == 3) {
				MyLog.d(TAG, "マイ萌えアプリキターーーー");
				activity.MyMoeWebView.getSettings().setCacheMode(WebSettings.LOAD_DEFAULT);
				activity.MyMoeWebView.loadUrl(WEBPATH + PATH_MYMOE_APP);
			} else if (position == 4) {
				MyLog.d(TAG, "その他キターーーー");
				if(lastFlagment != stgFragment) {
					fragmentTransaction.add(R.id.setting_view, stgFragment);
					lastFlagment = stgFragment;
					fragmentTransaction.commit();
				}
			}
		}

		if(MoeMoeActivity.settingView.getVisibility() == View.VISIBLE) {
			MoeMoeUtil.setInvisible(MoeMoeActivity.settingView);
		}

		if(position == 0 || position == 1) {
			MoeMoeUtil.setInvisible(activity.MyMoeWebView);
			MoeMoeUtil.setInvisible(activity.singleWebView);
			if(position == 0) {
				MoeMoeUtil.changeTitle(R.string.pname_latest_moe);
			} else if(position == 1) {
				MoeMoeUtil.changeTitle(R.string.pname_ranking);
			}
		} else if(position == 2) {
			MoeMoeUtil.changeTitle(R.string.pname_moplitan);
			MoeMoeUtil.setVisible(activity.singleWebView);
		} else if(position == 3) {
			MoeMoeUtil.changeTitle(R.string.pname_mymoeapp);
			MoeMoeUtil.setVisible(activity.MyMoeWebView);
			MoeMoeUtil.setInvisible(activity.singleWebView);
		} else if(position == 4) {
			MoeMoeUtil.changeTitle(R.string.pname_other);
			MoeMoeUtil.setVisible(MoeMoeActivity.settingView);
			MoeMoeUtil.setInvisible(activity.singleWebView);
		}
		MoeMoeUtil.setInvisible(MoeMoeActivity.backButton);
		MoeMoeUtil.setVisible(MoeMoeActivity.menuButton);

		//メニュー開閉イベントを呼ぶ
		MoeMoeActivity.slideMenu.callIvent();
	}

	private Map<String, Object> getMapData(int menuIcon, String menuName) {
		Map<String, Object> map = new HashMap<String, Object>();
		map.put(item.icon.name, menuIcon);
		map.put(item.title.name, menuName);

		return map;
	}

	private enum item {
		icon("menu_image", R.id.menu_icon), title("menu_name", R.id.menu_name);

		private final String name;
		private final int id;

		item(String item_name, int item_id) {
			this.name = item_name;
			this.id = item_id;
		}
	}
}
