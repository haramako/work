<?php

// DOM操作用ライブラリ(phpQuery)を読み込む
// http://code.google.com/p/phpquery/
require_once( APPPATH.'vendor/phpQuery/phpQuery-onefile.php');

/*
// エラーハンドラを指定する
set_error_handler( function( $errno, $errstr, $errfile, $errline ){
		Log::error( $errfile.':'.$errline.' '.$errstr );
		return TRUE;
	});
*/

class Spider_Walker
{
	private static $_walkers = array();

	public static function regist( $walker )
	{
		self::$_walkers[] = $walker;
	}
	
	public static function match( $url )
	{
		foreach( self::$_walkers as $i=>$walker ){
			if( preg_match( $walker->regexp, $url, $match ) ){
				try {
					$expire = $walker->walk( $url, $match );
					DB::update('spider_url')->where('url','=',$url)->
						set( array('expire_at'=>time()+$expire,'status'=>'') )->execute();
				}catch( Exception $err ){
					DB::update('spider_url')->where('url','=',$url)->set( array('status'=>'F') )->execute();
					Log::warning( $err );
				}
				return TRUE;
			}
		}
		throw new Exception( "unknow url {$url}" );
	}

	public static function walk_all()
	{
		// AppStore/GooglePlayのルートURLを追加する(初回だけやればよい)
		$walker = new Spider_Walker();
		$walker->add_url( 'https://play.google.com/store/apps/category/GAME' );
		$walker->add_url( 'https://play.google.com/store/apps/collection/topselling_new_paid' );
		$walker->add_url( 'https://play.google.com/store/apps/collection/topselling_new_free' );

		while( true ){
			DB::start_transaction();
			
			$rows = DB::query('SELECT url FROM spider_url USE INDEX (status_expire_at ) WHERE status = "" AND expire_at < '.time().' LIMIT 1 FOR UPDATE ')->execute();
			if( count($rows) == 0 ){
				DB::rollback_transaction();
				sleep( 10 );
				continue;
			}
			$row = $rows[0];

			DB::update('spider_url')
				->where('url','=',$row['url'])
				->set( array('status'=>'P') )
				->execute();
			DB::commit_transaction();
			
			Log::debug( "scraping {$row['url']}" );
			self::match( $row['url'] );
		}
	}
		

	public function add_url( $url )
	{
		$row = DB::select('url')->from('spider_url')->where('url','=',$url)->execute();
		if( count( $row ) == 0 ){
			DB::insert('spider_url')->set( array( 'url'=>$url, 'expire_at'=>time() ) )->execute();
		}
	}

	
}

// ./walker/ 以下のPHPファイルをすべて読み込む
$dirs = new RecursiveIteratorIterator( new RecursiveDirectoryIterator(__DIR__.'/walker') );
foreach( $dirs as $path ){
	if( preg_match( '/\.php$/', $path ) ){
		require_once( $path );
	}
}
