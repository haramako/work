<?php

/**
 * Kvsの内部で使用し、基本的には直接触らない
 */
class Model_Kvs extends Orm\Model
{
	public static $_table_name = 'kvs';
	
	protected static $_properties = array(
		'id',
		'key',
		'val',
		'desc',
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
	);
	
}


