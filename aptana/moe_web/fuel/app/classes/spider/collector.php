<?php

/**
 * アプリの収集を行う
 */
class Spider_Collector
{
	public static $moe_regexp;
	public static $moe_words;
	
	public static function has_moe_word( $str )
	{
		// 単語一覧を読み込み、キャッシュする
		if( !self::$moe_regexp ){
			$words = explode( "\n", file_get_contents( __DIR__.'/moe_words.txt' ) );
			$words = array_filter( $words, function($word){ return $word && $word[0] != '#'; } );
			$words = array_map( function($word){
					return preg_replace( '/\(|\)|\*|\+|\.|\[|\]|\//', "\\$0", $word );
				}, $words );
			self::$moe_regexp = '/'.implode( '|', $words ).'/';
			self::$moe_words = $words;
			// Log::info( self::$moe_regexp );
		}

		// MEMO: 正規表現よりも loop+strposのほうが全然早いので、正規表現は使わない
		foreach( self::$moe_words as $word ){
			if( strpos( $str, $word ) !== false ) return true;
		}
		return false;
	}
	
	public static function collect_ios()
	{
		return;
		$apps = DB::select()->from('ios_apps')->where('is_japanese','T')->execute();
		$num = 0;
		foreach( $apps as $app ){

			
			if( self::has_moe_word( $app['description'].$app['track_name'] ) ){
				//
			}else{
				continue;
			}
				
			$new_app = Model_Appli::find()->where( array('platform'=>'ios','original_id'=>$app['track_id']) )->get_one();
			if( !$new_app ){
				$new_app = Model_Appli::forge( array('platform'=>'ios') );
			}

			$new_app->platform = 'ios';
			$new_app->original_id=$app['track_id'];
			$new_app->title=$app['track_name'];
			$new_app->author=$app['artist_name'];
			$new_app->icon=$app['artwork_url60'];
			$new_app->screenshot=$app['screenshot_urls'];
			$new_app->description=$app['description'];
			$new_app->release_date=strtotime($app['release_date']);
			$new_app->price=(int)$app['price'];
			$genres = unserialize($app['genres']);
			$new_app->category=$genres[0];
			$new_app->rate='5.0';
			if( !$new_app->moe) $new_app->moe = 0;
			if( !$new_app->view) $new_app->view = 0;
			if( !$new_app->install) $new_app->install = 0;
			if( !$new_app->status) $new_app->status = '';
			
			if( $new_app->category == 'ブック' ) continue; // とりあえずブックははずす
			$new_app->save();
			$num += 1;
		}
		print $num."\n";
	}

	public static function collect_android( $from_at )
	{
		$last_at = $from_at;
		$apps = DB::select()->from('android_apps')->where('is_japanese','T')->where('updated_at','>',$from_at)->as_object()->execute('spider');
		$num = 0;
		foreach( $apps as $app ){
			
			$new_app = Model_Appli::find()->where( array('platform'=>'android','original_id'=>$app->app_id) )->get_one();
			if( !$new_app ){
				$new_app = Model_Appli::forge( array('platform'=>'android') );
			}

			if( $new_app->updated_at >= $app->updated_at ) continue;
			if( !self::has_moe_word( $app->description.$app->title ) ) continue;

			$new_app->platform = 'android';
			$new_app->original_id=$app->app_id;
			$new_app->title=$app->title;
			$new_app->author=$app->author;
			$new_app->icon=$app->icon;
			$new_app->screenshot=unserialize( $app->screenshot );
			$new_app->description=$app->description;
			$new_app->release_date=strtotime($app->release_date);
			$new_app->price=(int)$app->price;
			$new_app->category=$app->category;
			$new_app->rate=$app->rate;
			$new_app->save();
			$num += 1;
			$last_at = max( $last_at, $app->updated_at );
		}
		print $num."\n";
		return $last_at;
	}

	public static function collect_images( $from_at )
	{
	}
	
}

