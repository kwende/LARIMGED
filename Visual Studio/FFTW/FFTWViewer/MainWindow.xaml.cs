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
        private double[] _data = null; 

        public MainWindow()
        {
            InitializeComponent();
        }

        private void DoIt(double[] data, int maxToProcess)
        {
            if (data.Length > 0)
            {
                double smallest = data.Min();
                double largest = data.Max();

                FFTW fftw = new FFTW();
                double[] output = fftw.Process(data, maxToProcess);

            }
        }

        private void Button_Click_1(object sender, RoutedEventArgs e)
        {
            try
            {
                OpenFileDialog ofd = new OpenFileDialog();
                ofd.Filter = "Text Files (*.txt)|*.txt";
                if (ofd.ShowDialog() == true)
                {
                    _currentOpenFile = ofd.FileName;
                    TextBox_LoadedFile.Text = _currentOpenFile;

                    _data = DataLoader.Load(_currentOpenFile);

                    DoIt(_data, 1);

                    slider.Minimum = 1;
                    slider.Maximum = _data.Length / 2 + 1;

                    return;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString()); 
            }
        }

        private void slider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            DoIt(_data, (int)slider.Value);
            TextBox_Value.Text = ((int)slider.Value).ToString(); 
            return; 
        }

        private void Window_Loaded_1(object sender, RoutedEventArgs e)
        {

        }
    }
}
