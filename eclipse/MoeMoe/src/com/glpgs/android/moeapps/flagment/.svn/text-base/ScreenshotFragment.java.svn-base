package com.glpgs.android.moeapps.flagment;

import java.io.IOException;
import java.io.InputStream;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.entity.BufferedHttpEntity;
import org.apache.http.impl.client.DefaultHttpClient;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;

import com.glpgs.android.moeapps.R;
import com.glpgs.android.moeapps.ScreenshotActivity;
import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;

public class ScreenshotFragment extends Fragment implements Runnable {
	private static final String TAG = "ScreenshotFragment";

	private ScreenshotActivity activity;

	private ImageView imgView;
	LinearLayout progressLayout;
	private String imageUrl;
	private int pageNum;
	Bitmap bmp;

	public static ScreenshotFragment newInstance(int position, String url) {
		ScreenshotFragment fragment = new ScreenshotFragment();
		fragment.pageNum = position;
		fragment.imageUrl = url;
		return fragment;
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		if(savedInstanceState != null) {
			imageUrl = savedInstanceState.getString("image_url");
		}
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
		MyLog.d(TAG, TAG + " " + pageNum + " onCreateView start!");

		activity = (ScreenshotActivity)getActivity();
		LinearLayout layout = new LinearLayout(getActivity());

		View v = inflater.inflate(R.layout.screenshot, layout, false);
		layout.addView(v);

		progressLayout = (LinearLayout) v.findViewById(R.id.progress_view);
		imgView = (ImageView) v.findViewById(R.id.app_info_screenshot);

		if(bmp == null) {
			new Thread(this).start();
		} else {
			imgView.setImageBitmap(bmp);
			MoeMoeUtil.setInvisible(progressLayout);
		}

		return layout;
	}

	@Override
	public void onSaveInstanceState(Bundle outState) {
		MyLog.d(TAG, TAG + " onSaveInstanceState start!");
		super.onSaveInstanceState(outState);
		if(!imageUrl.equals("")) {
			outState.putString("image_url", imageUrl);
		}
	}

	@Override
	public void onActivityCreated(Bundle savedInstanceState) {
		super.onActivityCreated(savedInstanceState);
		MyLog.d(TAG, "onActivityCreated");
	}

	private static final Handler handler = new Handler();

	@Override
	public void run() {
		//bmp = setBitmap(imageUrl);
		bmp = setBitmap(imageUrl);

		if(bmp != null) {
			bmp = bmp.copy(Bitmap.Config.RGB_565, true);

			handler.post(new Runnable() {
				@Override
				public void run() {
					imgView.setImageBitmap(bmp);
					MoeMoeUtil.setInvisible(progressLayout);
				}
			});
		}
	}

	/**
	 * イメージURLをBitmapに変換します。
	 * @param JSONArray ja urlが格納されたJSON配列
	 */
	private Bitmap setBitmap(String imageURL) {
		HttpResponse httpResponse = null;
		BufferedHttpEntity bufHttpEntity = null;

		MyLog.d(TAG, "imageURL : " + imageURL);

		try {
			httpResponse = new DefaultHttpClient().execute(new HttpGet(imageURL));
			HttpEntity entity = httpResponse.getEntity();
			//InputStreamのバグ回避
			bufHttpEntity = new BufferedHttpEntity(entity);
		} catch (ClientProtocolException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}

		if (bufHttpEntity != null && httpResponse != null && httpResponse.getStatusLine().getStatusCode() == HttpStatus.SC_OK) {
		  InputStream in = null;
			try {
				in = bufHttpEntity.getContent();
			} catch (IllegalStateException e) {
				e.printStackTrace();
			} catch (IOException e) {
				e.printStackTrace();
			}

			return BitmapFactory.decodeStream(in);
		} else {
			return null;
		}
	}
}
