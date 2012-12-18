<?php

/**
 * デベロッパページ
 *
 * 対象ページ例： https://play.google.com/store/apps/developer?id=adidas+Japan+K.K.
 */
class Spider_Walker_Android_Developer extends Spider_Walker
{
	public $regexp = '!https://play\.google\.com/store/apps/developer\?id=([^&]+)!';
	
	public function walk( $url, $match )
	{
		$app_id = $match[1];
		for( $page=0; $page<20; $page++){

			try {
				$doc = phpQuery::newDocument( Spider_Cache::get( $url.'&start='.($page*12).'&num=12' ));
			}catch( Exception $err ){
				break;
			}
		
			foreach( pq('a', $doc) as $link ){
				$href = pq($link)->attr('href');
				// アプリを取得
				if( preg_match( '!^/store/apps/details\?id=([^&]+)!', $href, $match ) ){
					$this->add_url( 'https://play.google.com/store/apps/details?id='.$match[1] );
				}
			}

			phpQuery::unloadDocuments( $doc );
		}
		
		return 60*60*24*30;
	}
}

Spider_Walker::regist( new Spider_Walker_Android_Developer() );
