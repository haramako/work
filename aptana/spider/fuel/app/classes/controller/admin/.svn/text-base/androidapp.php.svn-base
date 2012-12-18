<?php

class Controller_Admin_Androidapp extends Controller_Admin_Base
{
	public function action_index()
	{
		$page = (int)Input::param('p',1);
		$filter_has_face = Input::param('has_face');
		$filter_is_japanese = Input::param('is_japanese');
		$filter_text = Input::param('text');
		$order_by = Input::param('order_by','id');

		// アイテムリストを取得する
		$query = DB::select()->from('android_apps');
		if( $filter_has_face ) $query->where('has_face','T');
		if( $filter_is_japanese ) $query->where('is_japanese','T');
		if( $filter_text ){
			$query
				->where_open()
				->where('title','LIKE','%'.$filter_text.'%')
				->or_where('description','LIKE','%'.$filter_text.'%')
				->where_close();
		}
		$count_query = clone($query);
		$query->order_by($order_by,'desc')
			->limit(100)->offset(($page-1)*100);
		$apps = $query->execute()->as_array();

		// ページ数を取得する
		$count = $count_query->select(DB::expr('count(*)'))->execute();
		$max_page = ceil($count[0]['count(*)']/100);

		$base_url = 'admin/androidapp?'
			.($filter_has_face?'has_face=1&':'')
			.($filter_is_japanese?'is_japanese=1&':'')
			.($order_by?'order_by='.$order_by.'&':'')
			.($filter_text?'text='.$filter_text.'&':'')
			.'p=%';
		
		$bool_class = array( ''=>'icon-minus', 'T'=>'icon-certificate', 'F'=>'icon-remove' );
		foreach( $apps as &$app ){
			//$app['has_face_class'] = $bool_class[ $app['has_face'] ];
			//$app['is_japanese_class'] = $bool_class[ $app['is_japanese'] ];
			$app['release_date'] = substr($app['release_date'],0,10);
		}

		$this->template->title = '';
		$this->template->content = View::forge('admin/androidapp/index',
			array(
				'apps'=>$apps,
				'base_url'=>$base_url,
				'page'=>$page,
				'max_page'=>$max_page,
				'filter_has_face'=>$filter_has_face,
				'filter_is_japanese'=>$filter_is_japanese,
				'filter_text'=>$filter_text,
				'order_by'=>$order_by,
			) );
	}

	public function action_view($id)
	{
		$rows = DB::select()->from('android_apps')->where('id',$id)->execute();
		$app = $rows[0];
		// $app['screenshot'] = unserialize( $app['screenshot'] );
		
		$this->template->title = '';
		$this->template->content = View::forge('admin/androidapp/view', array('app'=>$app) );
	}

}
