<?php

class Spider_Walker_Ios_App extends Spider_Walker
{
	public $regexp = '!http://itunes\.apple\.com/jp/app/.*/id(\\d+)\?!';
	
	public function walk( $url, $match )
	{
		$app_id = $match[1];
		$url = 'http://itunes.apple.com/jp/lookup?country=JP&id='.$app_id;
		$json = json_decode( Spider_Cache::get($url), true );
		$app = array();
		if( !is_array($json) || !array_key_exists('results', $json) || count( $json['results'] ) == 0 ) throw new Exception("invalid item $url");
		foreach( $json['results'][0] as $key=>$val ){
			if( $key == 'averageUserRatingForCurrentVersion' ) continue;
			if( $key == 'userRatingCountForCurrentVersion' ) continue;
			if( $key == 'averageUserRating' ) continue;
			if( $key == 'userRatingCount' ) continue;
			$column = strtolower(preg_replace('/([a-z])([A-Z])/', "$1_$2", $key));
			if( is_array($val) ){
				$app[$column] = serialize( $val );
			}else{
				$app[$column] = $val;
			}
		}
		
		// ibookの場合は、飛ばす
		if( $app['track_name'] == 'iBooks' ) return 60*60*24*365;

		// 画像の判定
		$url = $app['artwork_url512'];
		$feature = Spider_Filter::get_feature( $url );
		$app['has_face'] = ( count($feature) > 0)?'T':'F';
		// 日本語が入っているか判定
		$is_japanese = Spider_Filter::is_japanese( $app['track_name'].$app['description'] );
		$app['is_japanese'] = ($is_japanese?'T':'F');

		// アプリを追加する
		$row = DB::select('id')->from('ios_apps')->where('track_id','=',$app_id)->execute();
		if( count( $row ) == 0 ){
			DB::insert('ios_apps')->set($app)->execute();
		}else{
			DB::update('ios_apps')->where('id','=',$app_id)->set($app)->execute();
		}
		return 60*60*24*365;
	}
}

Spider_Walker::regist( new Spider_Walker_Ios_App() );
