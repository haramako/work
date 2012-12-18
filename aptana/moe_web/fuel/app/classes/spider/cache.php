<?php

/**
 * キャッシュ付きのHTTPアクセスを行う.
 *
 * 使い方：
 * <code>
 * $html = Spider_Cache::get('http://www.yahoo.co.jp/'); // ページを取得する、２回目以降はキャッシュを利用する
 *
 * list( $path, $data ) = Spider_Cache::fetch('http://www.yahoo.co.jp/'); 
 * </code>
 */
class Spider_Cache
{

	static public $cache_dir;
	
	/** キャッシュを有効にするかどうか */
	static public $enabled = true;
	
	static public function _init()
	{
		self::$cache_dir = Config::get('cache_dir').'cached_http/';
	}

	/**
	 * URLを指定し、データを取得する.
	 *
	 * @param string $url 取得するデータのURL
	 * @return string 取得したデータ
	 */
	static public function get( $url )
	{
		list( $path, $data ) = self::fetch( $url );
		if( $data ){
			return $data;
		}else{
			return file_get_contents( $path );
		}
	}

	/**
	 * URLを指定し、データを取得し、キャッシュに格納する.
	 *
	 * @param string $url 取得するデータのURL
	 * @return Array 取得したデータ( [キャッシュのパス、データ(キャッシュに入っていた場合はNULL)] )
	 */
	static public function fetch( $url )
	{
		$filename = str_replace( '/', '-', $url );
		$dir = self::$cache_dir.substr( md5( $filename ), 0, 2 );
		$path = $dir.'/'.$filename;
		if( self::$enabled && file_exists( $path ) ){
			// キャッシュにあった
			return array($path, NULL);
		}else{
			// キャッシュになかった
			$data = @file_get_contents( $url );
			if( !$data ) throw new Exception( "cannot access {$url}" );
			if( !file_exists($dir) ) mkdir( $dir, 0777, true );
			file_put_contents( $path, $data );
			return array($path, $data);
		}
	}
	
}
