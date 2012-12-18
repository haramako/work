<?php
/**
 * The development database settings.
 */

return array(
	'default' => array(
		'connection'  => array(
			/*
			'dsn'        => 'mysql:host=moe-be;dbname=app_data',
			'username'   => 'root',
			'password'   => 'hosopy1234',
			*/
			'dsn'        => 'mysql:host=localhost;dbname=moe',
			'username'   => 'root',
			'password'   => '',
		),
	),

	'spider' => array(
		'connection'  => array(
			'dsn'        => 'mysql:host=moe-be;dbname=spider',
			'username'   => 'root',
			'password'   => 'hosopy1234',
		),
	),
);
