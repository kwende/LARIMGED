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

using namespace System;

namespace Lowell {
	namespace MGED {
		public ref class FFTW
		{
		public:
			array<double>^ Process(array<double>^ input);   
		};
	}
}
