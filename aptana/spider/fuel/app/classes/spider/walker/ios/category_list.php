<?php
/**
 * カテゴリ一覧ページの解析を行うクラス.
 *
 * 対象ページ： http://itunes.apple.com/jp/genre/ios/id36?mt=8
 */ 
class Spider_Walker_Ios_Category_list extends Spider_Walker
{
	public $regexp = '!http://itunes\.apple\.com/jp/genre/ios/id36\?mt=8!';
	
	public function walk( $url, $match )
	{
		$doc = phpQuery::newDocument( Spider_Cache::get( $url ) );
		foreach( pq('a', $doc) as $link ){
			$href = pq($link)->attr('href');
			// ニューススタンドは無視
			if( preg_match( '!http://itunes.apple.com/jp/genre/ios-newsstand!', $href ) ){
				continue;
			}
			// アプリのジャンルを取得
			if( preg_match( '!http://itunes.apple.com/jp/genre/ios-!', $href ) ){
				$this->add_url( $href );
			}
		}
		phpQuery::unloadDocuments( $doc );
		return 60*60*24;
	}

}

Spider_Walker::regist( new Spider_Walker_Ios_Category_list() );
