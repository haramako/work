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
spiderは、AppStore/GooglePlayのアプリ情報を収集するためのタスクです。
taskは途中経過を標準出力に出力することができないので、ログをtailして経過は確認してください。
		
使い方:
    $ oil refine spider               # spiderを実行する
    $ oil refine spider:multi <num>   # spiderをnum個のプロセスで複数並列実行
    $ oil refine spider:daemon <num>  # デーモンとして走らせる(num個のプロセスで複数並列実行)
    $ oil refine spider:url <url>     # URLを指定して、spiderの処理を行う
    $ oil refine spider:clean         # 'P'状態のurlをクリーンナップする
    $ oil refine spider:image         # 画像の萌え判定を行う
			
    $ oil refine spider:help          # このヘルプを表示する
EOT;
	}
	
	public static function run()
	{
		\Spider_Cache::$enabled = false;
		\Spider_Walker::walk_all();
	}
	
	public static function multi( $worker_num )
	{
		$pipes = array();
		for( $i=0; $i<$worker_num; $i++){
			$p[]= \popen('php oil refine spider','r');
		}
		foreach( $pipes as $pipe ){
			\Log::info( \fread( $pipe ) );
		}
	}

	/**
	 * デーモンとして実行する.
	 */
	public static function daemon( $uid, $gid, $worker_num = 1 )
	{
		// PearのSystem_Daemonが必要
		require_once( 'System/Daemon.php' );
		\Log::info( APPPATH );
		\System_Daemon::SetOptions( array(
				'appName' => 'spider',
				'appDir' => APPPATH,
				'appPidLocation' => APPPATH.'tmp/pid',
				'appRunAsUID' => $uid,
				'appRunAsGID' => $gid,
			));

		System_Daemon::start();
		
		$pipes = array();
		for( $i=0; $i<$worker_num; $i++){
			$p[]= \popen('php oil refine spider','r');
		}

		while( !System_Daemon::isDying() ){
			System_Daemon::iterate(1);
		}
		System_Daemon::stop();

	}

	public static function clean()
	{
		\DB::query("UPDATE spider_url SET status='' WHERE status='P'")->execute();
	}
	
	public static function url($url)
	{
		\Spider_Walker::match( $url );
	}

	public static function image()
	{
		\Spider_Filter::filter_ios();
		\Spider_Filter::filter_android();
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

	public static function fix()
	{
		$apps = \Model_Androidapp::find()->where('screenshot','LIKE','s:%')->get();
		foreach( $apps as $app ){
			$app->screenshot = unserialize( $app->screenshot );
			$app->save();
		}
		print count($apps)."\n";
	}

}
