<?php

/**
 * カテゴリページの解析を行うクラス.
 *
 * 対象ページ例： http://itunes.apple.com/jp/genre/ios-gemu/id6014?mt=8
 */ 
class Spider_Walker_Ios_Category extends Spider_Walker
{
	public $regexp = '!http://itunes\.apple\.com/jp/genre/ios-!';
	
	public function walk( $url, $match )
	{
		$doc = phpQuery::newDocument( Spider_Cache::get( $url ) );
		foreach( pq('a', $doc) as $link ){
			$href = pq($link)->attr('href');
			// 頭文字別アプリ一覧(１ページ目)
			if( preg_match( '!http://itunes.apple.com/jp/genre/ios-.*&letter=.!', $href ) ){
				$this->add_url( $href );
			}
			// アプリ一覧の２ページ目以降
			if( preg_match( '!http://itunes.apple.com/jp/genre/ios-.*&letter=.*&page=.*!', $href ) ){
				$this->add_url( $href );
			}
			// アプリの情報ページ
			if( preg_match( '!http://itunes.apple.com/jp/app/!', $href ) ){
				$this->add_url( $href );
			}
		}
		phpQuery::unloadDocuments( $doc );
		return 60*60*8;
	}
}

Spider_Walker::regist( new Spider_Walker_Ios_Category() );
