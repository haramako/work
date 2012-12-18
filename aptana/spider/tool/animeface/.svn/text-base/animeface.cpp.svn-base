//g++ -o animeface animeface.cpp `pkg-config opencv --cflags --libs`
#include "stdio.h"
#include "libgen.h"
#include "iostream"
#include "opencv2/core/core.hpp"
#include "opencv2/objdetect/objdetect.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/features2d/features2d.hpp"
#include "opencv2/flann/flann.hpp"
#include "opencv2/video/video.hpp"

//openCVの名前空間のインポート
using namespace cv;

int main(int argc, char *argv[]){
	int min;
	Mat image; //入力画像（カラー）
	Mat grayImage; //検出用のグレイスケール画像

	// ヘルプテキストを表示
	if( argc != 2 ){
		printf( "萌え画像判定ツール\n"
				"Usage: \n"
				"  ./animeface <image_file>\n" );
		exit(0);
	}
	
	// 使う分類器（カスケード）の位置を取得する。
	// 実行ファイルとおなじディレクトリにあればよい。
	// ここでは正面顔のdefaultのものを指定
	char exe_path[PATH_MAX];
	char cascade_name[PATH_MAX];
	strcpy( exe_path, argv[0] );
	char *dir = dirname( exe_path );
	sprintf( cascade_name, "%s/lbpcascade_animeface.xml", dir );

	//入力画像の読み込み　引数がなければサンプル画像を読み込む
	image = imread(argv[1], CV_LOAD_IMAGE_COLOR);
	min = image.rows > image.cols ? image.cols/9 : image.rows/9;
	min = min > 20 ? min : 20;
	
	//検出用に、入力をグレイスケール変換
	cvtColor(image, grayImage, CV_BGR2GRAY, 0);
	//さらに、検出しやすくなるよう、ヒストグラムを均一化しコントラストを調整
	equalizeHist(grayImage, grayImage);

	CascadeClassifier cascade; //分類器を示す変数
	vector<Rect> faces; //検出結果
	
	cascade.load(cascade_name);
	//検出の実行　ここではReference Manualに記述してある標準的なパラメータを指定
	cascade.detectMultiScale( grayImage, faces,
		1.1, // scale factor
		3, // minimum neighbors
		0, // flags
		Size(min, min) // minimum size
	);

	//個々の検出領域を表す変数
	vector<Rect>::const_iterator r;
	printf( "[" );
	//検出領域の一つ一つに対するループ処理
	for( r = faces.begin();  r != faces.end(); r++ ){
		//検出した領域をJSON的に出力
		if( r != faces.begin() ) printf(",");
		printf("[%d,%d,%d,%d]",r->x,r->y,r->x + r->width - 1,r->y + r->height - 1);
	}
	printf( "]" );
	//終了
	return 0;
}
