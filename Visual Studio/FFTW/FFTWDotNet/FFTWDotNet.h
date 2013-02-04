// FFTWDotNet.h

#pragma once

#include <fftw3.h>
#include <math.h>
#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <algorithm>
#include <iterator>
#include <vector>
#include <map>

using namespace System;
using namespace System::Numerics; 

namespace Lowell {
	namespace MGED {
		public ref class FFTW
		{
		public:
			array<Complex>^ Forward(array<double>^ input); 
			array<double>^ Backward(array<Complex>^ input); 
		};
	}
}
