using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
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

namespace MGEDConsoleLauncher
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private string _inputFile = null, _outputFile = null;
        private Process _process = new Process(); 

        public MainWindow()
        {
            InitializeComponent();
        }

        private void InputFile_Button_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog ofd = new OpenFileDialog();
            if (ofd.ShowDialog() == true)
            {
                _inputFile = ofd.FileName;
                InputFile_TextBox.Text = _inputFile; 
            }
        }

        private void OutputFile_Button_Click(object sender, RoutedEventArgs e)
        {
            SaveFileDialog sfd = new SaveFileDialog();
            if (sfd.ShowDialog() == true)
            {
                _outputFile = sfd.FileName;
                OutputFile_TextBox.Text = _outputFile; 
            }
        }

        private void Launch_Button_Click(object sender, RoutedEventArgs e)
        {
            string toLaunch = "Apps\\";

            if (CSV_RadioButton.IsChecked == true)
            {
                toLaunch += "mged_data_csv.exe"; 
            }
            else if (DataPhaser_RadioButton.IsChecked == true)
            {
                toLaunch += "mged_data_csv.exe"; 
            }
            else if (DataSplitter_RadioButton.IsChecked == true)
            {
                toLaunch += "mged_data_csv.exe"; 
            }

            string arguments = string.Format("'{0}', '{1}' {2}", _inputFile, _outputFile, OutputFile_TextBox_Copy.Text);
            
            _process.StartInfo = new ProcessStartInfo(toLaunch, arguments);
            _process.StartInfo.UseShellExecute = false; 
            _process.StartInfo.RedirectStandardOutput = true;
            _process.Start();

            string output = _process.StandardOutput.ReadToEnd();
            _process.WaitForExit();

            return; 
        }
    }
}
