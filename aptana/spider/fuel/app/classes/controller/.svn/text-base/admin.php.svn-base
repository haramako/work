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
			'クロールURL'=>array(
				'URL数'     => $this->get_val('SELECT count(*) val FROM spider_url'),
				'失敗数'    => $this->get_val('SELECT count(*) val FROM spider_url WHERE status="F"'),
				'作業中'    => $this->get_val('SELECT count(*) val FROM spider_url WHERE status="P"'),
				'待ち数'    => $this->get_val('SELECT count(*) val FROM spider_url WHERE status="" AND expire_at < unix_timestamp()'),
				'24H予定数' => $this->get_val('SELECT count(*) val FROM spider_url WHERE status="" AND expire_at < unix_timestamp()+60*60*24'),
			),
			'クロール済みアプリ数' => array(
				'iosアプリ' => $this->get_val('SELECT count(*) val FROM ios_apps'),
				'androidアプリ' => $this->get_val('SELECT count(*) val FROM android_apps'),
			),
			);

		$this->template->title = '統計';
		$this->template->content = View::forge( 'admin/statistics', array( 'data'=>$data ) );
	}
}
