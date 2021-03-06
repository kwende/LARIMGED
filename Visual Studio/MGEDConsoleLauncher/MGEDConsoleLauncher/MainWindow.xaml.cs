﻿using Microsoft.Win32;
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
using System.Windows.Forms;
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
        public ObservableCollection<ProcessListItem> Items { get; set; }
        private string _toLaunch = "";
        private StringBuilder _outputText = new StringBuilder(10240);

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
            Microsoft.Win32.OpenFileDialog ofd = new Microsoft.Win32.OpenFileDialog();
            if (ofd.ShowDialog() == true)
            {
                InputFile_TextBox.Text = ofd.FileName;
            }
        }

        private void OutputFile_Button_Click(object sender, RoutedEventArgs e)
        {
            Microsoft.Win32.SaveFileDialog sfd = new Microsoft.Win32.SaveFileDialog();
            if (sfd.ShowDialog() == true)
            {
                OutputFile_TextBox.Text = sfd.FileName;
            }
        }


        private void OutputDir_Button_Click(object sender, RoutedEventArgs e)
        {
            FolderBrowserDialog d = new FolderBrowserDialog();
            if (d.ShowDialog() == System.Windows.Forms.DialogResult.OK)
            {
                OutputFile_TextBox.Text = d.SelectedPath;
            }
        }

        private void Launch_Button_Click(object sender, RoutedEventArgs e)
        {
            if (!string.IsNullOrEmpty(_toLaunch))
            {
                TextBlock_Output.Text = "";
                _outputText.Clear(); 

                Process process = new Process();

                process.StartInfo.FileName = _toLaunch;
                process.StartInfo.Arguments = string.Format("\"{0}\" \"{1}\" {2}", InputFile_TextBox.Text,
                    OutputFile_TextBox.Text, OutputFile_TextBox_Copy.Text);

                process.StartInfo.CreateNoWindow = true;
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
                TextBlock_Output.Text += _outputText.ToString();

                TextBlock_Output.Text += "Process exited with value " + ((Process)sender).ExitCode + "\n";
                TextBlock_Output.Text += "Process completed in " +
                    ((DateTime.Now - ((Process)sender).StartTime)).TotalSeconds + " seconds.\n";
            });
        }

        void process_ErrorDataReceived(object sender, DataReceivedEventArgs e)
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                Dispatcher.Invoke((Action)delegate()
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
                _outputText.Append(e.Data);
            }
            return;
        }

        private void RadioButton_Checked_1(object sender, RoutedEventArgs e)
        {
            _toLaunch = ((System.Windows.Controls.RadioButton)e.Source).Tag.ToString();

            return;
        }
    }
}
