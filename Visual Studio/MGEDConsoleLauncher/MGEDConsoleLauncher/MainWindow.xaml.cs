using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
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
        public ObservableCollection<ProcessListItem> Items { get; set; }
        private string _toLaunch = ""; 

        public MainWindow()
        {
            InitializeComponent();

            Items = new ObservableCollection<ProcessListItem>();

            string[] files = Directory.GetFiles(System.IO.Path.Combine(Directory.GetCurrentDirectory(), "Apps"), "*exe");
            foreach (string file in files)
            {
                Items.Add(new ProcessListItem { TheText = System.IO.Path.GetFileName(file), TheValue = file });
            }

            this.DataContext = Items;
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
            if (!string.IsNullOrEmpty(_toLaunch))
            {
                TextBlock_Output.Text = ""; 

                Process process = new Process();

                process.StartInfo.FileName = _toLaunch;
                process.StartInfo.Arguments = string.Format("\"{0}\" \"{1}\" {2}", _inputFile, _outputFile, OutputFile_TextBox_Copy.Text);

                process.StartInfo.CreateNoWindow = false;
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                process.StartInfo.RedirectStandardInput = true;
                process.StartInfo.RedirectStandardOutput = true;
                process.StartInfo.RedirectStandardError = true;

                process.EnableRaisingEvents = true;
                process.OutputDataReceived += process_OutputDataReceived;
                process.ErrorDataReceived += process_ErrorDataReceived;
                process.Exited += process_Exited;
                process.Start();

                process.BeginOutputReadLine();
                process.BeginErrorReadLine();

                return;
            }
        }

        void process_Exited(object sender, EventArgs e)
        {


            Dispatcher.BeginInvoke((Action)delegate()
            {
                TextBlock_Output.Text += "Process exited with value " + ((Process)sender).ExitCode + "\n";
                TextBlock_Output.Text += "Process completed in " +
                    ((DateTime.Now - ((Process)sender).StartTime)).TotalSeconds + " seconds.\n";
            });
        }

        void process_ErrorDataReceived(object sender, DataReceivedEventArgs e)
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                Dispatcher.BeginInvoke((Action)delegate()
                {
                    TextBlock_Output.Text += e.Data + "\n";
                });
            }

            return;
        }

        void process_OutputDataReceived(object sender, DataReceivedEventArgs e)
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                Dispatcher.BeginInvoke((Action)delegate()
                {
                    TextBlock_Output.Text += e.Data + "\n";
                });
            }

            return;
        }

        private void RadioButton_Checked_1(object sender, RoutedEventArgs e)
        {
            _toLaunch = ((RadioButton)e.Source).Tag.ToString(); 

            return; 
        }
    }
}
