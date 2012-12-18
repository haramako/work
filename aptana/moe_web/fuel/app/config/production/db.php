<?php
/**
 * The production database settings.
 */

return array(
	'default' => array(
		'connection'  => array(
			'dsn'        => 'mysql:host=localhost;dbname=moe',
			'username'   => 'root',
			'password'   => 'hosopy1234',
		),
	),
	'spider' => array(
		'connection'  => array(
			'dsn'        => 'mysql:host=219.94.246.227;dbname=spider',
			'username'   => 'root',
			'password'   => 'hosopy1234',
		),
	),
);
