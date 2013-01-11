using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Media;

namespace FFTWViewer
{
    public static class GraphDataHelper
    {
        public static GraphData[] GenerateForRawData(double[] data)
        {
            return new GraphData[] { new GraphData(Brushes.Black, data, "Raw Data") }; 
        }

        public static GraphData[] GenerateForRawDataAndFFTW(double[] rawData, double[] fftwData)
        {
            return new GraphData[] { new GraphData(Brushes.Red, rawData, "Raw Data"), new GraphData(Brushes.Black, fftwData, "FFTW") }; 
        }

        public static GraphData[] GenerateForRawDataMinusFFTW(double[] data)
        {
            return new GraphData[] { new GraphData(Brushes.Black, data, "FFTW Subtracted") }; 
        }
    }
}
