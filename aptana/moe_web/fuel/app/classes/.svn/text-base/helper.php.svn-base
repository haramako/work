<?php

class Helper {

	/**
	 * ページネーションを行う.
	 *
	 * このページネーションは、最初と最後のページへのリンクを必ず表示する（途中は'...'で飛ばす)
	 *
	 * <code>
	 * // 全部で１０ページで、現在が１ページ目のページネーションを行う
	 * // [1] [2] [3] [4] [5] [6] ... [10] のようなページネーションが表示される
	 * echo Helper::pagenation( 'search?text=hoge&p=%', 1, 10 ); 
	 * 
	 * </code>
	 *
	 * @param string $url リンクのベースとなる文字列('%'の部分にページ数が入る)
	 * @param int $cur 現在のページ番号(１始まり)
	 * @param int $max 最大ページ数
	 * @param int $num 前後何ページを表示するか
	 # @return string ページネーションのHTML
	 */
	public static function pagination( $url, $cur, $max, $num = 5 )
	{
		$result = array('<div class="pagination"><ul>');
		$begin = max( 1, $cur - $num );
		$end = min( $max, $cur + $num );
	
		if( $begin > 1 ) $result[]= '<li>'.Html::anchor( str_replace('%',1,$url), 1).'</li><li class="disabled"><a href="#">...</a></li>';
	
		for( $p=$begin; $p<=$end; $p++){
			if( $p == $cur ){
				$result[]= '<li class="active">'.Html::anchor( str_replace('%',$p,$url), $p ).'</li>';
			}else if( $p == $cur+1 ){
				// auto pagerize用のタグ
				$result[]= '<li>'.Html::anchor( str_replace('%',$p,$url), $p, array('rel'=>'next') ).'</li>';
			}else{
				$result[]= '<li>'.Html::anchor( str_replace('%',$p,$url), $p).'</li>';
			}
		}
	
		if( $end < $max ) $result[]= '<li class="disabled"><a href="#">...</a></li><li>'.Html::anchor( str_replace('%',$max,$url), $max).'</li>';

		$result[]= '</ul></div>';
		return implode( '', $result );
	}

	/**
	 * ブール値をアイコンHTMLに変換する.
	 * @param bool mixed 値( 真は true,'T'、 偽は false,'F'、  不明は '',null,それ以外 )
	 * @return string アイコンを表すHTML
	 */
	public static function bool2icon( $bool )
	{
		if( $bool === 'T' or $bool === true ){
			return '<i class="icon-certificate"></i>';
		}else if( $bool === 'F' or $bool === false ){
			return '<i class="icon-remove"></i>';
		}else{
			return '<i class="icon-minus"></i>';
		}
	}

	/**
	 * 日時を"2012-07-01"のような文字列に変換する
	 * @param int $date unixtime
	 * @return string 日時を表す文字列
	 */
	public static function date2str( $date )
	{
		return strftime( '%Y-%m-%d', $date );
	}
	
	/**
	 * 日付を"2012-07-01 12:00:00"のような文字列に変換する
	 * @param int $date unixtime
	 * @return string 日付を表す文字列
	 */
	public static function datetime2str( $date )
	{
		return strftime( '%Y-%m-%d %H:%M:%S', $date );
	}

	/**
	 * 文字列を途中で切る.
	 * @param string $text 文字列
	 * @param int $length 切り取る長さ[文字]
	 * @param string $omission 省略された場合に追加される文字列
	 * @return string 指定された以上に長い場合は、省略された文字列
	 */
	public static function truncate( $text, $length, $omission = '...')
	{
		if( mb_strlen($text) > $length ){
			return mb_substr( $text, 0, $length ).$omission;
		}else{
			return $text;
		}
	}
}
