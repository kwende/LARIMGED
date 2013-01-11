using Lowell.MGED;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FFTWViewer
{
    public class FFTWHelper
    {
        public double[] Process(double[] data, int maxToProcess)
        {
            double[] output = null; 
            if (data.Length > 0)
            {
                double smallest = data.Min();
                double largest = data.Max();

                FFTW fftw = new FFTW();
                output = fftw.Process(data, maxToProcess);
            }
            return output; 
        }
    }
}
