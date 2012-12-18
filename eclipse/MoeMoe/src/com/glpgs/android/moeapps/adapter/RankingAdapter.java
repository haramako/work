package com.glpgs.android.moeapps.adapter;

import static com.glpgs.android.moeapps.config.EnvironmentProvider.RANKING_POPULAR;
import static com.glpgs.android.moeapps.config.EnvironmentProvider.RANKING_MOE;

import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentPagerAdapter;

import com.glpgs.android.moeapps.flagment.RankingFragment;

public  class RankingAdapter extends FragmentPagerAdapter {
	private static final String TAG = "RankingAdapter";

	private static final String[] RANKINGTITLE = new String[] { "人気", "萌え"};
	private static final String[] RANKING_PATH = new String[] {RANKING_POPULAR, RANKING_MOE};

	public int mCount = RANKINGTITLE.length;

	public RankingAdapter(FragmentManager fm) {
		super(fm);
	}

	@Override
	public CharSequence getPageTitle(int position) {
		return RANKINGTITLE[position % mCount];
	}

	@Override
	public Fragment getItem(int position) {
		return RankingFragment.newInstance(RANKING_PATH[position % mCount]);
	}

	@Override
	public int getCount() {
		return mCount;
	}

	public void setCount(int count) {
		mCount = count;
		notifyDataSetChanged();
	}
}