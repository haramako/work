#include <stdio.h>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <math.h>
#include <memory.h>

using namespace std;

const double DT = 0.02;
const double RE = 0.003;
const int XSIZE = 128;
const int YSIZE = 32;
const int END_TIME = 400;
const int SKIP = 4/DT;

void puts(double d[XSIZE][YSIZE], ostream &out = cout, const string &label = "");

class CFD {
public:
	CFD(int width, int height);
	~CFD(){}

	void Step();
	void Dump();
	
	const int WALL = 0;
	const int VALID = 1;
	
	//private:
	void CalcIryu();
	void CalcGairyoku();
	void CalcAtsuryoku();
	void Poason();
	
	int width;
	int height;
	double cur_time;
	double vx[XSIZE][YSIZE];
	double vy[XSIZE][YSIZE];
	double next_vx[XSIZE][YSIZE];
	double next_vy[XSIZE][YSIZE];
	double p[XSIZE][YSIZE];
	double s[XSIZE][YSIZE];
	char flag[XSIZE][YSIZE]; // 0: 壁, 1: 有効面
};

CFD::CFD(int width_, int height_):
	width(width_), height(height_), cur_time(0)
{
	for(int x=0; x<width; x++){
		for(int y=0; y<height; y++){
			vx[x][y] = 0.0;
			vy[x][y] = 0.0;
			next_vx[x][y] = 0.0;
			next_vy[x][y] = 0.0;
			p[x][y] = 0.0;
			s[x][y] = 0.0;
			flag[x][y] = 1;
		}
	}

	for(int x=0; x<width; x++){
		flag[x][0] = 0;
		flag[x][height-1] = 0;
	}
	
	for(int y=0; y<height; y++){
		flag[0][y] = 0;
		flag[width-1][y] = 0;
	}

	for(int x=18; x<=20; x++ ){
		for(int y=12; y<=16; y++ ){
			flag[x][y] = 0;
		}
	}
	for(int x=17; x<=21; x++ ){
		for(int y=13; y<=15; y++ ){
			flag[x][y] = 0;
		}
	}

	/*
	for(int x=12; x<=14; x++ ){
		for(int y=20; y<=26; y++ ){
			flag[x][y] = 0;
		}
	}
	*/
}

void CFD::Step()
{
	CalcIryu();
	CalcGairyoku();
	CalcAtsuryoku();
	cur_time += DT;
}

void CFD::CalcIryu()
{
	// 移流項
	int cx, cy;
	double u, v;
	for(int x=1; x<width-1; x++){
		for(int y=1; y<height-1; y++){
			u = vx[x][y];
			v = (vy[x-1][y] + vy[x][y] + vy[x-1][y+1] + vy[x][y+1] ) / 4.0;
			if( v >= 0 ){ cy = -1; }else{ cy = 1; }
			if( u >= 0 ){ cx = -1; }else{ cx = 1; }
			next_vx[x][y] = vx[x][y] + cx * u * (vx[x][y] - vx[x+cx][y]) * DT + cy * v * (vx[x][y] - vx[x][y+cy]) * DT;

			u = vy[x][y];
			v = (vx[x][y-1] + vx[x][y] + vx[x+1][y-1] + vx[x+1][y] ) / 4.0;
			if( v >= 0 ){ cx = -1; }else{ cx = 1; }
			if( u >= 0 ){ cy = -1; }else{ cy = 1; }
			next_vy[x][y] = vy[x][y] + cy * u * (vy[x][y] - vy[x][y+cy]) * DT + cx * v * (vy[x][y] - vy[x+cx][y]) * DT;
			
		}
	}

	// 粘性項
	for(int x=1; x<width-1; x++){
		for(int y=1; y<height-1; y++){
			next_vx[x][y] += RE * (vx[x+1][y] + vx[x][y+1] + vx[x-1][y] + vx[x][y-1]) * DT;
			next_vy[x][y] += RE * (vy[x+1][y] + vy[x][y+1] + vy[x-1][y] + vy[x][y-1]) * DT;
		}
	}
	memcpy( vx, next_vx, sizeof(vx) );
	memcpy( vy, next_vy, sizeof(vy) );
}

void CFD::CalcGairyoku()
{
	for(int x=0; x<width; x++){
		for(int y=0; y<height; y++){
			if( flag[x][y] == WALL ){
				vx[x][y] = 0;
				if( x < width-1 ) vx[x+1][y] = 0;
				vy[x][y] = 0;
				if( y < height-1 ) vy[x][y+1] = 0;
			}
		}
	}
	
	for(int y=0; y<height; y++){
		vx[1][y] = 1.0;
		vx[width-1][y] = 1.0;
	}
}

void CFD::CalcAtsuryoku()
{
	// 湧出項
	double total_p = 0;
	int count_p = 0;
	for(int x=1; x<width-1; x++){
		for(int y=1; y<height-1; y++){
			if( flag[x][y] == WALL ) continue;
			s[x][y] = (-vx[x][y] - vy[x][y] + vx[x+1][y] + vy[x][y+1]) / DT;
			total_p += p[x][y];
			count_p++;
		}
	}

	double average_p = total_p / count_p;
	for(int x=1; x<width-1; x++){
		for(int y=1; y<height-1; y++){
			if( flag[x][y] == WALL ) continue;
			p[x][y] -= average_p;
		}
	}

	Poason();

	// 圧力修正項
	for(int x=1; x<width-1; x++){
		for(int y=1; y<height-1; y++){
			if( flag[x][y] == WALL ) continue;
			vx[x][y] -= flag[x-1][y] * (p[x][y] - p[x-1][y]) * DT;
			vy[x][y] -= flag[x][y-1] * (p[x][y] - p[x][y-1]) * DT;
		}
	}
	
}

void CFD::Poason()
{
    double omega = 1.7;
	if( cur_time <= 0.2 ) omega = 1.9;
	
	// 圧力のポアソン方程式を解く
	for(int i=0;; i++){
		double max_diff = 0;
		for(int x=1; x<width-1; x++){
			for(int y=1; y<height-1; y++){
				// if( flag[x][y] == WALL ) continue;
				int pl = flag[x-1][y];
				int pr = flag[x+1][y];
				int pu = flag[x][y-1];
				int pd = flag[x][y+1];
				double diff = omega / 4.0 * (-(pl+pr+pu+pd)*p[x][y] + pl*p[x-1][y] + pr*p[x+1][y] + pu*p[x][y-1] + pd*p[x][y+1] - s[x][y]);
				p[x][y] += diff;
				if( fabs(diff) > max_diff ) max_diff = fabs(diff);
			}
		}

		if( max_diff < 0.001 ){
			// cerr << i << ": " << max_diff << endl;
			break;
		}
	}
}

void CFD::Dump()
{
	ostream &out = cout;
	out << "{\"cur_time\":" << cur_time << "," << endl;
	puts( vx, out, "\"vx\"" );
	out << ",";
	puts( vy, out, "\"vy\"" );
	out << ",";
	puts( p, out, "\"p\"" );
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

void puts(double d[XSIZE][YSIZE], ostream &out, const string &label)
{
	if( !label.empty() ){
		out << label << ":";
		out << "[" << endl;
	}
	for(int y=0; y<YSIZE; y++){
		out << "[";
		for(int x=0; x<XSIZE; x++){
			out << /*setw(6) << fixed << */setprecision(3) << d[x][y];
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

