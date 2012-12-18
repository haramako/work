package com.glpgs.android.moeapps.util;

import android.util.Log;

import com.glpgs.android.moeapps.config.EnvironmentProvider;

public final class MyLog {
	private static final boolean LOG = EnvironmentProvider.LOG;

	public static void i(String tag, String msg) {
		if(LOG) Log.i(tag, msg);
	}

	public static void d(String tag, String msg) {
		if(LOG) Log.d(tag, msg);
	}

	public static void e(String tag, String msg) {
		if(LOG) Log.e(tag, msg);
	}
}
