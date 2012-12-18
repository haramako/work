<?php

class Controller_Admin_Base extends Controller_Template
{
	public $template = 'admin/template';

	public function before()
	{
		parent::before();
		
		// キャッシュが効かないようにする
		$this->response->set_header('Cache-Control', 'no-cache, max-age=0');
	}
}

