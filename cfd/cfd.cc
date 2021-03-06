#include <stdio.h>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <math.h>
#include <memory.h>
#include <assert.h>

using namespace std;

const double DT = 0.1;
const double RE = 0.01;
const int XSIZE = 64;
const int YSIZE = 16;
const int END_TIME = 400;
const int SKIP = 4/DT;

void puts(const double d[XSIZE][YSIZE], ostream &out = cout, const string &label = "");

typedef double darray[XSIZE][YSIZE];

class CFD {
public:
	CFD(int width, int height);
	~CFD(){}

	void WriteCircle( double cx, double cy, double r );

	void Step();
	void Dump();
	
	const int WALL = 0;
	const int VALID = 1;
	
	//private:
	void CalcIryu();
	void CalcIryuCIP();
	void CalcNensei();
	void CalcGairyoku();
	void CalcPressure();
	void Poason();
	void CalcRHS();
	void CalcMarker();

	int width;
	int height;
	double cur_time;
	int cur_frame;
	
	char flag[XSIZE][YSIZE]; // 0: 壁, 1: 有効面
	
	darray yu;
	darray yun;
	darray yv;
	darray yvn;
	darray gux;
	darray guy;
	darray gvx;
	darray gvy;
	darray yp;
	darray s;
	darray marker;
};

CFD::CFD(int width_, int height_):
	width(width_), height(height_), cur_time(0), cur_frame(0)
{
	memset( yu, 0, sizeof(yu) );
	memset( yun, 0, sizeof(yun) );
	memset( yv, 0, sizeof(yv) );
	memset( yvn, 0, sizeof(yvn) );
	memset( gux, 0, sizeof(gux) );
	memset( guy, 0, sizeof(guy) );
	memset( gvx, 0, sizeof(gvx) );
	memset( gvy, 0, sizeof(guy) );
	memset( yp, 0, sizeof(yp) );
	memset( s, 0, sizeof(s) );
	memset( marker, 0, sizeof(marker) );
	
	for(int x=0; x<width; x++){
		for(int y=0; y<height; y++){
			flag[x][y] = 1;
		}
	}

	for(int x=0; x<width; x++){
		flag[x][0] = WALL;
		flag[x][height-1] = WALL;
	}
	
	for(int y=0; y<height; y++){
		flag[0][y] = WALL;
		flag[width-1][y] = WALL;
	}

	WriteCircle( 5.5, 5.5, 2 );
	//WriteCircle( 13.5, 9.5, 2 );

}

void CFD::WriteCircle( double cx, double cy, double r )
{
	for(int i=0; i<width; i++){
		for(int j=0; j<height; j++){
			if( sqrt( pow(i-cx,2) + pow(j-cy,2) ) < r ) flag[i][j] = 0;
		}
	}
}

void CFD::Step()
{
	CalcGairyoku();
	
	CalcPressure();
	CalcGairyoku();
	
	CalcRHS();
	CalcGairyoku();

	CalcIryu();
	//CalcIryuCIP();
	CalcNensei();
	CalcMarker();

	cur_time += DT;
	cur_frame++;
}

void CFD::CalcIryu()
{
	memcpy( yu, yun, sizeof(yu) );
	memcpy( yv, yvn, sizeof(yv) );
	
	// 移流項
	for(int i=1; i<width-1; i++){
		for(int j=1; j<height-1; j++){
			int is, js;
			double u, v;
			u = yu[i][j];
			v = (yv[i-1][j] + yv[i][j] + yv[i-1][j+1] + yv[i][j+1] ) / 4.0;
			is = -copysign(1.0, u);
			js = -copysign(1.0, v);
			yun[i][j] = yu[i][j] + is * u * (yu[i][j] - yu[i+is][j]) * DT + js * v * (yu[i][j] - yu[i][j+js]) * DT;

			u = (yu[i][j-1] + yu[i][j] + yu[i+1][j-1] + yu[i+1][j] ) / 4.0;
			v = yv[i][j];
			is = -copysign(1.0, u);
			js = -copysign(1.0, v);
			yvn[i][j] = yv[i][j] + js * v * (yv[i][j] - yv[i][j+js]) * DT + is * u * (yv[i][j] - yv[i+is][j]) * DT;
			
		}
	}

}


inline void newgrad( const darray &yn, const darray &y, darray &gx, darray &gy, int width, int height ) __restrict
{
	for(int i=1; i<width-1; i++){
		for(int j=1; j<height-1; j++){
			gx[i][j] += (yn[i+1][j] - yn[i-1][j] - y[i+1][j] + y[i-1][j] ) / 2;
			gy[i][j] += (yn[i][j+1] - yn[i][j-1] - y[i][j+1] + y[i][j-1] ) / 2;
		}
	}
}

// CIP法
// See: http://www.civil.hokudai.ac.jp/yasu/pdf_files/2d_basic.pdf ( 2次元CIP法 2.1.3 )
inline void dcip( darray &f, darray &gx, darray &gy, const darray &u, const darray &v, int width, int height ) __restrict
{
	
	double fn[XSIZE][YSIZE];
	double gxn[XSIZE][YSIZE];
	double gyn[XSIZE][YSIZE];

	memset( gxn, 0, sizeof(gxn) );
	memset( gyn, 0, sizeof(gyn) );
		
	for(int i=1; i<width-1; i++){
		for(int j=1; j<height-1; j++){
				
			double X = -u[i][j] * DT;
			double Y = -v[i][j] * DT;
			int is = copysign(1.0, u[i][j]);
			int js = copysign(1.0, v[i][j]);
			int im = i - is;
			int jm = j - js;
				
			double a1 = ( is * ( gx[im][j] + gx[i][j] ) - 2 * ( f[i][j] - f[im][j] ) ) * is;
			double b1 = ( js * ( gy[i][jm] + gy[i][j] ) - 2 * ( f[i][j] - f[i][jm] ) ) * js;
			double c1 = ( f[i][j] - f[i][jm] - f[im][j] + f[im][jm] - is * ( gx[i][jm] - gx[i][j] ) ) * js;
			double d1 = ( f[i][j] - f[i][jm] - f[im][j] + f[im][jm] - js * ( gx[im][j] - gx[i][j] ) ) * is;
			double e1 = 3 * ( f[im][j] - f[i][j] ) + is * ( gx[im][j] + 2 * gx[i][j] );
			double f1 = 3 * ( f[i][jm] - f[i][j] ) + js * ( gy[i][jm] + 2 * gy[i][j] );
			double g1 = ( gy[im][j] - gy[i][j] + c1 ) * is;

			fn[i][j] = ( ( a1*X + c1*Y + e1 )*X  +  g1*Y + gx[i][j] )*X
				+ ( (b1*Y + d1*X + f1 )*Y  +  gy[i][j] )*Y
				+ f[i][j];

			gxn[i][j] = ( 3*a1*X + 2*( c1*Y + e1 ) )*X  + (d1*Y+g1)*Y + gx[i][j];
			gyn[i][j] = ( 3*b1*Y + 2*( d1*X + f1 ) )*Y  + (c1*X+g1)*X + gy[i][j];
		}
	}

	for(int i=1; i<width-1; i++){
		for(int j=1; j<height-1; j++){
			double gxo = gxn[i][j]; //(gxn[i+1][j] - gxn[i-1][j]) / 2;
			double gyo = gyn[i][j]; //(gyn[i][j+1] - gyn[i][j-1]) / 2;
			f[i][j] = fn[i][j];
			gx[i][j] = gxn[i][j] - ( gxo*(u[i+1][j]-u[i-1][j]) + gyo*(v[i+1][j]-v[i-1][j]) )/2*DT;
			gy[i][j] = gyn[i][j] - ( gxo*(u[i][j+1]-u[i][j-1]) + gyo*(v[i][j+1]-v[i][j-1]) )/2*DT;
			if( fabs(gx[i][j]) > 1.0 ){ gx[i][j] = copysign(1.0,gx[i][j]); }
			if( fabs(gy[i][j]) > 1.0 ){ gy[i][j] = copysign(1.0,gy[i][j]); }
			//gx[i][j] = 0;
			//gy[i][j] = 0;
		}
	}
}

void CFD::CalcIryuCIP()
{
	newgrad( yun, yu, gux, guy, width, height );
	newgrad( yvn, yv, gvx, gvy, width, height );

	CalcGairyoku();
	
	// veloc
	double yuv[XSIZE][YSIZE];
	double yvu[XSIZE][YSIZE];
	memset( yuv, 0, sizeof(yuv) );
	memset( yvu, 0, sizeof(yvu) );
	for(int i=1; i<width-1; i++){
		for(int j=1; j<height-1; j++){
			yuv[i][j] = ( yu[i][j-1] + yu[i][j] + yu[i+1][j-1] + yu[i+1][j] ) / 4;
			yvu[i][j] = ( yv[i-1][j] + yv[i][j] + yv[i-1][j+1] + yv[i][j+1] ) / 4;
		}
	}

	dcip( yun, gux, guy, yu, yvu, width, height );
	dcip( yvn, gvx, gvy, yuv, yv, width, height );
	
	CalcGairyoku();
}

void CFD::CalcNensei()
{
	// 粘性項
	memcpy( yu, yun, sizeof(yu) );
	memcpy( yv, yvn, sizeof(yv) );
	for(int i=1; i<width-1; i++){
		for(int j=1; j<height-1; j++){
			yun[i][j] = yu[i][j] + RE * (yu[i+1][j] + yu[i][j+1] + yu[i-1][j] + yu[i][j-1]) * DT;
			yvn[i][j] = yv[i][j] + RE * (yv[i+1][j] + yv[i][j+1] + yv[i-1][j] + yv[i][j-1]) * DT;
		}
	}
	memcpy( yu, yun, sizeof(yun) );
	memcpy( yv, yvn, sizeof(yvn) );
}

void CFD::CalcGairyoku()
{
	for(int x=0; x<width; x++){
		for(int y=0; y<height; y++){
			if( flag[x][y] == WALL ){
				yu[x][y] = 0;
				yv[x][y] = 0;
				yun[x][y] = 0;
				yvn[x][y] = 0;
				gux[x][y] = 0;
				guy[x][y] = 0;
				gvx[x][y] = 0;
				gvy[x][y] = 0;

				// 壁の下面
				if( y < height-1 ){
					yv[x][y+1] = 0;
					yvn[x][y+1] = 0;
					guy[x][y+1] = 0;
					gvy[x][y+1] = 0;
				}
			
				// 壁の右面
				if( x < width-1 ){
					yu[x+1][y] = 0;
					yun[x+1][y] = 0;
					gux[x+1][y] = 0;
					gvx[x+1][y] = 0;
				}
			}
		}
	}

	for(int y=0; y<height; y++){
		yu[0][y] = 1;
		yun[0][y] = 1;
		yu[1][y] = 1;
		yun[1][y] = 1;
		yu[width-1][y] = 1;
		yun[width-1][y] = 1;
	}
}

void CFD::CalcPressure()
{
	// 湧出項
	double stotal = 0;
	for(int x=1; x<width-1; x++){
		for(int y=1; y<height-1; y++){
			if( flag[x][y] == WALL ) continue;
			s[x][y] = (-yu[x][y] - yv[x][y] + yu[x+1][y] + yv[x][y+1]) / DT;
			stotal += s[x][y];
		}
	}
	//cerr << "stotal " << stotal << endl;

	Poason();

}

void CFD::Poason()
{
	memset( yp, 0, sizeof(yp) );
	
    double omega = 1.7;
	if( cur_time <= 0.2 ) omega = 1.9;

	// 圧力のポアソン方程式を解く
	for(int i=0;; i++){
		double max_diff = 0;
		for(int x=1; x<width-1; x++){
			for(int y=1; y<height-1; y++){
				if( flag[x][y] == WALL ) continue;
				int pl = flag[x-1][y];
				int pr = flag[x+1][y];
				int pu = flag[x][y-1];
				int pd = flag[x][y+1];
				double diff = omega / 4.0 * (-(pl+pr+pu+pd)*yp[x][y] + pl*yp[x-1][y] + pr*yp[x+1][y] + pu*yp[x][y-1] + pd*yp[x][y+1] - s[x][y]);
				yp[x][y] += diff;
				if( fabs(diff) > max_diff ) max_diff = fabs(diff);
			}
		}

		if( max_diff < 0.01 ){
			// cerr << i << ": " << max_diff << endl;
			break;
		}
		
		if( i >= 10000 ){
			cerr << "error: " << i << " " << cur_time << " " << max_diff << endl;
			assert(0);
		}
	}
}

void CFD::CalcRHS()
{
	// 圧力修正項
	for(int x=1; x<width-1; x++){
		for(int y=1; y<height-1; y++){
			if( flag[x][y] == WALL ) continue;
			yun[x][y] = yu[x][y] - flag[x-1][y] * (yp[x][y] - yp[x-1][y]) * DT;
			yvn[x][y] = yv[x][y] - flag[x][y-1] * (yp[x][y] - yp[x][y-1]) * DT;
		}
	}
	
}

/** マーカーを計算する */
void CFD::CalcMarker()
{
	double color = (int)(cur_time / 20 ) % 2;

	// set marker
	for(int y=1; y<height-1; y++){
		marker[0][y] = color;
	}

	darray mn;
	memset( mn, 0, sizeof(mn) );

	// マーカーの移流を計算する( 一次川上差分法 )
	for(int x=1; x<width-1; x++){
		for(int y=1; y<height-1; y++){
			if( flag[x][y] == WALL ) continue;
			
			double u = (yu[x][y] + yu[x+1][y] ) / 2.0;
			double v = (yv[x][y] + yv[x][y+1] ) / 2.0;
			int is = -copysign(1.0, u);
			int js = -copysign(1.0, v);
			
			mn[x][y] = marker[x][y]
				+ u * is * (marker[x][y] - marker[x+is][y] ) * DT
			    + v * js * (marker[x][y] - marker[x][y+js] ) * DT;
			
		}
	}
	memcpy( marker, mn, sizeof(marker) );
}

void CFD::Dump()
{
	ostream &out = cout;
	out << "{\"cur_time\":" << cur_time << "," << endl;
	puts( yu, out, "\"vx\"" );
	out << ",";
	puts( yv, out, "\"vy\"" );
	out << ",";
	puts( yp, out, "\"p\"" );
	out << ",";
	puts( marker, out, "\"marker\"" );
	out << ",\"flag\":[\n";
	for(int y=0; y<height; y++){
		for(int x=0; x<width; x++){
			out << (int)flag[x][y];
			if( x != width-1 || y != height-1 ) out << ",";
		}
		out << endl;
	}
	out << "]" << endl;
	out << "}" << endl;
}

void puts(const double d[XSIZE][YSIZE], ostream &out, const string &label)
{
	if( !label.empty() ){
		out << label << ":";
		out << "[" << endl;
	}
	for(int y=0; y<YSIZE; y++){
		out << "[";
		for(int x=0; x<XSIZE; x++){
			out << setw(6) << fixed << setprecision(3) << d[x][y];
			if( x < XSIZE-1 ){
				out << ", ";
			}else if( y < YSIZE-1 ){
				out << " ]," << endl;
			}else{
				out << " ]" << endl;
			}
		}
	}
	if( !label.empty() ) out << "]" << endl;
}

int main( int argc, char **argv )
{
	CFD cfd(XSIZE,YSIZE);
	bool comma = false;
	cout << "[" << endl;

	int progress = 0;
	for(int i=0;; i++){
		cfd.Step();
		
		int next_progress = cfd.cur_time / END_TIME * 100;
		if( next_progress > progress ){
			progress = next_progress;
			cerr << "+";
		}
		
		if( i % SKIP == 0 ){
			if( comma ) cout << ",";
			comma = true;
			cfd.Dump();
			if( cfd.cur_time >= END_TIME ) break;
		}
	}
	cerr << endl;
	cout << "]" << endl;
	// puts( cfd.vx, cout, "\"vx\"" );
	return 0;
}

