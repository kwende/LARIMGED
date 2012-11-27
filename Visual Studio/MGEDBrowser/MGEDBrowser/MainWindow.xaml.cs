// This file is part of MGEDBrowser.
// Foobar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Foobar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

// Copyright 2012 Benjamin D. Rush

using Microsoft.Win32;
using System;
using System.Collections.Generic;
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

namespace MGEDBrowser
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private const string StartAddress = "http://asteroid.lowell.edu/LARI/mged.html";
        private const string DataAddress = "http://asteroid.lowell.edu/cgi-bin/tres";
        private const string ContentStartString = "Uncertainty\r\n";
        private const string ContentEndString = "</PRE>"; 

        private string _currentAddress = "";
        private string _currentDocumentContent = ""; 

        public MainWindow()
        {
            InitializeComponent();
            this.Loaded += MainWindow_Loaded;
            this.Browser.LoadCompleted += Browser_LoadCompleted;
            this.Browser.Navigating += Browser_Navigating;
        }

        void Browser_Navigating(object sender, NavigatingCancelEventArgs e)
        {
            MessageTextBlock.Text = "Navigating..."; 
        }

        void Browser_LoadCompleted(object sender, NavigationEventArgs e)
        {
            dynamic doc = Browser.Document;
            _currentDocumentContent = doc.documentElement.InnerHtml;
            _currentAddress = e.Uri.ToString();
            MessageTextBlock.Text = ""; 
        }

        void MainWindow_Loaded(object sender, RoutedEventArgs e)
        {
            Browser.Navigate(StartAddress); 
        }

        private void MenuItem_Click_1(object sender, RoutedEventArgs e)
        {
            if (_currentAddress == DataAddress)
            {
                SaveFileDialog sfd = new SaveFileDialog();
                sfd.Filter = "Text Document|*.txt";
                if (sfd.ShowDialog() == true)
                {
                    int startIndex = _currentDocumentContent.IndexOf(ContentStartString);
                    int endIndex = _currentDocumentContent.IndexOf(ContentEndString);

                    string content = _currentDocumentContent.Substring(startIndex + ContentStartString.Length, endIndex - (startIndex + ContentStartString.Length));

                    File.WriteAllText(sfd.FileName, content); 
                }
            }
        }

        private void MenuItem_Click_2(object sender, RoutedEventArgs e)
        {
            if (_currentAddress == DataAddress)
            {
                SaveFileDialog sfd = new SaveFileDialog();
                sfd.Filter = "CSV|*.csv";
                if (sfd.ShowDialog() == true)
                {
                    int startIndex = _currentDocumentContent.IndexOf(ContentStartString);
                    int endIndex = _currentDocumentContent.IndexOf(ContentEndString);

                    string content = _currentDocumentContent.Substring(startIndex + ContentStartString.Length, endIndex - (startIndex + ContentStartString.Length));
                    content = content.Replace("   ", ","); 

                    File.WriteAllText(sfd.FileName, content);
                }
            }
        }
    }
}
