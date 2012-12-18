<?php
/**
 * 萌えアプリのWEB巡回を行うタスク.
 *
 */

namespace Fuel\Tasks;

class Spider
{

	public static function help()
	{
		return <<< EOT
使い方:
    $ oil refine spider:collect     // spiderからアプリを収集する
    $ oil refine spider:check_alive // アプリが削除されていないか確認する
    $ oil refine spider:clean_cache // キャシュディレクトを削除する
			
    $ oil refine spider:help        // このヘルプを表示する
EOT;
	}
	
	public static function image()
	{
		\Spider_Filter::filter_ios();
		\Spider_Filter::filter_android();
	}

	public static function collect()
	{
		$from_at = \Kvs::get('spider.last_collect');
		$last_ios = \Spider_Collector::collect_ios($from_at);
		$last_android = \Spider_Collector::collect_android($from_at);
		$last_at = max( $last_ios, $last_android );
		\Kvs::set( 'spider.last_collect', $last_at );
		print $last_at."\n";
	}

	public static function clean_cache()
	{
		$dir = \Spider_Cache::$cache_dir;
		$result = explode( "\n", trim(`find $dir -type f -cmin +60`) ); // １時間以上古いものを消す
		foreach( $result as $file ){
			unlink( $file );
		}
		return "cache deleted";
	}

	/**
	 * アプリの生存確認を行い、ストアから削除されている場合は削除を行う.
	 */
	public static function check_alive()
	{
		$apps = \Model_Appli::find()->where('status','in',array('','W') )->get();
		foreach( $apps as $app ){
			// if( $app->release_date < time() - 60*60*24*7 ) continue; // リリースから7日以上経ってたらやらない
			\Log::debug( "checking alive {$app->original_id}" );
			if( !$app->is_alive() ){
				\Log::debug( "{$app->original_id} is dead!" );
				$app->status = "K";
				$app->save();
			}
		}
	}
	
}
