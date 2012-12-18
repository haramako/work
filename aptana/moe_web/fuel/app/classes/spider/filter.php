<?php

define( 'ANIMEFACE_PATH', APPPATH.'../../tool/animeface/animeface' );

/**
 * 萌え絵フィルタ.
 */
class Spider_Filter
{
		
	/**
	 * 画像の特徴量を取得する.
	 *
	 * 二次元の顔の座標を検知して、その座標リストを取得する.
	 *
	 * @param string $url 画像のURL
	 * @return string 画像の特徴量( '[ [ left1,top1,right1,bottom1], [ left2,top2,right2,bottom2] ]' のような形の配列, 検出されなかった場合は[] )
	 */
	public static function get_feature( $url )
	{
		$rows = DB::select()->from('images')->where('url','=',$url)->execute()->as_array();
		if( count($rows) != 0 ) return json_decode($rows[0]['feature']); // すでに処理しているなら飛ばす
	
		try{
			list( $file ) = Spider_Cache::fetch( $url );
		}catch( Exception $err ){
			Log::warning( $err );
			return '';
		}
		$size = getimagesize($file);
		
		$data = array();
		$data['url'] = $url;
		$data['feature'] = '';
		$data['width'] = $size[0];
		$data['height'] = $size[1];
		
		DB::insert('images')->set( $data )->execute();
		Log::info( "filter image {$url}: {$data['feature']}" );
		
		return '';
	}

	/**
	 * 日本語が含まれているかを判定.
	 */
	public static function is_japanese( $str )
	{
		return preg_match( '/(あ|い|う|え|お|か|き|く|け|こ|さ|し|す|せ|そ|た|ち|つ|て|と|な'.
			'|に|ぬ|ね|の|は|ひ|ふ|へ|ほ|ま|み|む|め|も|や|ゆ|よ|わ|を|ん)/', $str );
	}

	/**
	 * androidアプリのアイコンをフィルターで処理する.
	 */
	public static function filter_android()
	{
		$apps = DB::query("SELECT id, title, description, icon, screenshot FROM android_apps ".
			" WHERE is_japanese = '' OR has_face = ''" )
			->execute()->as_array();

		foreach( $apps as $i=>$app ){
			try{
				// 顔があるか判定
				$url = $app['icon'];
				$feature = self::get_feature( $url );
				$has_face = ( count($feature) > 0)?'T':'F';
				// 日本語が入っているか判定
				$is_japanese = self::is_japanese( $app['title'].$app['description'] );
				$is_japanese = ($is_japanese?'T':'F');
				// 更新
				DB::update('android_apps')->where('id','=', $app['id'] )
					->set( array( 'has_face'=>$has_face, 'is_japanese'=>$is_japanese ) )->execute();
			}catch( Exception $err ){
				Log::warning( "failed filter image {$url}\n" );
				Log::warning( $err );
			}
		}
	}
	
	/**
	 * iosアプリのアイコンをフィルターで処理する.
	 */
	public static function filter_ios()
	{
		$apps = DB::query("SELECT id, track_name, description, screenshot_urls, artwork_url60, artwork_url512 FROM ios_apps ".
			" WHERE is_japanese = '' OR has_face = ''" )
			->execute()->as_array();

		foreach( $apps as $i=>$app ){
			try{
				// 顔があるか判定
				$url = $app['artwork_url512'];
				$feature = self::get_feature( $url );
				$has_face = ( count($feature) > 0)?'T':'F';
				// 日本語が入っているか判定
				$is_japanese = self::is_japanese( $app['track_name'].$app['description'] );
				$is_japanese = ($is_japanese?'T':'F');
				// 更新
				DB::update('ios_apps')->where('id','=', $app['id'] )
					->set( array( 'has_face'=>$has_face, 'is_japanese'=>$is_japanese ) )->execute();
			}catch( Exception $err ){
				Log::warning( "failed filter image {$url}\n" );
				Log::warning( $err );
			}
		}
	}
}
