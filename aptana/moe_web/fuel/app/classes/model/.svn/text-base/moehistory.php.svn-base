<?php

class Model_Moehistory extends Model_Crud
{
	public static $_table_name = 'moe_histories';

	public static function find_by_pk( $time_at, $appli_id )
	{
		$result = self::find( array( 'where'=>array( 'time_at'=>$time_at, 'appli_id'=>$appli_id ) ) );
		if( $result ){
			return $result[0];
		}else{
			return null;
		}
	}
}
