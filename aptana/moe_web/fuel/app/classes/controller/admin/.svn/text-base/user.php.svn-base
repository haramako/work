<?php
class Controller_Admin_User extends Controller_Admin_Base
{
	static public $PER_PAGE = 100;

	public function action_index()
	{
		$page = Input::get('p',1);
		$text = Input::get('text');
		
		$query = Model_User::query();
		if( $text) $query->where('uiid','LIKE','%'.$text.'%')->or_where('push_token','LIKE','%'.$text.'%')->or_where('ID','=',$text);
		$data['max_page'] = ceil($query->count()/self::$PER_PAGE);
		$data['users'] = $query->order_by('id','desc')->limit(self::$PER_PAGE)->offset(($page-1)*self::$PER_PAGE)->get();
		$data['base_url'] = "admin/user?text={$text}&p=%";
		$data['page'] = $page;
		$data['text'] = $text;
		
		$this->template->title = "ユーザーの一覧";
		$this->template->content = View::forge('admin/user/index', $data );
	}

	public function action_delete($id = null)
	{
		if ($user = Model_User::find($id))
		{
			$user->delete();
			Session::set_flash('success', 'Deleted appli #'.$id);
		}else{
			Session::set_flash('error', 'Could not delete appli #'.$id);
		}

		Response::redirect('admin/user');
	}

	public function action_view($id = null)
	{
		$user = Model_User::find($id);
		if( !$user ) return new HttpServerErrorException('cannot find user');
		
		$this->template->title = 'ユーザーの詳細';
		$this->template->content = View::forge('admin/user/view', array( 'user'=>$user ) );
	}

}
