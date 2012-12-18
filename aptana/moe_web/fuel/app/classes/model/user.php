<?php

class Model_User extends Orm\Model
{
	public static $_table_name = 'users';
	
	protected static $_properties = array(
		'id',
		'uiid',
		'platform',
		'push_token',
		'option'=>array('data_type'=>'json', 'default'=>array() ),
		'created_at',
		'updated_at',
	);

	protected static $_observers = array(
		'Orm\Observer_CreatedAt' => array(
			'events' => array('before_insert'),
			'mysql_timestamp' => false,
		),
		'Orm\Observer_UpdatedAt' => array(
			'events' => array('before_save'),
			'mysql_timestamp' => false,
		),
		'Orm\\Observer_Typing' => array(
			'events' => array('before_save', 'after_save', 'after_load')
		),
	);

	public function register_to_baas()
	{
		if( $this->push_token ){
			file_get_contents('http://baas.moe-apps.com/api/register_'.$this->platform.'/'.$this->uiid.'/'.$this->push_token);
		}
	}
}
