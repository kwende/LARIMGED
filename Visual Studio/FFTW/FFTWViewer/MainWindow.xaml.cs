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
        public string[] DropDownChoices = new string[] { "Raw Data", "FFTW and Raw Data", "FFTW minus Raw Data" };

        private string _currentOpenFile = null;
        private double[] _data = null;
        private GraphHelper _graphHelper = null;
        private FFTWHelper _fftwHelper = null;

        public MainWindow()
        {
            InitializeComponent();
        }

        private void DrawGraphBasedOnDropDown(double[] rawData, int index)
        {
            if (rawData != null && rawData.Length > 0)
            {
                GraphData[] graphs = null;
                switch (index)
                {
                    case 0:
                        graphs = GraphDataHelper.GenerateForRawData(rawData);
                        break;
                    case 1:
                        graphs = GraphDataHelper.GenerateForRawDataAndFFTW(rawData, _fftwHelper.Process(rawData, 1));
                        break;
                    case 2:
                        double[] result = new double[rawData.Length];
                        double[] fftw = _fftwHelper.Process(rawData, 1);
                        for (int c = 0; c < rawData.Length; c++)
                        {
                            result[c] = rawData[c] - fftw[c];
                        }
                        graphs = GraphDataHelper.GenerateForRawDataMinusFFTW(result);
                        break;
                }
                _graphHelper.Update(graphs);
            }
        }

        private void Button_Click_1(object sender, RoutedEventArgs e)
        {
            OpenFileDialog ofd = new OpenFileDialog();
            ofd.Filter = "Text Files (*.txt)|*.txt";
            if (ofd.ShowDialog() == true)
            {
                _currentOpenFile = ofd.FileName;
                TextBox_LoadedFile.Text = _currentOpenFile;

                _data = DataLoader.Load(_currentOpenFile);

                DrawGraphBasedOnDropDown(_data, ComboBox_Input.SelectedIndex);

                slider.Minimum = 1;
                slider.Maximum = _data.Length / 2 + 1;

                return;
            }
        }

        private void Window_Loaded_1(object sender, RoutedEventArgs e)
        {
            _graphHelper = new GraphHelper(exampleChart);
            _fftwHelper = new FFTWHelper();

            foreach (string choice in DropDownChoices)
            {
                ComboBox_Input.Items.Add(new ComboBoxItem { Content = choice });
            }
        }

        private void ComboBox_Input_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (ComboBox_Input.SelectedIndex >= 0)
            {
                DrawGraphBasedOnDropDown(_data, ComboBox_Input.SelectedIndex);
            }
        }
    }
}
