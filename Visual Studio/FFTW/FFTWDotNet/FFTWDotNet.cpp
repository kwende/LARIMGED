// This is the main DLL file.

#include "stdafx.h"

#include "FFTWDotNet.h"

using namespace Lowell::MGED;
using namespace std; 

array<double>^ FFTW::Process(array<double>^ input, int numberOfSignalsToPreserve)
{
	int N = input->Length; 

	double *in, *in2;
	fftw_complex *out; 
	fftw_plan plan_forward, plan_backward;

	// allocate memory arrays
	in = (double*) fftw_malloc(sizeof(double) * N);
	in2 = (double*) fftw_malloc(sizeof(double) * N);

	out = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N/2+1); 

	fftw_complex* out2 = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N/2+1);
	memset(out2, 0, sizeof(fftw_complex) * N/2+1); 

	// construct plans
	plan_forward = fftw_plan_dft_r2c_1d(N, in, out, FFTW_ESTIMATE);
	plan_backward = fftw_plan_dft_c2r_1d(N, out2, in2, FFTW_ESTIMATE); 

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

	map<double, int> sortedMap; 
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

		sortedMap.insert( pair<double, int>(modulo, c) ); 
	}

	map<double, int>::reverse_iterator  it;
	int c=0; 
	for (it = sortedMap.rbegin(); it != sortedMap.rend() && c < numberOfSignalsToPreserve; c++, ++it)
	{
		double key = (*it).first; 
		int val = (*it).second;

		out2[val][0] = out[val][0];
		out2[val][1] = out[val][1];
	}

	out2[0][0] = out[0][0];
	out2[0][1] = out[0][1];

	fftw_execute(plan_backward); 

	array<double>^ ret = gcnew array<double>(N); 
	for(int c=0;c<N;c++)
	{
		ret[c] = in2[c] / ((double)N); 
	}
	return ret; 
}