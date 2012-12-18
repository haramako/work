<?php

class Kvs
{
	private static $cache = array();

	public static function fetch( $key_prefix )
	{
		$rows = Model_Kvs::find()->where('key','LIKE',$key_prefix)->get();
		foreach( $rows as $id=>$val ){
			self::$cache[$row->key] = $row->val;
		}
	}
	
	public static function get( $key )
	{
		if( array_key_exists( $key, self::$cache ) ){
			return self::$cache[$key];
		}else{
			$row = Model_Kvs::find()->where('key',$key)->get_one();
			if( $row ){
				$cache[$key] = $row->val;
				return $cache[$key];
			}else{
				return null;
			}
		}
	}

	public static function set( $key, $val, $desc = "" )
	{
		$cache[$key] = $val;
		$row = Model_Kvs::find()->where('key',$key)->get_one();
		if( $row ){
			$row->val = $val;
			if( $desc ) $row->desc = $desc;
			$row->save();
		}else{
			$row = new Model_Kvs( array('key'=>$key,'val'=>$val,'desc'=>$desc) );
			$row->save();
		}
	}
}
