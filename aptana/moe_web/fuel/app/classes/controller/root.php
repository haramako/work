<?php

/**
 * ルートコントローラ.
 * 他のコントローラに所属しないアクションを担当する.
 */
class Controller_Root extends Controller_Base
{
	/** インデックスページ */
	public function action_index()
	{
		if( Fuel::$env == Fuel::PRODUCTION ) return '';
		return Response::forge( View::forge('root/index') );
	}
	
	/** 404 Not Found */
	public function action_404()
	{
		return Response::forge( View::forge('root/404') );
	}
	
	/**
	 * ユーザー登録を行う.
	 *
	 * 初回ログイン時に、アプリがIDを発行しサーバーに伝える。
	 * 成功した場合は、同時にログインも行われる。
	 *
	 * HTTPパラメータ: 
	 *   uiid: ユーザーを識別するためのID( プラットフォーム(android/ios)の区別をする文字列+UIID )
	 *   platform: プラットフォーム('android'か'ios')
	 *   push_toke: Push用のトークン
	 *   desc: 機種情報などの文字列
	 *   debug: (オプショナル)デバッグ端末かどうか( 存在する=デバッグ端末、存在しない=通常端末)
	 */
	public function action_regist()
	{
		// パラメータのチェック
		$uiid = Input::param('uiid');
		$platform = Input::param('platform');
		$push_token = Input::param('push_token','');
		$desc = Input::param('desc','');
		$debug = ( Input::param('debug',false) !== false );
		if( !$uiid ) return new Response('invalid parameter', 500 );
		if( !$platform ) return new Response('invalid parameter', 500 );
		// if( !$push_token ) return new Response('invalid parameter', 500 );

		// ユーザーがすでにいるかを確認する
		$user = Model_User::find()->where('uiid', $uiid )->get_one();
		if( $user ){
			// １回目の起動でpush_tokenが送られない問題対策
			if( $user->push_token != $push_token ){
				$user->push_token = $push_token;
				$user->register_to_baas();
				$user->save();
			}
			
			return new Response('uiid already exists', 401);
		}
			
		// ユーザーを作成する
		$user = new Model_User( array( 'uiid'=>$uiid, 'platform'=>$platform, 'push_token'=>$push_token, 'option'=>array('desc'=>$desc, 'debug'=>$debug ) ) );
		$user->register_to_baas();
		$user->save();

		// セッション情報の更新
		Session::set('user_id', $user->id );
		Session::set('platform', $user->platform );
		Session::set('uiid', $uiid );
		
		$this->no_cache();
		return 'regist ok';
	}
	
	/**
	 * ログインを行う.
	 *
	 * アプリから直接アクセスするだけなので、とくにパスワード等はなし、
	 * ユーザーが存在しないなら作成も行う.
	 *
	 * ログイン情報はセッションに記録され、萌えボタンが押された時などに参照される。
	 *
	 * HTTPパラメータ: 
	 *   uiid: ユーザーを識別するためのID( プラットフォーム(android/ios)の区別をする文字列+UIID )
	 */
	public function action_login()
	{
		// パラメータのチェック
		$uiid = Input::param('uiid');
		if( !$uiid ) return new Response('invalid parameter', 500 );

		// ユーザーを取得する
		$user = Model_User::find()->where('uiid', $uiid )->get_one();
		if( !$user ) return new Response('cannot find uiid', 500);

		// セッション情報の更新
		Session::set('user_id', $user->id );
		Session::set('platform', $user->platform );
		Session::set('uiid', $uiid );

		$this->no_cache();
		return 'login ok';
	}

	/**
	 * ユーザーのプッシュ通知のON/OFFなどのオプションを変更する.
	 *
	 * レスポンスとして、ユーザーのオプション情報のJSON文字列を返す
	 *
	 * HTTPパラメータ: 
	 *   push: プッシュ通知をするかどうか('true'=する, それ以外=しない)
	 */
	public function action_change_option()
	{
		$user = $this->user();
		
		$push = Input::param( 'push' );

		if( $push !== null ) $user->option->push = ($push == 'true');
		$user->save();

		$this->no_cache();
		return json_encode( $user->option );
	}

	/**
	 * バージョン情報などを取得する.
	 * レスポンスは、'{"android":"1.0.0", "ios":"1.0.0"}'のようなJSON文字列
	 */
	public function action_version()
	{
		$this->response->set_header('Cache-Control', 'no-cache; max-age=0'); // キャッシュは無効
		$json = array( 'android'=>Kvs::get('version.android'), 'ios'=>Kvs::get('version.ios') );
		
		$this->no_cache();
		return json_encode( $json );
	}
}
