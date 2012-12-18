<?php

class Controller_Base extends Controller_Template
{
	public $platform;
	public $user_id;
	public $uiid;
	public $user;

	/** リクエスト前 */
	public function before()
	{
		parent::before();
		
		$this->user_id = Session::get('user_id', 0);
		$this->uiid = Session::get('uiid', 0);
		$this->platform = Session::get('platform', 'android');

		// デフォルトではキャッシュを無効にする
		$this->response->set_header('Cache-Control', 'max-age=0');
	}

	/** キャッシュを使わないように指定する */
	public function no_cache()
	{
		$this->response->set_header('Cache-Control', 'private, no-cache, max-age=0', true);
	}

	/**
	 * セッションに保存されているユーザーを取得する.
	 * ログインしていない場合は、エラーを表示する。
	 *
	 * @return Model_User ログイン中のユーザー
	 */
	public function user()
	{
		if( $this->user ) return $this->user;
		$this->user = Model_User::find( $this->user_id );
		if( !$this->user ){
			throw new HttpServerErrorException('login required');
		}
		return $this->user;
	}
}
