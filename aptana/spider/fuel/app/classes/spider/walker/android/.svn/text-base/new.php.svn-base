<?php
/**
 * カテゴリ一覧ページの解析を行うクラス.
 *
 * 対象ページ： https://play\.google\.com/store/apps/category/GAME
 */
class Spider_Walker_Android_New extends Spider_Walker
{
	public $regexp = '!https://play\.google\.com/store/apps/collection/topselling_new_!';
	
	public function walk( $url, $match )
	{
		for( $page=0; $page < 19; $page++ ){
			try {
				$doc = phpQuery::newDocument( Spider_Cache::get( $url.'?start='.($page*24).'&num=24' ) );
			}catch( Exception $err ){
				continue;
			}
		
			foreach( pq('a', $doc) as $link ){
				$href = pq($link)->attr('href');
				// アプリを取得
				if( preg_match( '!^/store/apps/details\?id=([^&]+)!', $href, $match ) ){
					$this->add_url( 'https://play.google.com'.$match[0] );
				}
			}
		}
		phpQuery::unloadDocuments( $doc );
		return 60*60*8;
	}

}

Spider_Walker::regist( new Spider_Walker_Android_New() );
