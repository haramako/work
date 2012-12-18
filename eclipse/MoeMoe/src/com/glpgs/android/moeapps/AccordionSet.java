package com.glpgs.android.moeapps;

import android.graphics.Color;
import android.os.Handler;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.animation.DecelerateInterpolator;
import android.widget.Button;
import android.widget.LinearLayout;

import com.glpgs.android.moeapps.util.MoeMoeUtil;
import com.glpgs.android.moeapps.util.MyLog;

public class AccordionSet {
	private static final String TAG = "AccordionSet";

	private Button _btn;
	private LinearLayout _content;
	private Handler _handler;
	private Thread _thread;
	//メニューが開いているか
	private boolean _opened = false;
	//メニュー開閉処理が実行中か
	private boolean _started = false;
	private int _startTime;

	private int easeTime = 500;
	private int baseAlpha = 160;
	private float current = 0.0f;
	private float alpha = 0.0f;

	private DecelerateInterpolator mInterpolator = new DecelerateInterpolator();

	public AccordionSet(Button btn, LinearLayout content) {
		_btn = btn;
		_content = content;
		_handler = new Handler();
		_btn.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				callIvent();
			}
		});
	}

	/**
	 * メニューの開閉処理が実行状態を返します。
	 * 実行中はtrue、実行していないときはfalse。
	 * @return boolean _started
	 */
	public boolean getStarted() {
		return _started;
	}

	/**
	 * メニューの開閉状態を返します。
	 * 開いていればtrue、閉じていればfalse。
	 * @return boolean _opened
	 */
	public boolean getOpened() {
		return _opened;
	}

	private void makeThread() {
		_thread = new Thread(new Runnable() {
			public void run() {

				int diff = (int) System.currentTimeMillis() - _startTime;
				float interpolation = 0;

				while (easeTime > diff) {
					interpolation = mInterpolator.getInterpolation((float) diff / (float) easeTime);
					if (!_opened) {
						current = MoeMoeUtil.slideX * interpolation;
						alpha = baseAlpha * interpolation;
					} else {
						current = MoeMoeUtil.slideX - MoeMoeUtil.slideX * interpolation;
						alpha = baseAlpha - baseAlpha * interpolation;
					}

					threadFunc();
					diff = (int) System.currentTimeMillis() - _startTime;
				}

				_opened = (_opened == true ? false : true);
				_started = false;
				_handler.post(new Runnable() {
					public void run() {
						if(!_opened) {
							MoeMoeActivity.coverLayout.setVisibility(View.INVISIBLE);
						}
					}
				});
			}
		});
	}

	private void threadFunc() {
		_handler.post(new Runnable() {
			public void run() {
				_content.setPadding((int)-current, 0, (int)current, 0);
				MoeMoeActivity.coverLayout.setBackgroundColor(Color.argb((int)alpha, 0, 0, 0));
			}
		});
		try {
			Thread.sleep(1);
		} catch (InterruptedException e) {}
	}

	public void deleteAccordion() {
		_btn.setOnClickListener(null);
		_btn = null;
		_content = null;
	}

	public void callIvent() {
		if(_started) {
			return;
		} else {
			_started = true;
		}

		if(!_opened) {
			MyLog.d(TAG, "Opening Menu");
			MoeMoeActivity.coverLayout.setVisibility(View.VISIBLE);
		} else {
			MyLog.d(TAG, "Closing Menu");
		}

		_startTime = (int) System.currentTimeMillis();

		if (_thread == null || !_thread.isAlive()) {
			_thread = null;
			makeThread();
			_thread.start();
		}
	}
}
