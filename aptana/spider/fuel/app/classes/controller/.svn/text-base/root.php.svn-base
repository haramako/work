<?php

/**
 * ルートコントローラ.
 * 他のコントローラに所属しないアクションを担当する.
 */
class Controller_Root extends Controller
{
	/** インデックスページ */
	public function action_index()
	{
		return Response::redirect( 'admin' );
	}
	
	/** 404 Not Found */
	public function action_404()
	{
		return Response::forge( View::forge('root/404') );
	}

}
