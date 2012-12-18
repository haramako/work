<?php

class Controller_Appli extends Controller_Base
{

	/**
	 * アプリの詳細画面.
	 * @param string $id アプリケーションのID
	 */
	public function action_view( $id )
	{
		
		$app = Model_Appli::find( $id );
		$app->increment_view();

		$app->description = preg_replace( '!<br/>|<br>!', "\n", $app->description );

		$this->template->title = 'appli/view';
        $this->template->content = View::forge('appli/view', array( 'app'=>$app ) )->auto_filter(false);;
	}

	/**
	 * 「萌え」ボタンが押された時のアクション.
	 * @param string $id アプリケーションのID
	 */
	public function action_moe( $id )
	{
		$this->no_cache();

		$user_id = Session::get( 'user_id' );
		if( !$user_id ) throw new HttpServerErrorException('login required');

		$user = Model_User::find( $user_id );

		$app = Model_Appli::find( $id );
		if( $app->increment_moe( $user ) ){
			Log::debug( "AFTER MOE!MOE! user_id={$user_id} app_id={$id}" );
			return 'ok';
		}else{
			Log::debug( "already moed. user_id={$user_id} app_id={$id}" );
			throw new HttpServerErrorException('already moed');
		}
	}

	/** スクリーンショットの一覧をJSONで返す */
	public function action_screenshot( $id )
	{
		$app = Model_Appli::find( $id );
		return json_encode( $app->screenshot );
	}

	/** インストール画面に飛ばす */
	public function action_install( $id )
	{
		$this->no_cache();

		$app = Model_Appli::find( $id );
		$user = Model_User::find( $this->user_id );
		if( $user ) $app->increment_install( $user );
		Response::redirect( $app->detail_url() );
	}
	
}
