package com.glpgs.android.moeapps.adapter;

import java.util.ArrayList;
import java.util.List;

import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentPagerAdapter;

import com.glpgs.android.moeapps.ScreenshotActivity;
import com.glpgs.android.moeapps.flagment.ScreenshotFragment;
import com.glpgs.android.moeapps.util.MyLog;

public class ScreenshotAdapter extends FragmentPagerAdapter {
	private static final String TAG = "ScreenshotAdapter";

	private int mCount = 1;
	private final List<ScreenshotFragment> fragments = new ArrayList<ScreenshotFragment>();
	private String[] screenshotUrlArray;

	public static ScreenshotAdapter newInstance(ScreenshotActivity activity, String[] urlArray) {
		ScreenshotAdapter adapter =  new ScreenshotAdapter(activity.getSupportFragmentManager());
		adapter.screenshotUrlArray = urlArray;
		adapter.setCount(adapter.screenshotUrlArray.length);
		return adapter;
	}

	public ScreenshotAdapter(FragmentManager fm) {
		super(fm);
	}

	@Override
	public Fragment getItem(int position) {
		MyLog.d(TAG, "getItem position : " + position);

		String imageUrl = screenshotUrlArray[position];

		if(imageUrl == null || imageUrl.equals("")) {
			return null;
		}

		//配列数が等しということはページが足りないことを意味する
		if(fragments.size() == position) {
			fragments.add(ScreenshotFragment.newInstance(position, imageUrl));
		}

		return fragments.get(position);
	}

	@Override
	public int getCount() {
		return mCount;
	}

	public void setCount(int count) {
		mCount = count;
	}
}