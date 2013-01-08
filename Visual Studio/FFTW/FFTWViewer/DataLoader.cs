using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FFTWViewer
{
    public class DataLoader
    {
        public static double[] Load(string filePath)
        {
            if (!File.Exists(filePath)) throw new FileNotFoundException(filePath);
            else
            {
                List<double> arr = new List<double>(); 

                foreach (string line in File.ReadLines(filePath))
                {
                    string[] bits = line.Split(' ').Where(m=>m.Length > 0).ToArray();
                    if (bits.Length == 3)
                    {
                        arr.Add(double.Parse(bits[1])); 
                    }
                }

                return arr.ToArray(); 
            }
        }
    }
}
