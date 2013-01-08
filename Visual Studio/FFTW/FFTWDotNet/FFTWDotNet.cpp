// This is the main DLL file.

#include "stdafx.h"

#include "FFTWDotNet.h"

using namespace Lowell::MGED;

array<double>^ FFTW::Process(array<double>^ input)
{
	
	int N = input->Length; 

	double *in, *in2;
	fftw_complex *out; 
	fftw_plan plan_forward, plan_backward;

	// allocate memory arrays
	in = (double*) fftw_malloc(sizeof(double) * N);
	in2 = (double*) fftw_malloc(sizeof(double) * N);
	out = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N/2+1); 

	// construct plans
	plan_forward = fftw_plan_dft_r2c_1d(N, in, out, FFTW_ESTIMATE);
	plan_backward = fftw_plan_dft_c2r_1d(N, out, in2, FFTW_ESTIMATE); 

	// copy data into in
	for(int c=0;c<N;c++)
	{
		in[c] = input[c]; 
	}

	// execute forward plan
	fftw_execute(plan_forward);

	// strip out everything but the highest level
	double largestModulo = 0.0; 
	int largestModuloIndex = -1; 
	for(int c=1;c<N/2+1;c++)
	{
		//out[c][0] = 0; 
		//out[c][1] = 0; 
		double modulo = sqrt(pow(out[c][0],2) + pow(out[c][1],2));  
		if(modulo > largestModulo)
		{
			largestModulo = modulo; 
			largestModuloIndex = c; 
		}
	}

	for(int c=1;c<N/2+1;c++)
	{
		if(c != largestModuloIndex)
		{
			out[c][0] = out[c][1] = 0; 
		}
	}

	fftw_execute(plan_backward); 

	array<double>^ ret = gcnew array<double>(N); 
	for(int c=0;c<N;c++)
	{
		ret[c] = in2[c] / ((double)N); 
	}
	return ret; 
}