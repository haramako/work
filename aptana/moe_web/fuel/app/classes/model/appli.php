<?php
use Orm\Model;

class Model_Appli extends Model
{
	public $info = array(); // モデル等に渡すときに使用する付属情報
	
	public static $STATUS_STR = array( ''=>'通常', 'D'=>'削除', 'W'=>'保留', 'K'=>'死亡' );
	public static $STATUS_LABEL = array( ''=>'', 'D'=>'label-warning', 'W'=>'label-info', 'K'=>'label-inverse' );
	
	protected static $_properties = array(
		'id',
		'platform',
		'original_id',
		'title',
		'author',
		'icon',
		'screenshot'=>array('data_type'=>'serialize', 'default'=>array()),
		'description',
		'release_date',
		'price',
		'category',
		'rate',
		'moe'=>array('default'=>0),
		'view'=>array('default'=>0),
		'install'=>array('default'=>0),
		'status'=>array('default'=>'W'),
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
		'Orm\\Observer_Typing' => array(
			'events' => array('before_save', 'after_save', 'after_load')
		),
	);

	public static function validate($factory)
	{
		$val = Validation::forge($factory);
		$val->add_field('platform', 'Platform', 'required|max_length[8]');
		$val->add_field('original_id', 'Original Id', 'required|max_length[64]');
		$val->add_field('title', 'Title', 'required|max_length[255]');
		$val->add_field('author', 'Author', 'required|max_length[255]');
		$val->add_field('icon', 'Icon', 'required|max_length[255]');
		$val->add_field('screenshot', 'Screenshot', 'required|max_length[1024]');
		$val->add_field('description', 'Description', 'required');
		$val->add_field('release_date', 'Release Date', 'required|valid_string[numeric]');
		$val->add_field('price', 'Price', 'required|valid_string[numeric]');
		$val->add_field('category', 'Category', 'required|max_length[64]');
		$val->add_field('rate', 'Rate', 'required');
		$val->add_field('moe', 'Moe', 'required');
		$val->add_field('view', 'View', 'required');
		$val->add_field('install', 'Install', 'required');
		$val->add_field('status', 'Status', 'required');

		return $val;
	}

	/**
	 * 萌えボタンを押す.
	 * @param Model_User $user
	 */
	public function increment_moe( $user )
	{
		try {
			DB::start_transaction();
			
			// 今日の00:00の時間を取得
			$begin_of_today = new DateTime( date('Y-m-d') );
			$begin_of_today = $begin_of_today->getTimestamp();

			// moe_usersの更新
			$moe_user = DB::select()->from('moe_users')->where( array('user_id'=>$user->id, 'appli_id'=>$this->id ) )->execute();
			if( count( $moe_user ) == 0 ){
				$moe_user = array('user_id'=>$user->id, 'appli_id'=>$this->id, 'count'=>1, 'updated_at'=>time() );
				DB::insert('moe_users')->set( $moe_user )->execute();
			}else{
				$moe_user = $moe_user[0];
				$update_day = new DateTime( date('Y-m-d', $moe_user['updated_at']) );
				$update_day = $update_day->getTimestamp();
				Log::info( $update_day, $begin_of_today );
				if( $update_day == $begin_of_today ){
					// 今日はすでに押してるのでキャンセル
					DB::rollback_transaction();
					return false;
				}
				$moe_user['count']++;
				$moe_user['updated_at'] = time();
				DB::update('moe_users')->where( array('user_id'=>$user->id, 'appli_id'=>$this->id ) )->set( $moe_user )->execute();
			}
			
			// appliの更新
			$this->moe++;
			$this->save();
			
			// moe_historiesの更新
			$history = DB::select()->from('moe_histories')->where( array('time_at'=>$begin_of_today, 'appli_id'=>$this->id ) )->execute();
			if( count( $history ) == 0 ){
				$history = array('time_at'=>$begin_of_today, 'appli_id'=>$this->id, 'count'=>1 );
				DB::insert('moe_histories')->set( $history )->execute();
			}else{
				$history = $history[0];
				$history['count']++;
				DB::update('moe_histories')->where( array('time_at'=>$begin_of_today, 'appli_id'=>$this->id ) )->set( $history )->execute();
			}
			
			DB::commit_transaction();
			return true;
		}catch( Exception $err ){
			DB::rollback_transaction();
			throw $err;
		}
	}

	/**
	 * PVを増やす
	 */
	public function increment_view()
	{
		try {
			DB::start_transaction();
			
			// 今日の00:00の時間を取得
			$begin_of_today = new DateTime( date('Y-m-d') );
			$begin_of_today = $begin_of_today->getTimestamp();

			// appliの更新
			$this->view++;
			$this->save();
			
			// moe_historiesの更新
			$history = DB::select()->from('pv_histories')->where( array('time_at'=>$begin_of_today, 'appli_id'=>$this->id ) )->execute();
			if( count( $history ) == 0 ){
				$history = array('time_at'=>$begin_of_today, 'appli_id'=>$this->id, 'count'=>1 );
				DB::insert('pv_histories')->set( $history )->execute();
			}else{
				$history = $history[0];
				$history['count']++;
				DB::update('pv_histories')->where( array('time_at'=>$begin_of_today, 'appli_id'=>$this->id ) )->set( $history )->execute();
			}
			
			DB::commit_transaction();
		}catch( Exception $err ){
			DB::rollback_transaction();
			throw $err;
		}
	}

	/**
	 * INSTALLを増やす
	 */
	public function increment_install( $user )
	{
		// appliの更新
		$this->install++;
		$this->save();
		// user_appli_installsの更新
		DB::insert('install_logs')->set( array( 'user_id'=>$user->id, 'appli_id'=>$this->id, 'created_at'=>time() ) )->execute();
	}
	
	/**
	 * AppStore/GooglePlayのURLを取得する
	 */
	public function detail_url()
	{
		if( $this->platform == 'android' ){
			return 'market://details?id='.$this->original_id;
		}else{
			return 'http://itunes.apple.com/jp/app/id'.$this->original_id;
		}
	}

	/**
	 * ストアでアプリが生きているかを確認する.
	 *
	 * @return bool 削除されている場合は、falseを返す。削除されていなければtrueを返す
	 */
	public function is_alive()
	{
		require_once( 'HTTP/Request2.php' );
		switch( $this->platform ){
			case 'android':
				$url = 'https://play.google.com/store/apps/details?id='.$this->original_id;
				$request = new HTTP_Request2($url);
				
				// ubuntu上でエラーが出るのでSSLのオプションを指定
				// 参考:http://1000g.5qk.jp/2011/11/25/http_request2%E3%81%A7https%E6%8E%A5%E7%B6%9A%E3%81%A7%E3%81%8D%E3%81%AA%E3%81%84%E5%A0%B4%E5%90%88%E3%81%AE%E5%AF%BE%E7%AD%96/)
				$request->setConfig( array( 'ssl_verify_host' => false, 'ssl_verify_peer' => false ) );
				
				$response = $request->send();
				if( $response->getStatus() == 404 ){
					return false;
					Log::warning( "android appli {$this->original_id} is dead." );
				}else if( $response->getStatus() != 200 ){
					Log::warning( "cannot access to {$url}, status={$response->getStatus()}" );
				}
				return true;
				break;
			case 'ios':
				// TODO: must implement
				return true;
				break;
			default:
				throw new Exception( "invalid platform {$this->platform}, id={$this->id}" );
		}
	}

	/** ステータスの文字列表現を返す */
	public function status_str()
	{
		return self::$STATUS_STR[$this->status];
	}

	/** ステータスのCSSクラス('label-*')を返す */
	public function status_label()
	{
		return self::$STATUS_LABEL[$this->status];
	}
	
}
