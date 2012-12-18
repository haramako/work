<?php

namespace Fuel\Migrations;

class Create_users
{
	public function up()
	{
		// ユーザー情報
		\DBUtil::create_table('users', array(
			'id' => array('constraint' => 11, 'type' => 'int', 'auto_increment' => true),
			'uiid' => array('constraint' => 64, 'type' => 'varchar' ),
			'platform' => array('constraint' => 16, 'type' => 'varchar' ),
			'push_token' => array('constraint' => 255, 'type' => 'varchar' ),
			'option'=>array( 'constraint'=>255, 'type'=>'varchar', 'default'=>'{}' ),
			'created_at' => array('constraint' => 11, 'type' => 'int' ),
			'updated_at' => array('constraint' => 11, 'type' => 'int' ),
		), array('id'));
		\DBUtil::create_index( 'users', 'uiid' );

		// アプリ情報
		\DBUtil::create_table('applis', array(
			'id' => array('constraint' => 11, 'type' => 'int', 'auto_increment' => true),
			'platform' => array('constraint' => 8, 'type' => 'varchar'),
			'original_id' => array('constraint' => 255, 'type' => 'varchar'),
			'title' => array('constraint' => 255, 'type' => 'varchar'),
			'author' => array('constraint' => 255, 'type' => 'varchar'),
			'icon' => array('constraint' => 255, 'type' => 'varchar'),
			'screenshot' => array('constraint' => 1024, 'type' => 'varchar'),
			'description' => array('type' => 'text'),
			'release_date' => array('constraint' => 11, 'type' => 'int'),
			'price' => array('constraint' => 11, 'type' => 'int'),
			'category' => array('constraint' => 64, 'type' => 'varchar'),
			'rate' => array('type' => 'float'),
			'moe' => array('constraint' => 11, 'type' => 'int', 'default'=>0),
			'view' => array('constraint' => 11, 'type' => 'int', 'default'=>0),
			'install' => array('constraint' => 11, 'type' => 'int', 'default'=>0 ),
			'status'=>array( 'constraint'=>1, 'type'=>'varchar', 'default'=>'' ),
			'created_at' => array('constraint' => 11, 'type' => 'int'),
			'updated_at' => array('constraint' => 11, 'type' => 'int'),

		), array('id'));
		\DBUtil::create_index( 'applis', array('platform','original_id'), null, 'unique' );
		\DBUtil::create_index( 'applis', array('platform','release_date'), null );
		\DBUtil::create_index( 'applis', array('platform','view') );
		
		// イメージ
		\DBUtil::create_table('images', array(
			'id' => array('constraint' => 11, 'type' => 'int', 'auto_increment' => true),
			'url' => array('constraint' => 255, 'type' => 'varchar' ),
			'feature' => array('constraint' => 255, 'type' => 'varchar' ),
			'width' => array('constraint' => 11, 'type' => 'int' ),
			'height' => array('constraint' => 11, 'type' => 'int' ),
		), array('id'));
		\DBUtil::create_index( 'images', 'url', null, 'unique' );

		// アプリごとの萌えボタンを押した情報
		\DBUtil::create_table('moe_histories', array(
			'appli_id' => array('constraint' => 11, 'type' => 'int'),
			'time_at' => array('constraint' => 11, 'type' => 'int' ),
			'count' => array('constraint' => 11, 'type' => 'int'),
		), array('appli_id','time_at'));
		\DBUtil::create_index( 'moe_histories', array('time_at','appli_id'), null, 'unique' );

		// ユーザーごとの萌えボタンを押した情報
		\DBUtil::create_table('moe_users', array(
			'user_id' => array('constraint' => 11, 'type' => 'int'),
			'appli_id' => array('constraint' => 11, 'type' => 'int'),
			'count' => array('constraint' => 11, 'type' => 'int'),
			'updated_at' => array('constraint' => 11, 'type' => 'int' ),
		), array('user_id','appli_id'));
		\DBUtil::create_index( 'moe_users', array('appli_id', 'user_id'), null, 'unique' );

		// アプリ詳細画面のページビュー
		\DBUtil::create_table('pv_histories', array(
			'appli_id' => array('constraint' => 11, 'type' => 'int'),
			'time_at' => array('constraint' => 11, 'type' => 'int' ),
			'count' => array('constraint' => 11, 'type' => 'int'),
		), array('appli_id','time_at'));
		\DBUtil::create_index( 'pv_histories', array('time_at','appli_id'), null, 'unique' );

		// インストールボタンを押した情報
		\DBUtil::create_table('install_logs', array(
			'id' => array('constraint' => 11, 'type' => 'int', 'auto_increment'=>true),
			'appli_id' => array('constraint' => 11, 'type' => 'int'),
			'user_id' => array('constraint' => 11, 'type' => 'int'),
			'created_at' => array('constraint' => 11, 'type' => 'int' )
		), array('id'));
		\DBUtil::create_index( 'install_logs', array('appli_id') );
		\DBUtil::create_index( 'install_logs', array('user_id','appli_id') );

		// 設定(KVS)の情報
		\DBUtil::create_table('kvs', array(
			'id' => array('constraint' => 11, 'type' => 'int', 'auto_increment' => true),
			'key' => array('constraint' => 64, 'type' => 'varchar' ),
			'val' => array('constraint' => 255, 'type' => 'varchar' ),
			'desc' => array('constraint' => 255, 'type' => 'varchar' ),
			'created_at' => array('constraint' => 11, 'type' => 'int' ),
			'updated_at' => array('constraint' => 11, 'type' => 'int' )
		), array('id'));
		\DBUtil::create_index( 'kvs', 'key', null, 'unique' );

		\Kvs::set( 'version.android', '1.0.0', 'androidのアプリバージョン' );
		\Kvs::set( 'version.ios', '1.0.0', 'iosのアプリバージョン' );
		\Kvs::set( 'spider.last_collect', -1, '最後にcollectした日時' );
	}

	public function down()
	{
		\DBUtil::drop_table('users');
		\DBUtil::drop_table('images');
		\DBUtil::drop_table('applis');
		\DBUtil::drop_table('moe_histories');
		\DBUtil::drop_table('moe_users');
		\DBUtil::drop_table('pv_histories');
		\DBUtil::drop_table('install_logs');
		\DBUtil::drop_table('kvs');
	}
}
