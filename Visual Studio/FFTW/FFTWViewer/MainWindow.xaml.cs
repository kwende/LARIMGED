using Lowell.MGED;
using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using Visiblox.Charts;

namespace FFTWViewer
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private string _currentOpenFile = null; 

        public MainWindow()
        {
            InitializeComponent();
        }

        private void Button_Click_1(object sender, RoutedEventArgs e)
        {
            OpenFileDialog ofd = new OpenFileDialog();
            ofd.Filter = "Text Files (*.txt)|*.txt";
            if (ofd.ShowDialog() == true)
            {
                _currentOpenFile = ofd.FileName;
                TextBox_LoadedFile.Text = _currentOpenFile;

                double[] data = DataLoader.Load(_currentOpenFile);

                if (data.Length > 0)
                {
                    double smallest = data.Min();
                    double largest = data.Max();

                    FFTW fftw = new FFTW();
                    double[] output = fftw.Process(data);

                    DataSeries<double, double> xLiftData = new DataSeries<double, double>("Input");
                    for (int x = 0; x < output.Length; x++)
                    {
                        xLiftData.Add(new DataPoint<double, double> { X = x, Y = data[x] });
                    }
                    exampleChart.Series[0].DataSeries = xLiftData;

                    DataSeries<double, double> xLiftData2 = new DataSeries<double, double>("Output");
                    for (int x = 0; x < data.Length; x++)
                    {
                        xLiftData2.Add(new DataPoint<double, double> { X = x, Y = output[x] });
                    }
                    exampleChart.Series[1].DataSeries = xLiftData2;


                    exampleChart.Series[0].YAxis.Range = new DoubleRange(smallest, largest);
                }
                return; 
            }
        }
    }
}
