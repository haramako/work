<?php
class Controller_Admin_Appli extends Controller_Admin_Base
{
	public static $PER_PAGE = 100;

	/** 一覧 */
	public function action_index()
	{
		$page = Input::get('p',1);
		$platform = Input::get('platform');
		$text = Input::get('text');
		$show_deleted = Input::get('show_deleted');
		$order_by = Input::get('order_by','id');
		
		$query = Model_Appli::query()
			->order_by($order_by,'desc');
		if( $platform ) $query->where('platform',$platform);
		if( $text ) $query->where('title','like','%'.$text.'%');
		if( !$show_deleted ) $query->where('status','in',array('','W'));
		$max_page = ceil( $query->count() / self::$PER_PAGE );
		$applis = $query->limit(self::$PER_PAGE)->offset(($page-1)*self::$PER_PAGE)->get();

		$base_url = "admin/appli?platform={$platform}&text={$text}&show_deleted={$show_deleted}&order_by={$order_by}&p=%";

		$this->template->title = "アプリの一覧";
		$this->template->content = View::forge('admin/appli/index',
			array( 'applis'=>$applis, 'base_url'=>$base_url, 'page'=>$page, 'max_page'=>$max_page,
				'platform'=>$platform, 'text'=>$text, 'show_deleted'=>$show_deleted, 'order_by'=>$order_by ) );

	}

	/** 詳細 */
	public function action_view($id = null)
	{
		$data['appli'] = Model_Appli::find($id);

		is_null($id) and Response::redirect('admin/appli');

		$text = $data['appli']->description.$data['appli']->description;
		Spider_Collector::has_moe_word('');
		preg_match( Spider_Collector::$moe_regexp, $text, $match );
		if( $match ){
			$data['match'] = $match[0];
		}else{
			$data['match'] = '';
		}

		$this->template->title = "アプリの詳細";
		$this->template->content = View::forge('admin/appli/view', $data);

	}

	/** ajaxによる状態変更 */
	public function action_change_status($id)
	{
		$appli = Model_Appli::find($id);
		$appli->status = Input::get('val','');
		$appli->save();
		return 'ok';
	}

	/** ajaxによる状態変更 */
	public function action_ajax_update($id)
	{
		$appli = Model_Appli::find($id);
		$appli->status = Input::get('status','');
		$appli->save();
		return View::forge('admin/appli/_item', array( 'appli'=>$appli ) );
	}
}
