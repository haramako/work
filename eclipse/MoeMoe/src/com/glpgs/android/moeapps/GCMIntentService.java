package com.glpgs.android.moeapps;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.glpgs.android.moeapps.http.MoeMoeHttpClientManager;
import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;
import com.google.android.gcm.GCMBaseIntentService;

public class GCMIntentService extends GCMBaseIntentService {
	private static final String TAG = "GCMIntentService";

	/**
	 * Google API project id registered to use GCM.
	 */
	public static final String SENDER_ID = "633163887710";

	public GCMIntentService() {
		super(SENDER_ID);
	}

	@Override
	public void onRegistered(Context context, String registrationId) {
		MyLog.d(TAG, "registration id : " + registrationId);
		MoeMoeUtil.GCMRegistId = registrationId;
		MoeMoeHttpClientManager.apiLogin();
	}

	@Override
	protected void onUnregistered(Context context, String registrationId) {
		sendMessage("C2DM Unregistered");
	}

	@Override
	public void onError(Context context, String errorId) {
		sendMessage("err:" + errorId);
	}

	@Override
	protected void onMessage(Context context, Intent intent) {
		MyLog.d(TAG, "Detect a push notification!");
		if(MoeMoeUtil.getPush()) {
			String str = intent.getStringExtra("message");
			Log.w("message:", str);
			// notifies user
			generateNotification(context, str);
		}
	}

	// 本体側に通知するなりなんなり
	private void sendMessage(String str) {
		MyLog.d(TAG, str);
	}

	/**
	 * Issues a notification to inform the user that server has sent a message.
	 */
	@SuppressWarnings("deprecation")
	private static void generateNotification(Context context, String message) {
		int icon = R.drawable.icon;
		long when = System.currentTimeMillis();
		NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
		Notification notification = new Notification(icon, message, when);
		String title = context.getString(R.string.app_name);
		Intent notificationIntent = new Intent(context, SplashActivity.class);
		// set intent so it does not start a new activity
		notificationIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
		PendingIntent intent = PendingIntent.getActivity(context, 0, notificationIntent, 0);
		notification.setLatestEventInfo(context, title, message, intent);
		notification.flags |= Notification.FLAG_AUTO_CANCEL;
		notificationManager.notify(0, notification);
	}

}