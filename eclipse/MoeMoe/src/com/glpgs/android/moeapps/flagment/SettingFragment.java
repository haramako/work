package com.glpgs.android.moeapps.flagment;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.ListView;

import com.glpgs.android.moeapps.MoeMoeActivity;
import com.glpgs.android.moeapps.R;
import com.glpgs.android.moeapps.adapter.SettingAdapter;
import com.glpgs.android.moeapps.util.MyLog;

/**
 * @author hiroyuki.takaya
 * その他画面
 */
public final class SettingFragment extends Fragment {
	private static final String TAG = "SettingFragment";

	public static SettingFragment newInstance(String content) {
		SettingFragment fragment = new SettingFragment();
		return fragment;
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
		MyLog.d(TAG, TAG + " onCreateView start!");

		LinearLayout layout = new LinearLayout(getActivity());

		if(savedInstanceState != null && savedInstanceState.getBoolean(TAG, false)) {
			return layout;
		}

		View v = inflater.inflate(R.layout.moe_setting_list, layout, false);
		layout.addView(v);

		ListView settingList = (ListView)v.findViewById(R.id.menu_setting_list);
		// フォーカスが当たらないようにする
		settingList.setItemsCanFocus(false);

		SettingAdapter adapter = new SettingAdapter();
		settingList.setAdapter(adapter);
		settingList.setOnItemClickListener(adapter);

		return layout;
	}

	@Override
	public void onSaveInstanceState(Bundle outState) {
		super.onSaveInstanceState(outState);
		outState.putBoolean(TAG, true);
	}
}
