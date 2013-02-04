using FFTWFileHelper;
using Lowell.MGED;
using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Numerics;
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

namespace FFTWFrequencyManipulator
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public ObservableCollection<CheckBoxBinder> TheList { get; set; }
        private Complex[] _frequencyDomain, _frequencyDomainLinkedToCheckboxes;
        private double[] _input, _ret; 

        public MainWindow()
        {
            InitializeComponent();
        }

        private void Button_Click_1(object sender, RoutedEventArgs e)
        {
            OpenFileDialog ofd = new OpenFileDialog();
            if (ofd.ShowDialog() == true)
            {
                TextBox_InputName.Text = ofd.FileName;

                FFTW fftw = new FFTW();
                _input = DataLoader.Load(ofd.FileName);
                double[] inputCopy = new double[_input.Length];
                _input.CopyTo(inputCopy, 0);

                _frequencyDomain = fftw.Forward(inputCopy);
                _frequencyDomainLinkedToCheckboxes = new Complex[_frequencyDomain.Length]; 

                _frequencyDomain.CopyTo(_frequencyDomainLinkedToCheckboxes, 0); 

                DataSeries<double, double> points = new DataSeries<double, double>("Magnitudes");
                TheList = new ObservableCollection<CheckBoxBinder>();
                List<CheckBoxBinder> mags = new List<CheckBoxBinder>();
                for (int c = 0; c < _frequencyDomain.Length; c++)
                {
                    points.Add(new DataPoint<double, double> { X = c, Y = _frequencyDomain[c].Magnitude });
                    mags.Add(new CheckBoxBinder { TheValue = _frequencyDomain[c].Magnitude, Index = c });
                }

                foreach (CheckBoxBinder d in mags.OrderByDescending(m => m.TheValue))
                {
                    TheList.Add(d);
                }

                exampleChart.Series[0].DataSeries = points;
                this.DataContext = this;

                DataSeries<double, double> data = new DataSeries<double, double>("Data");
                for (int c = 0; c < _input.Length; c++)
                {
                    data.Add(new DataPoint<double, double> { X = c, Y = _input[c] });
                }

                dataChart.Series[0].DataSeries = data;

                return;
            }
        }

        private void Checkbox_Checked_1(object sender, RoutedEventArgs e)
        {

        }

        private void Checkbox_Click_1(object sender, RoutedEventArgs e)
        {
            CheckBox checkbox = (CheckBox)sender;
            int index = (int)checkbox.Tag;

            if (checkbox.IsChecked == true)
            {
                _frequencyDomainLinkedToCheckboxes[index] = new Complex();
            }
            else
            {
                _frequencyDomainLinkedToCheckboxes[index] = _frequencyDomain[index];
            }

            FFTW fftw = new FFTW();
            _ret = fftw.Backward(_frequencyDomainLinkedToCheckboxes);

            DataSeries<double, double> points = new DataSeries<double, double>("Data");
            for (int c = 0; c < _ret.Length; c++)
            {
                points.Add(new DataPoint<double, double> { X = c, Y = _ret[c] });
            }

            dataChart.Series[0].DataSeries = points;
        }

        private void Button_Click_2(object sender, RoutedEventArgs e)
        {
            if (_ret != null)
            {
                SaveFileDialog sfd = new SaveFileDialog();
                if (sfd.ShowDialog() == true)
                {
                    using (FileStream fout = File.OpenWrite(sfd.FileName))
                    {
                        using (StreamWriter sw = new StreamWriter(fout))
                        {
                            for (int c = 0; c < _ret.Length; c++)
                            {
                                sw.WriteLine(_ret[c].ToString());
                            }
                        }
                    }
                }
            }
        }
    }
}
