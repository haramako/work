<?php
/**
 * カテゴリ一覧ページの解析を行うクラス.
 *
 * 対象ページ： https://play\.google\.com/store/apps/category/GAME
 */
class Spider_Walker_Android_Category extends Spider_Walker
{
	public $regexp = '!https://play\.google\.com/store/apps/category/!';
	
	public function walk( $url, $match )
	{
		try {
			$doc = phpQuery::newDocument( Spider_Cache::get( $url ) );
		}catch( Exception $err ){
			return 60*60*8;
		}
		
		foreach( pq('a', $doc) as $link ){
			$href = pq($link)->attr('href');
			// アプリのジャンルを取得
			if( preg_match( '!^/store/apps/category/([[a-zA-Z]+)\?!', $href, $match ) ){
				$this->add_url( 'https://play.google.com'.$href );
				for( $page=0; $page < 19; $page++ ){
				  $this->add_url( 'https://play.google.com/store/apps/category/'.$match[1].'/collection/topselling_free?start='.($page*24).'&num=24' );
				  $this->add_url( 'https://play.google.com/store/apps/category/'.$match[1].'/collection/topselling_paid?start='.($page*24).'&num=24' );
				}
			}
			// アプリを取得
			if( preg_match( '!^/store/apps/details\?id=([^&]+)!', $href, $match ) ){
				$this->add_url( 'https://play.google.com'.$match[0] );
			}
		}
		phpQuery::unloadDocuments( $doc );
		return 60*60*8;
	}

}

Spider_Walker::regist( new Spider_Walker_Android_Category() );
