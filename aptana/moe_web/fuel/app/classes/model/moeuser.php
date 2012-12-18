<?php

class Model_Moeuser extends Model_Crud
{
	public static $_table_name = 'moe_users';
	public static $_updated_at = 'updated_at';
	
	public static function find_by_pk( $time_at, $user_id )
	{
		$result = self::find( array( 'where'=>array( 'user_id'=>$user_id, 'appli_id'=>$appli_id ) ) );
		if( $result ){
			return $result[0];
		}else{
			return null;
		}
	}
}
