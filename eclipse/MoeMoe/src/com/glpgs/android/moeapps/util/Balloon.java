package com.glpgs.android.moeapps.util;

import java.util.Date;
import java.util.Random;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.glpgs.android.moeapps.MoeMoeActivity;
import com.glpgs.android.moeapps.R;

/**
 * @author hiroyuki.takaya
 *
 */
public final class Balloon {
	private static final String TAG = "Balloon";

	public static final int BALLOON_VERSION = 1;
	public static final int BALLOON_APP_CLOSE = 2;
	public static final int BALLOON_REVIEW = 3;

	private static MoeMoeActivity moeMoeActivity;
	private static LayoutInflater inflater;
	private static Context context;

	//吹き出しのレイアウト
	private static LinearLayout balloonCoverView;
	//吹き出しのレイアウト
	private static LinearLayout balloonButtonView;
	//もプリたんと吹き出しのレイアウト
	private static LinearLayout mopuritanBalloon;
	//『うん』『やめとく』ボタンのレイアウト
	private LinearLayout balloonButtonLayout1;
	//『分かった』ボタンのレイアウト
	private LinearLayout balloonButtonLayout2;
	//吹き出しのコメント
	private TextView comment;
	private Button okButton;
	private Button confirmButton;
	private Button closeButton;

	private int balloonType1 = 0;
	private int balloonType2 = 1;
	private LinearLayout[] balloons = new LinearLayout[(balloonType2+1)];

	private static Animation openBlln;
	private static Animation closeBlln;

	private boolean viewBalloon = false;
	private boolean viewQuestion = false;
	private boolean versionBalloon = false;

	private Balloon() {}

	public static Balloon getInstance(MoeMoeActivity activity) {
		context = activity.getApplicationContext();

		Balloon balloon = new Balloon();
		moeMoeActivity = activity;
		inflater = moeMoeActivity.getLayoutInflater();
		balloon.init();

		return balloon;
	}


	/**
	 * 最新バージョン通知用吹き出しの状態を返します。
	 * 表示されていればtrue、非表示であればfalse。
	 * @return boolean versionBalloon
	 */
	public boolean getShowVersionBalloon() {
		return versionBalloon;
	}


	/**
	 * 吹き出しの初期化を行います。
	 */
	private void init() {
		comment = (TextView) moeMoeActivity.findViewById(R.id.comment);

		mopuritanBalloon =  (LinearLayout) moeMoeActivity.findViewById(R.id.mopuritan_balloon);
		balloonCoverView = (LinearLayout) moeMoeActivity.findViewById(R.id.mopuritan_cover_view);
		balloonButtonView = (LinearLayout) moeMoeActivity.findViewById(R.id.balloon_btn_view);
		balloonButtonLayout1 = (LinearLayout) inflater.inflate(R.layout.moe_main_mopuritan_btn1, null);
		balloonButtonLayout2 = (LinearLayout) inflater.inflate(R.layout.moe_main_mopuritan_btn2, null);
		balloons[0] = balloonButtonLayout1;
		balloons[1] = balloonButtonLayout2;

		//もプリたんをタップしたら吹き出しを表示する
		ImageView mopuritan = (ImageView) moeMoeActivity.findViewById(R.id.character);
		mopuritan.setVisibility(View.VISIBLE);
		mopuritan.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				openBalloon();
			}
		});

		okButton = (Button) balloonButtonLayout1.findViewById(R.id.btn_ok);
		closeButton = (Button) balloonButtonLayout1.findViewById(R.id.btn_cancel);
		confirmButton = (Button) balloonButtonLayout2.findViewById(R.id.btn_confirm);

		OnClickListener onClick = new OnClickListener() {
			@Override
			public void onClick(View v) {
				closeBalloon();
			}
		};

		confirmButton.setOnClickListener(onClick);
		closeButton.setOnClickListener(onClick);

		//balloonButtonView.addView(balloons[balloonType2]);
		//MoeMoeActivity.mopuritanView.addView(MoeMoeActivity.mopuritanLayout);

		//吹き出しを表示するときと閉じるときのアニメーションを作成
		openBlln = AnimationUtils.loadAnimation(context, R.anim.dialog_enter);
		closeBlln = AnimationUtils.loadAnimation(context, R.anim.dialog_exit);
	}

	/**
	 * もプリたんの吹き出しを表示する。
	 * 既に表示されている場合は閉じる。
	 */
	public void openBalloon() {
		if(!viewBalloon) {
			setBalloon();
			visibleBalloon();
		} else if(!viewQuestion) {
			closeBalloon();
		}
	}

	/**
	 * もプリたんの吹き出しを表示する
	 */
	private void visibleBalloon() {
		if(!viewBalloon) {
			MoeMoeUtil.setVisible(balloonCoverView);
			mopuritanBalloon.startAnimation(openBlln);
			MoeMoeUtil.setVisible(mopuritanBalloon);
			viewBalloon = true;
		}
	}

	/**
	 * もプリたんの吹き出しを閉じる
	 */
	public void closeBalloon() {
		if(viewBalloon) {

			//既にボタンがあれば削除する
			int length = balloons.length;
			for(int i = 0; i < length; i++) {
				if(balloonButtonView.indexOfChild(balloons[i]) != -1) {
					balloonButtonView.removeView(balloons[i]);
				}
			}

			mopuritanBalloon.startAnimation(closeBlln);
			MoeMoeUtil.setInvisible(mopuritanBalloon);
			viewBalloon = false;
			viewQuestion = false;
			MoeMoeUtil.setInvisible(balloonCoverView);
		}
	}

	private static final String[] COMMENTS = {
		"今日も萌えアプリをじゃんじゃん紹介しちゃいますよ!",
		"季節の変わり目って天気が崩れて嫌ですよね。髪の毛がめちょ～ってなります。",
		"お疲れですか？萌えアプリで癒されましょう!",
		"ふんふんふふんふん～♪ドナドナドーナードーナー・・・・",
		"萌え、ってなんなんでしょうか。興奮するくらいかわいいと思えることですか？",
		"もプリたんって呼ばれるの最初は慣れなかったのですが、何度も呼ばれるうちに慣れてしまいました。",
		"無性にクレープが食べたくなるときってありませんか？",
		"Twitterクライアントアプリっていっぱいありすぎてどれがいいのよくかわかりません。",
		"ドロイド君って実は女の子かもしれない！\nだとしたら君って呼んだら失礼ですよね。",
		"なんだか味噌カレー牛乳ラーメンが食べたくなってきちゃいました。",
		"最近のマイブームはジャスミンの入浴剤を入れたお風呂に入ることです。あまりに気持ちよくて、お風呂で眠ってしまいそうになります。",
		"アロマは柑橘系が好きです。オレンジがいい感じです。",
		"二の腕ぷにぷに！運動しないとっ。",
		"本はやっぱり恋愛ものが好きですね。まぁ本と言ってもラノベなんですけどね。",
		"ドラッカーって最初ロボットかなにかの名前かと思ってました。",
		"おにいちゃん、って呼んだほうがいいですか？\nそれともお姉さん？弟、妹？\n・・・えっ！お父さん？！",
		"私もツイッターやってますよ！",
		"ピンクの丸いボタンは\"萌えボタン\"と言って、\n萌えボタンを押すとお気に入りとして\"マイ萌えアプリ\"に登録されます。",
		"昨日、カモをしょったネギがドヤ顔で歩いている夢をみました。ネギに顔なんて無いのに・・・、意味不明です。",
		"ダイエットを意識すればするほどお腹が空いてしまうんですよね。気付くと普段よりお菓子食べてたり・・・。",
		"幼馴染って女の子同士でもちゃんとあるから！",
		"なんか社員の人がそれとなくガンダムネタを教えようとしてくるんです。",
		"この間学校でウェブサイトを作ったら、90年代な雰囲気って言われました。これって褒められてる？",
		"電波ゆんゆん♪\n・・・こんな言葉どこで覚えたんだろう？",
		"暗いところは苦手ですっ＞＜\n真っ暗だと眠れません～。",
		"お土産で貰ったリコリスのグミが不味くて不味くて、なんであんな食べ物がこの世に存在するのか一時間位考えてしまいました。",
		"読書もするけど、皆とお話しするほうが楽しいな！",
		"会社のトイレの張り紙に『男女禁制』って書いてあったけど・・・どうゆうこと？",
		"┌（┌ ＾o＾）┐ﾎﾓｫ\nってかわいいよね、って友達に話したら引かれました・・・。\nかわいいと思うんだけどなぁ。",
		"でつ\n有名な犬に見えるらしいですよ。"};

	/**
	 * もプリたんの吹き出しのコメントをセットする
	 */
	public void setBalloon() {
		Random rndm = new Random(new Date().getTime());
		comment.setText(COMMENTS[rndm.nextInt(COMMENTS.length)]);

//		if(rndm.nextInt(COMMENTS.length) == (COMMENTS.length-1)) {
//			balloonButtonView.addView(balloons[balloonType2]);
//			viewQuestion = true;
//		}
	}

	/**
	 * もプリたんの吹き出しのコメントをセットする
	 */
	public void setBalloon(String str, final int type) {
		if(viewBalloon) {
			if(type == 2) {
				closeBalloon();
			}
			return;
		}

		comment.setText(str);

		//バージョンアップ確認
		if(type == 1) {
			versionBalloon = true;
			balloonButtonView.addView(balloons[balloonType1]);
			okButton.setText(moeMoeActivity.getString(R.string.balloon_btn_ok2));
			closeButton.setText(moeMoeActivity.getString(R.string.balloon_btn_cancel2));

			okButton.setOnClickListener(new OnClickListener() {
				@Override
				public void onClick(View v) {
					moeMoeActivity.showStore(true);
				}
			});

			closeButton.setOnClickListener(new OnClickListener() {
				@Override
				public void onClick(View v) {
					closeBalloon();
					moeMoeActivity.finish();
				}
			});

		//アプリ終了確認かレビュー催促
		} else if(type == 2 || type == 3) {
			balloonButtonView.addView(balloons[balloonType1]);
			if(type == 2) {
				okButton.setText(moeMoeActivity.getString(R.string.balloon_btn_ok1));
			} else if(type == 3) {
				okButton.setText(moeMoeActivity.getString(R.string.balloon_btn_ok3));
			}
			closeButton.setText(moeMoeActivity.getString(R.string.balloon_btn_cancel1));

			okButton.setOnClickListener(new OnClickListener() {
				@Override
				public void onClick(View v) {
					closeBalloon();
					if(type == 2) {
						moeMoeActivity.finish();
					} else if(type == 3) {
						moeMoeActivity.showStore(false);
					}
				}
			});

			closeButton.setOnClickListener(new OnClickListener() {
				@Override
				public void onClick(View v) {
					closeBalloon();
				}
			});

		//アプリのレビューの催促
		} else {
			visibleBalloon();
			return;
		}
		viewQuestion = true;
		visibleBalloon();
	}

	/**
	 * 吹き出しの状態を返します。
	 * 表示していればtrue、表示されていなければfalseを返します。
	 * @return
	 */
	public boolean getOpened() {
		return viewBalloon;
	}
}
