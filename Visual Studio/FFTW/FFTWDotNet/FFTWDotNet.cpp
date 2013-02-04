// This is the main DLL file.

#include "stdafx.h"

#include "FFTWDotNet.h"

using namespace Lowell::MGED;
using namespace std; 

array<double>^ FFTW::Backward(array<Complex>^ input)
{
	int N = (input->Length * 2) - 1;

	double* out; 
	fftw_plan plan_backward; 

	out = (double*) fftw_malloc(sizeof(double) * N);
	fftw_complex* in = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N/2+1);

	for(int c=0;c<input->Length;c++)
	{
		in[c][0] = input[c].Real; 
		in[c][1] = input[c].Imaginary; 
	}

	plan_backward = fftw_plan_dft_c2r_1d(N, in, out, FFTW_ESTIMATE);

	fftw_execute(plan_backward);

	array<double>^ arr = gcnew array<double>(N); 
	for(int c=0;c<N;c++)
	{
		arr[c] = out[c];
	}

	return arr; 
}

array<Complex>^ FFTW::Forward(array<double>^ input)
{
	int N = input->Length; 

	double *in;
	fftw_complex *out; 
	fftw_plan plan_forward;

	// allocate memory arrays
	in = (double*) fftw_malloc(sizeof(double) * N);
	out = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N/2+1); 

	// construct plans
	plan_forward = fftw_plan_dft_r2c_1d(N, in, out, FFTW_ESTIMATE);

	// copy data
	for(int c=0;c<N;c++)
	{
		in[c] = input[c]; 
	}

	//execute forward plan
	fftw_execute(plan_forward);

	array<Complex>^ arr = gcnew array<Complex>(N/2+1); 

	// copy data into array of Complex type.
	for(int c=0;c<N/2+1;c++)
	{
		arr[c] = Complex(out[c][0], out[c][1]); 
	}

	return arr; 
}