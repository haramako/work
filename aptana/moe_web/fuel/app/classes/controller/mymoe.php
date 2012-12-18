<?php

class Controller_Mymoe extends Controller_Base
{
	public static $PER_PAGE = 20;
	
	public function action_index( $page = 1 )
	{
		$this->no_cache();

		Log::debug( print_r( Session::get(), true ) );
		$user = $this->user();
		
		$app_ids = DB::select()->from('moe_users')
			->where('user_id','=',$user->id)
			->order_by('updated_at','desc')
			->limit(self::$PER_PAGE)->offset(($page-1)*self::$PER_PAGE)
			->execute()->as_array();
		$apps = array();
		foreach( $app_ids as $app_id ){
			$apps[]= Model_Appli::find( $app_id['appli_id'] );
		}
		$this->render( $apps, 1 );
	}

	public function render( $apps, $page )
	{
		$i = 0;
		foreach( $apps as &$app ){
			
			// 表示スタイルの決定とスクリーンショットの取得
			$style = 'icon';
			if( rand(0,10) < 3 ){
				$images = $app->screenshot;
				if( $images ){
					// スクリーンショットがあれば
					$app->info['screenshot'] = $images[rand(0,count($images)-1)];
					Spider_Filter::get_feature( $app->info['screenshot'] );
					$image_info = DB::select()->from('images')->where('url','=',$app->info['screenshot'])->execute();
					if( $image_info->count() > 0 ){
						// イメージの解析済み情報があれば
						$image_info = $image_info[0];
						if( (int)$image_info['width'] > (int)$image_info['height'] ){
							$style = 'horizontal'; // 横長
							if( $app->platform == 'android' ) $app->info['screenshot'] = preg_replace( '/=.+$/','=w480', $app->info['screenshot'] );
							$app->info['screenshot_height'] = ceil($image_info['height'] * 480 / $image_info['width'] );
						}else{
							$style = 'vertical'; // 縦長
							if( $app->platform == 'android' ) $app->info['screenshot'] = preg_replace( '/=.+$/','=w260', $app->info['screenshot'] );
							$app->info['screenshot_height'] = ceil($image_info['height'] * 260 / $image_info['width'] );
						}
					}
				}
			}

			// 左右のどちらかを選択
			if( $i % 2 == 0 ){
				$app->info['position'] = 'left';
			}else{
				$app->info['position'] = 'right';
			}

			$app->info['moe_star'] = sprintf( '%02d', min( 50, $app->moe * 5 ) );
			$app->info['style'] = $style;
			
			$i++;
		}

		$this->template->title = 'Timeline &raquo; Index';
		/** latest/index を借りる */
        $this->template->content = View::forge('latest/index', array( 'apps'=>$apps, 'page'=>$page, 'base'=>'mymoe/index/' ) );
	}
	
}
