__kernel void vec_add(size_t n, __global float4* z, 
					  __global float4* x, __global float4* y)
{
	n = n / 4;
	for(size_t i=0; i<n; i+=1){
		z[i] = x[i]*x[i] + y[i]*y[i];
	}
}
