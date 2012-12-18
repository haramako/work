<?php

class Controller_Admin_Kvs extends Controller_Admin_Base
{
	/** 一覧 */
	public function action_index()
	{
		$page = (int)Input::param('p',1);
		$text = Input::param('text');

		$query = Model_Kvs::find();
		if( $text ) $query->where('key','LIKE','%'.$text.'%')->or_where('val','LIKE','%'.$text.'%')->or_where('desc','LIKE','%'.$text.'%');;
		$max_page = ceil($query->count()/100);
		$rows = $query->limit(100)->offset(($page-1)*100)->get();

		$base_url = 'admin/kvs?p=%';

		$this->template->title = '設定の一欄';
		$this->template->content = View::forge('admin/kvs/index', array( 'rows'=>$rows, 'base_url'=>$base_url, 'page'=>$page, 'max_page'=>$max_page, 'text'=>$text ) );
	}

	/** ajaxによる変更 */
	public function action_ajax_update( $id )
	{
		$row = Model_Kvs::find( $id );
		$row->val = Input::param( 'val' );
		$row->save();
		return View::forge( 'admin/kvs/_item', array('row'=>$row) );
	}

	/** ajaxによる削除 */
	public function action_ajax_delete( $id )
	{
		$row = Model_Kvs::find( $id );
		$row->delete();
		return new Response('');
	}
	
}
