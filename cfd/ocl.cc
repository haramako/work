#include "stdafx.h"
#include <iostream>
#include <fstream>
#ifdef darwin
#include <OpenCL/opencl.h>
#else
#include <CL/opencl.h>
#endif
#include <assert.h>
#include <string>

using namespace std;


const char * get_error_string(cl_int err);
#define CHK() if( ret != CL_SUCCESS ){ cout << "error: "<< get_error_string(ret) << "(" << ret << ")" << endl; throw(0); }
#define CHECK(exp) { ret = exp; CHK(); }

void vec_add(size_t n, float* z, float* x, float* y);

#ifdef WIN32
int _tmain(int argc, TCHAR *argv[])
#else
int main(int argc, char **argv)
#endif
{
	cl_int ret;
	char tmp[256*256];

	if( argc <= 2 ){
		cout << "no args" << endl;
		return 0;
	}
	int type = atoi(argv[1]);
	size_t n = atoi(argv[2]);
	size_t repeat = 1;
	if( argc > 3 ) repeat = atoi(argv[3]);

	size_t source_size[1];
	char *source_str[1];
	ifstream fs("kernel.cl");
	string src0;
	getline(fs, src0, '\0');
	source_size[0] = src0.length();
	source_str[0] = (char*)src0.c_str();

	cl_platform_id platform_id;
	cl_uint ret_num_platforms;
	ret = clGetPlatformIDs(1, &platform_id, &ret_num_platforms);
	CHK();
	clGetPlatformInfo( platform_id, CL_PLATFORM_VERSION, sizeof(tmp), tmp, NULL );
	// cout << tmp << endl;

	cl_device_id device_id;
	cl_uint ret_num_devices;
	CHECK( clGetDeviceIDs(platform_id, CL_DEVICE_TYPE_DEFAULT, 1, &device_id, &ret_num_devices) );
	clGetDeviceInfo(device_id, CL_DEVICE_NAME, sizeof(tmp), tmp, NULL );
	// cout << tmp << endl;

	cl_uint tmpi;
	CHECK(clGetDeviceInfo(device_id, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(tmpi), &tmpi, NULL));
	cout << tmpi << endl;
	//exit(0);
	
	cl_context context = clCreateContext(NULL, 1, &device_id, NULL, NULL, &ret); CHK();
	cl_command_queue command_queue = clCreateCommandQueue(context, device_id, 0, &ret); CHK();

	cl_program program = clCreateProgramWithSource(context, 1, (const char**)&source_str, (const size_t*)&source_size, &ret); CHK();

	ret = clBuildProgram(program, 1, &device_id, NULL, NULL, NULL);
	if( ret != CL_SUCCESS ){
		cout << "error" << endl;
		CHECK( clGetProgramBuildInfo(program, device_id, CL_PROGRAM_BUILD_LOG, sizeof(tmp), tmp, NULL) );
		cout << tmp << endl;
		exit(0);
	}

	cl_kernel kernel = clCreateKernel(program, "vec_add", &ret); CHK();

	cl_mem z_dev = clCreateBuffer(context, CL_MEM_WRITE_ONLY, n*sizeof(float), NULL, &ret); CHK();
	cl_mem x_dev = clCreateBuffer(context, CL_MEM_READ_ONLY, n*sizeof(float), NULL, &ret); CHK();
	cl_mem y_dev = clCreateBuffer(context, CL_MEM_READ_ONLY, n*sizeof(float), NULL, &ret); CHK();

	float *x = new float[n];
	float *y = new float[n];
	float *z = new float[n];

	for( size_t i=0; i<n; i++ ){
		//x[i] = rand()%100;
		//y[i] = rand()%100;
		x[i] = i;
		y[i] = i;
		z[i] = 0;
	}
	
	if( type == 0 ){
		clEnqueueWriteBuffer(command_queue, x_dev, CL_TRUE, 0, n * sizeof(float), x, 0, NULL, NULL);
		clEnqueueWriteBuffer(command_queue, y_dev, CL_TRUE, 0, n * sizeof(float), y, 0, NULL, NULL);
		clEnqueueWriteBuffer(command_queue, z_dev, CL_TRUE, 0, n * sizeof(float), z, 0, NULL, NULL);
		CHECK( clEnqueueBarrier(command_queue) );

		for( size_t j=0; j<repeat; j++ ){
			CHECK( clSetKernelArg(kernel, 0, sizeof(cl_mem), &z_dev) );
			CHECK( clSetKernelArg(kernel, 1, sizeof(cl_mem), &x_dev) );
			CHECK( clSetKernelArg(kernel, 2, sizeof(cl_mem), &y_dev) );
			size_t gsize = n/4;
			size_t lsize = n/4;
			if (lsize > 512) lsize = 512;
			CHECK( clEnqueueNDRangeKernel(command_queue, kernel, 1, nullptr, &gsize, &lsize, 0, NULL, NULL) );
			CHECK(clEnqueueBarrier(command_queue));
			/*
			if (j % 10000 == 0){
				cl_event event = clCreateUserEvent(context, &ret); CHK();
				CHECK(clEnqueueMarker(command_queue, &event));
				CHECK(clWaitForEvents(1, &event));
				//cout << j << endl;
			}
			*/
		}

		CHECK(clEnqueueBarrier(command_queue));
		CHECK(clEnqueueReadBuffer(command_queue, z_dev, CL_TRUE, 0, n * sizeof(float), z, 0, NULL, NULL));
		cout << "end" << endl;
	}else{
		for( size_t j=0; j<repeat; j++ ){
			vec_add(n,z,x,y);
		}
	}

	if( n <= 100 ){
		for( size_t i=0; i<n; i++ ){
			cout << z[i] << ", ";
		}
		cout << endl;
	}

	return 0;
}

#include <math.h>

void vec_add(size_t n, float* __restrict z, float* __restrict x, float* __restrict y)
{
	for(size_t i=0; i<n; i++){
		z[i] = x[i]*x[i] + y[i]*y[i];
	}
}



const char * get_error_string(cl_int err){
	switch(err){
	case 0: return "CL_SUCCESS";
	case -1: return "CL_DEVICE_NOT_FOUND";
	case -2: return "CL_DEVICE_NOT_AVAILABLE";
	case -3: return "CL_COMPILER_NOT_AVAILABLE";
	case -4: return "CL_MEM_OBJECT_ALLOCATION_FAILURE";
	case -5: return "CL_OUT_OF_RESOURCES";
	case -6: return "CL_OUT_OF_HOST_MEMORY";
	case -7: return "CL_PROFILING_INFO_NOT_AVAILABLE";
	case -8: return "CL_MEM_COPY_OVERLAP";
	case -9: return "CL_IMAGE_FORMAT_MISMATCH";
	case -10: return "CL_IMAGE_FORMAT_NOT_SUPPORTED";
	case -11: return "CL_BUILD_PROGRAM_FAILURE";
	case -12: return "CL_MAP_FAILURE";

	case -30: return "CL_INVALID_VALUE";
	case -31: return "CL_INVALID_DEVICE_TYPE";
	case -32: return "CL_INVALID_PLATFORM";
	case -33: return "CL_INVALID_DEVICE";
	case -34: return "CL_INVALID_CONTEXT";
	case -35: return "CL_INVALID_QUEUE_PROPERTIES";
	case -36: return "CL_INVALID_COMMAND_QUEUE";
	case -37: return "CL_INVALID_HOST_PTR";
	case -38: return "CL_INVALID_MEM_OBJECT";
	case -39: return "CL_INVALID_IMAGE_FORMAT_DESCRIPTOR";
	case -40: return "CL_INVALID_IMAGE_SIZE";
	case -41: return "CL_INVALID_SAMPLER";
	case -42: return "CL_INVALID_BINARY";
	case -43: return "CL_INVALID_BUILD_OPTIONS";
	case -44: return "CL_INVALID_PROGRAM";
	case -45: return "CL_INVALID_PROGRAM_EXECUTABLE";
	case -46: return "CL_INVALID_KERNEL_NAME";
	case -47: return "CL_INVALID_KERNEL_DEFINITION";
	case -48: return "CL_INVALID_KERNEL";
	case -49: return "CL_INVALID_ARG_INDEX";
	case -50: return "CL_INVALID_ARG_VALUE";
	case -51: return "CL_INVALID_ARG_SIZE";
	case -52: return "CL_INVALID_KERNEL_ARGS";
	case -53: return "CL_INVALID_WORK_DIMENSION";
	case -54: return "CL_INVALID_WORK_GROUP_SIZE";
	case -55: return "CL_INVALID_WORK_ITEM_SIZE";
	case -56: return "CL_INVALID_GLOBAL_OFFSET";
	case -57: return "CL_INVALID_EVENT_WAIT_LIST";
	case -58: return "CL_INVALID_EVENT";
	case -59: return "CL_INVALID_OPERATION";
	case -60: return "CL_INVALID_GL_OBJECT";
	case -61: return "CL_INVALID_BUFFER_SIZE";
	case -62: return "CL_INVALID_MIP_LEVEL";
	case -63: return "CL_INVALID_GLOBAL_WORK_SIZE";
	default: return "Unknown OpenCL error";
	}
}
