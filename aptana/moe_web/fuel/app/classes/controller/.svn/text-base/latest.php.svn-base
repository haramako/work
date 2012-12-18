<?php

class Controller_Latest extends Controller_Base
{
	public static $PER_PAGE = 20;

	/** すべて */
	public function action_all( $page = 1 )
	{
		$apps = Model_Appli::find()
			->where('platform',$this->platform)
			->where('status','=','')
			->order_by('release_date','desc')->limit(self::$PER_PAGE)->offset( ($page-1) * self::$PER_PAGE )->get();

		$this->render( $apps, $page, 'latest/all/' );
	}

	/** 無料 */
	public function action_free( $page = 1 )
	{
		$apps = Model_Appli::find()
			->where('platform',$this->platform)
			->where('price',0)
			->where('status','=','')
			->order_by('release_date','desc')->limit(self::$PER_PAGE)->offset( ($page-1) * self::$PER_PAGE )->get();
		$this->render( $apps, $page, 'latest/free/' );
	}

	/** 有料 */
	public function action_paid( $page = 1 )
	{
		$apps = Model_Appli::find()
			->where('platform',$this->platform)
			->where('price','!=',0)
			->where('status','=','')
			->order_by('release_date','desc')->limit(self::$PER_PAGE)->offset( ($page-1) * self::$PER_PAGE )->get();
		$this->render( $apps, $page, 'latest/paid/' );
	}
	
	public function render( $apps, $page, $base )
	{
		$i = 0;
		foreach( $apps as &$app ){
			
			// 表示スタイルの決定とスクリーンショットの取得
			$style = 'icon';
			if( rand(0,10) < 3 ){
				$images = $app->screenshot;
				if( $images ){
					// スクリーンショットがあれば
					if( $app->id == 29019 ) Log::debug( $images );
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

			$app->info['moe_star'] = sprintf( '%02d', floor( min( 50, $app->moe * 5 + $app->rate * 10 )/5)*5 );
			$app->info['style'] = $style;
			
			$i++;
		}

		$this->template->title = 'Timeline &raquo; Index';
        $this->template->content = View::forge('latest/index', array( 'apps'=>$apps, 'page'=>$page, 'base'=>$base ) );
	}

}
