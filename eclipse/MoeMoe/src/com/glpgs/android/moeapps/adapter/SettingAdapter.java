package com.glpgs.android.moeapps.adapter;

import static com.glpgs.android.moeapps.config.EnvironmentProvider.GOOGLE_PLAY_URL;
import static com.glpgs.android.moeapps.config.EnvironmentProvider.MAIL_ADDRESS;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.BaseAdapter;
import android.widget.CompoundButton;
import android.widget.CompoundButton.OnCheckedChangeListener;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.ToggleButton;

import com.glpgs.android.moeapps.MoeMoeActivity;
import com.glpgs.android.moeapps.R;
import com.glpgs.android.moeapps.config.EnvironmentProvider;
import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;

public class SettingAdapter extends BaseAdapter implements OnItemClickListener {
	private static final String TAG = "SettingAdapter";

	private final String[] LISTTITNLE = {"プッシュ通知","レビューを書く","お問い合わせ","利用上の注意","バージョン"};

	private static final String WEBPATH = EnvironmentProvider.getWebBase();
	//private static final String PATH_FAQ = EnvironmentProvider.MENU_FAQ;
	private static final String PATH_NOTICE = EnvironmentProvider.MENU_NOTICE;

	private MoeMoeActivity activity;
	private LayoutInflater layoutInflater;

	public SettingAdapter() {
		if(activity != null) {
			return;
		}
		activity = MoeMoeUtil.activity;
		layoutInflater = (LayoutInflater) activity.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
	}

	@Override
	public int getCount() {
		return LISTTITNLE.length + 1;
	}

	@Override
	public Object getItem(int arg0) {
		return null;
	}

	@Override
	public long getItemId(int arg0) {
		return LISTTITNLE.length + 1;
	}

	@Override
	public boolean isEnabled(int position) {
		if(position == (LISTTITNLE.length) || position == (LISTTITNLE.length - 1)) {
			return false;
		}
		return true;
	}

	@Override
	public View getView(int position, View view, ViewGroup viewGroup) {
		//MyLog.d(TAG, "getView position : " + position);
		if (view != null) {
			return view;
		}

		View layout = layoutInflater.inflate(R.layout.moe_setting_cell, null);
		ImageView icon = (ImageView)layout.findViewById(R.id.setting_icon);
		TextView title = (TextView)layout.findViewById(R.id.setting_name);
		ToggleButton button;
		TextView version;
		ImageView arrow = (ImageView)layout.findViewById(R.id.setting_arrow);

		if (position == 0) {
			//プッシュ通知
			icon.setImageResource(R.drawable.icon_other_01);
			title.setText("プッシュ通知");
			button = (ToggleButton)layout.findViewById(R.id.setting_push);
			button.setChecked(MoeMoeUtil.getPush());
			button.setOnCheckedChangeListener(new OnCheckedChangeListener() {
				@Override
				public void onCheckedChanged(CompoundButton compoundbutton, boolean flag) {
					MoeMoeUtil.setPush(flag);
				}
			});
			button.setVisibility(View.VISIBLE);
		} else if (position == 1) {
			//レビューを書く
			icon.setImageResource(R.drawable.icon_other_02);
			title.setText("レビューを書く");
			arrow.setVisibility(View.VISIBLE);
		} /*else if (position == 2) {
			//よくあるご質問
			icon.setImageResource(R.drawable.icon_other_03);
			title.setText("よくあるご質問");
			arrow.setVisibility(View.VISIBLE);
		}*/ else if (position == 2) {
			//お問い合わせ
			icon.setImageResource(R.drawable.icon_other_04);
			title.setText("お問い合わせ");
			arrow.setVisibility(View.VISIBLE);
		} else if (position == 3) {
			//利用上の注意
			icon.setImageResource(R.drawable.icon_other_05);
			title.setText("利用上の注意");
			arrow.setVisibility(View.VISIBLE);
		} else if (position == 4) {
			//バージョン
			icon.setImageResource(R.drawable.icon_other_06);
			title.setText("バージョン");
			version = (TextView)layout.findViewById(R.id.setting_version);

			if(!EnvironmentProvider.isDevelopment()) {
				version.setText(MoeMoeUtil.getVersion());
			} else {
				version.setText(MoeMoeUtil.getVersion() + " (Debug Version)");
			}

			version.setVisibility(View.VISIBLE);
		} else if (position == 5) {
			//最下部の空白
			icon.setVisibility(View.INVISIBLE);
			title.setVisibility(View.INVISIBLE);
		}
		return layout;
	}

	@Override
	public void onItemClick(AdapterView<?> adapterView, View view, int position, long arg3) {
		//MyLog.d(TAG, TAG + ".onItemClick start!!");

		if (position == 0) {
			//プッシュ通知
		} else if (position == 1) {
			//レビューを書く
			Intent intent = new Intent(Intent.ACTION_VIEW);
			intent.setData(Uri.parse(GOOGLE_PLAY_URL + EnvironmentProvider.APP_PACKAGE));
			activity.startActivity(intent);
		}/* else if (position == 2) {
			//よくあるご質問
			activity.singleWebView.loadUrl(WEBPATH + PATH_FAQ);
			MoeMoeUtil.setVisible(activity.singleWebView);
			MoeMoeUtil.changeTitle(R.string.pname_notice);
		}*/ else if (position == 2) {
			//お問い合わせ
			MyLog.d(TAG, "メーラーを起動します");

			//既定のメーラーを起動
			Intent intent = new Intent();
			intent.setAction(Intent.ACTION_SENDTO);
			intent.setData(Uri.parse("mailto:" + MAIL_ADDRESS));
			intent.putExtra(Intent.EXTRA_SUBJECT, getString(R.string.mail_contact));
			intent.putExtra(Intent.EXTRA_TEXT, getString(R.string.mail_body));
			activity.startActivity(intent);
		} else if (position == 3) {
			//利用上の注意
			activity.singleWebView.loadUrl(WEBPATH + PATH_NOTICE);
			MoeMoeUtil.setVisible(activity.singleWebView);
			MoeMoeUtil.changeTitle(R.string.pname_notice);
		} else if (position == 4) {
			//バージョン
		}
	}

	private String getString(int id) {
		return MoeMoeUtil.activity.getResources().getString(id);
	}
}
