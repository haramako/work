<?php

namespace Fuel\Migrations;

class Init_database
{
	public function up()
	{
		// spider_urlテーブル
		\DBUtil::create_table('spider_url', array(
				'id' => array('constraint' => 11, 'type' => 'int', 'auto_increment'=>true ),
				'url' => array('constraint' => 255, 'type' => 'varchar' ),
				'status' => array('constraint' => 1, 'type' => 'varchar', 'default'=>'' ), // '':通常, 'F':失敗した, 'I':無視, 'P':作業中
				'expire_at' => array('constraint' => 11, 'type' => 'int', 'default'=>0 ),
			), array('id'));
		\DBUtil::create_index( 'spider_url', 'url', null, 'unique' );
		\DBUtil::create_index( 'spider_url', array( 'status', 'expire_at') );

		// imagesテーブル
		\DBUtil::create_table('images', array(
			'id' => array('constraint' => 11, 'type' => 'int', 'auto_increment' => true),
			'url' => array('constraint' => 255, 'type' => 'varchar' ),
			'feature' => array('constraint' => 255, 'type' => 'varchar' ),
			'width' => array('constraint' => 11, 'type' => 'int' ),
			'height' => array('constraint' => 11, 'type' => 'int' ),
		), array('id'));
		\DBUtil::create_index( 'images', 'url', null, 'unique' );
		
		// android_appsテーブル
		\DBUtil::create_table('android_apps', array(
			'id' => array('constraint' => 11, 'type' => 'int', 'auto_increment' => true),
			'app_id' => array('constraint' => 255, 'type' => 'varchar' ),
			'title' => array('constraint' => 255, 'type' => 'varchar' ),
			'author' => array('constraint' => 255, 'type' => 'varchar' ),
			'icon' => array('constraint' => 255, 'type' => 'varchar' ),
			'screenshot' => array('constraint' => 1024, 'type' => 'varchar' ),
			'description' => array('constraint' => 2048, 'type' => 'varchar' ),
			'release_date' => array('constraint' => 16, 'type' => 'varchar' ),
			'price' => array('constraint' => 11, 'type' => 'int' ),
			'category' => array('constraint' => 32, 'type' => 'varchar' ),
			'release_date' => array('constraint' => 16, 'type' => 'varchar' ),
			'has_face' => array('constraint' => 1, 'type' => 'varchar' ),
			'is_japanese' => array('constraint' => 1, 'type' => 'varchar' ),
			'download_num' => array('constraint' => 32, 'type' => 'varchar' ),
			'rate' => array('constraint' => 8, 'type' => 'varchar' ),
			'tag'=>array( 'constraint'=>255, 'type'=>'varchar', 'default'=>'' ),
			'created_at'=>array( 'constraint'=>11, 'type'=>'int' ),
			'updated_at'=>array( 'constraint'=>11, 'type'=>'int' ),
		), array('id'));
		\DBUtil::create_index( 'android_apps', 'app_id' );
		\DBUtil::create_index( 'android_apps', 'release_date' );
		\DBUtil::create_index( 'android_apps', 'updated_at' );
		\DBUtil::create_index( 'android_apps', 'created_at' );
		\DBUtil::create_index( 'android_apps', array( 'is_japanese', 'release_date' ) );
		\DBUtil::create_index( 'android_apps', array( 'has_face', 'release_date' ) );

		// ios_appsテーブル
		\DBUtil::create_table('ios_apps', array(
			'id' => array('constraint' => 11, 'type' => 'int', 'auto_increment' => true),
			'kind' => array('constraint' => 255, 'type' => 'varchar' ),
			'features' => array('constraint' => 255, 'type' => 'varchar' ),
			'supported_devices' => array('constraint' => 255, 'type' => 'varchar' ),
			'is_game_center_enabled' => array('constraint' => 255, 'type' => 'varchar' ),
			'screenshot_urls' => array('constraint' => 1024, 'type' => 'varchar' ),
			'ipad_screenshot_urls' => array('constraint' => 1024, 'type' => 'varchar' ),
			'artwork_url60' => array('constraint' => 255, 'type' => 'varchar' ),
			'artwork_url512' => array('constraint' => 255, 'type' => 'varchar' ),
			'artist_view_url' => array('constraint' => 255, 'type' => 'varchar' ),
			'artist_id' => array('constraint' => 255, 'type' => 'varchar' ),
			'artist_name' => array('constraint' => 255, 'type' => 'varchar' ),
			'price' => array('constraint' => 255, 'type' => 'varchar' ),
			'version' => array('constraint' => 255, 'type' => 'varchar' ),
			'description' => array('constraint' => 2048, 'type' => 'varchar' ),
			'genre_ids' => array('constraint' => 255, 'type' => 'varchar' ),
			'release_date' => array('constraint' => 255, 'type' => 'varchar' ),
			'seller_name' => array('constraint' => 255, 'type' => 'varchar' ),
			'currency' => array('constraint' => 255, 'type' => 'varchar' ),
			'genres' => array('constraint' => 255, 'type' => 'varchar' ),
			'bundle_id' => array('constraint' => 255, 'type' => 'varchar' ),
			'track_id' => array('constraint' => 11, 'type' => 'int' ),
			'track_name' => array('constraint' => 255, 'type' => 'varchar' ),
			'primary_genre_name' => array('constraint' => 255, 'type' => 'varchar' ),
			'primary_genre_id' => array('constraint' => 255, 'type' => 'varchar' ),
			'release_notes' => array('constraint' => 255, 'type' => 'varchar' ),
			'wrapper_type' => array('constraint' => 255, 'type' => 'varchar' ),
			'track_censored_name' => array('constraint' => 255, 'type' => 'varchar' ),
			'language_codes_iso2a' => array('constraint' => 255, 'type' => 'varchar' ),
			'file_size_bytes' => array('constraint' => 11, 'type' => 'int' ),
			'seller_url' => array('constraint' => 255, 'type' => 'varchar' ),
			'content_advisory_rating' => array('constraint' => 255, 'type' => 'varchar' ),
			'artwork_url100' => array('constraint' => 255, 'type' => 'varchar' ),
			'track_view_url' => array('constraint' => 255, 'type' => 'varchar' ),
			'track_content_rating' => array('constraint' => 255, 'type' => 'varchar' ),
			'has_face' => array('constraint' => 1, 'type' => 'varchar' ),
			'is_japanese' => array('constraint' => 1, 'type' => 'varchar' ),
			'tag'=>array( 'constraint'=>255, 'type'=>'varchar', 'default'=>'' ),
			'created_at'=>array( 'constraint'=>11, 'type'=>'int' ),
			'updated_at'=>array( 'constraint'=>11, 'type'=>'int' ),
		), array('id'));
		\DBUtil::create_index( 'ios_apps', 'track_id' );
		\DBUtil::create_index( 'ios_apps', 'release_date' );
		\DBUtil::create_index( 'ios_apps', 'updated_at' );
		\DBUtil::create_index( 'ios_apps', 'created_at' );
		\DBUtil::create_index( 'ios_apps', array( 'is_japanese', 'release_date' ) );
		\DBUtil::create_index( 'ios_apps', array( 'has_face', 'release_date' ) );
	}

	public function down()
	{
		\DBUtil::drop_table('spider_url');
		\DBUtil::drop_table('images');
		\DBUtil::drop_table('android_apps');
		\DBUtil::drop_table('ios_apps');
	}
}
