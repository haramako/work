__kernel void vec_add(__global float4 *z, 
					  __global float4 *x, __global float4 *y)
{
	const int i = get_global_id(0);
	z[i] = x[i]*x[i] + y[i]*y[i];
}
