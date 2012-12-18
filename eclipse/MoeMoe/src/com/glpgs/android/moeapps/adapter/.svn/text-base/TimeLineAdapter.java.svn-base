package com.glpgs.android.moeapps.adapter;

import static com.glpgs.android.moeapps.config.EnvironmentProvider.LATEST_ALL;
import static com.glpgs.android.moeapps.config.EnvironmentProvider.LATEST_FREE;
import static com.glpgs.android.moeapps.config.EnvironmentProvider.LATEST_PAID;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentPagerAdapter;

import com.glpgs.android.moeapps.flagment.TimeLineFragment;


public class TimeLineAdapter extends FragmentPagerAdapter {
	private static final String TAG = "TimeLineAdapter";

	private static final String[] TIMELINETITLE = new String[] {"全て", "有料", "無料"};
	private static final String[] TIMELINE_PATH = new String[] {LATEST_ALL, LATEST_PAID, LATEST_FREE};
	public int mCount = TIMELINETITLE.length;

	public TimeLineAdapter(FragmentManager fm) {
		super(fm);
	}

	@Override
	public CharSequence getPageTitle(int position) {
		return TIMELINETITLE[position % mCount];
	}

	@Override
	public Fragment getItem(int position) {
		//MyLog.d(TAG, "getItem position : " + position);
		return TimeLineFragment.newInstance(TIMELINE_PATH[position % mCount]);
	}

	@Override
	public int getCount() {
		return mCount;
	}

	public void setCount(int count) {
		mCount = count;
		notifyDataSetChanged();
	}

	@Override
	public int getItemPosition(Object object) {
		return POSITION_NONE;
	}
}