<?php

class Controller_Ranking extends Controller_Base
{
	public static $PER_PAGE = 20;

	/** 人気(PVランキング)
	 */
	public function action_popular( $page = 1 )
	{
		$apps = Model_Appli::find()
			->where('platform',$this->platform)
			->where('status','=','')
			->order_by('view','desc')->limit(self::$PER_PAGE)->offset( ($page-1) * self::$PER_PAGE )->get();
		
		$this->render( $apps, $page, 'ranking/popular/' );
	}

	/** 萌え(萌えボタンランキング) */
	public function action_moe( $page = 1 )
	{
		$apps = Model_Appli::find()
			->where('platform',$this->platform)
			->where('status','=','')
			->order_by('moe','desc')->limit(self::$PER_PAGE)->offset( ($page-1) * self::$PER_PAGE )->get();
		
		$this->render( $apps, $page, 'ranking/moe/' );
	}

	/**
	 * Viewを適用する.
	 */
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
			$app->info['rank'] = (($page-1) * self::$PER_PAGE) + $i+1;

			// １〜３位はクラスを変える
			$app->info['top_class'] = sprintf( '%02d', min( 4, $app->info['rank'] ) );
			
			// １桁、２桁、３桁によって、ランキング表示のクラスを変更する
			$class = array('','ranking_num_xx','ranking_num_xxx', 'ranking_num_xxx');
			$app->info['ranking_num_class'] = $class[floor( log( $app->info['rank'], 10 ) )];
			
			$i++;
		}

		$this->template->title = 'Timeline &raquo; Index';
        $this->template->content = View::forge('ranking/index', array( 'apps'=>$apps, 'page'=>$page, 'base'=>$base ) );
	}

}
