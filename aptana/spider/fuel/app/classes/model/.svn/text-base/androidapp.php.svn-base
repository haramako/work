<?php

class Model_Androidapp extends Orm\Model
{
	protected static $_table_name = 'android_apps';
	
	protected static $_properties = array(
		'id',
		'app_id',
		'title',
		'author',
		'icon',
		'screenshot' =>array('data_type'=>'serialize', 'default'=>array() ),
		'description',
		'release_date',
		'price',
		'category',
		'release_date',
		'has_face',
		'is_japanese',
		'download_num',
		'rate',
		'tag' =>array( 'default'=>'' ),
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
			'events' => array('before_save', 'after_save', 'after_load'),
		),
	);

}
