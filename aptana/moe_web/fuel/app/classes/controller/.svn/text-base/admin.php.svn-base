<?php

class Controller_Admin extends Controller_Admin_Base
{
	private function get_val( $sql )
	{
		$result = DB::query($sql)->execute();
		return $result[0]['val'];
	}
	
	public function action_index()
	{
		$this->template->title = 'メイン';
		$this->template->content = View::forge( 'admin/index' );
	}

	public function action_statistics()
	{
		$data = array(
			'もぷりたんアプリ数' => array(
				'総数(削除含む)' => $this->get_val('SELECT count(*) val FROM applis'),
				'android'   => $this->get_val('SELECT count(*) val FROM applis WHERE platform="android" AND status = ""'),
				'ios'       => $this->get_val('SELECT count(*) val FROM applis WHERE platform="ios" AND status = ""'),
			),
			'ユーザー' => array(
				'総数'       => $this->get_val('SELECT count(*) val FROM users'),
				'android'    => $this->get_val('SELECT count(*) val FROM users WHERE platform="android"'),
				'ios'        => $this->get_val('SELECT count(*) val FROM users WHERE platform="ios"'),
			),
			);

		$this->template->title = '統計';
		$this->template->content = View::forge( 'admin/statistics', array( 'data'=>$data ) );
	}
}
