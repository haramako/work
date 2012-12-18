<?php

/**
 * アプリの詳細ページ
 *
 * 対象ページ例： https://play.google.com/store/apps/details?id=com.palmarysoft.customweatherpro
 */
class Spider_Walker_Android_App extends Spider_Walker
{
	public $regexp = '!https://play\.google\.com/store/apps/details\?id=([^&]+)!';
	
	public function walk( $url, $match )
	{
		$app_id = $match[1];
		$doc = phpQuery::newDocument( Spider_Cache::get( $url.'&hl=ja' /*日本語*/ ) );
		
		foreach( pq('a', $doc) as $link ){
			$href = pq($link)->attr('href');
			// アプリを取得
			if( preg_match( '!^/store/apps/details\?id=([^&]+)!', $href, $match ) ){
				$this->add_url( 'https://play.google.com/store/apps/details?id='.$match[1] );
			}
			if( preg_match( '!^/store/apps/developer\?id=([^&]+)!', $href, $match ) ){
				$this->add_url( 'https://play.google.com/store/apps/developer?id='.$match[1] );
			}
		}

		// アプリの情報をパース
		$app = Model_Androidapp::find()->where('app_id',$app_id)->get_one();
		if( !$app ) $app = new Model_Androidapp();
		
		$app->app_id       = $app_id;
		$app->title        = pq('.doc-banner-title',$doc)->text();
		$app->author       = pq('.doc-header-link',$doc)->text();
		$app->icon         = pq('.doc-banner-icon img',$doc)->attr('src');
		$app->description  = preg_replace( '!<br/>|<p>|</p>!', "\n", pq('#doc-original-text',$doc)->html() );
		$app->release_date = pq('time[itemprop=datePublished]',$doc)->text();
		$app->rate         = pq('.doc-metadata-list .ratings',$doc)->attr('content');
		$app->category     = pq('.doc-metadata-list dd:eq(4)',$doc)->text();
		$app->price        = preg_replace( '/￥|,/', '', pq('meta[itemprop=price])',$doc)->attr('content') );
		$download_num  = explode( "\n", pq('dd[itemprop=numDownloads]')->contents(0)->text() );
		$app->download_num  = $download_num[0];
		// $require_version = pq('dl.doc-metadata-list dd',$doc);
		$screenshot_urls = array();
		foreach( pq('.screenshot-carousel-content-container img') as $img ){
			$screenshot_urls[]= html_entity_decode( pq($img)->attr('data-baseurl') );
		}
		$app->screenshot   = $screenshot_urls;

		// 画像の判定
		$url = $app->icon;
		$feature = Spider_Filter::get_feature( $url );
		$app->has_face = ( count($feature) > 0)?'T':'F';
		// 日本語が入っているか判定
		$is_japanese = Spider_Filter::is_japanese( $app->title.$app->description );
		$app->is_japanese = ($is_japanese?'T':'F');

		// アプリを追加する
		$app->save();
		
		phpQuery::unloadDocuments( $doc );
		
		return 60*60*24*30;
	}
}

Spider_Walker::regist( new Spider_Walker_Android_App() );
