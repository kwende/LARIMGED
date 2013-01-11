using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Media;
using Visiblox.Charts;

namespace FFTWViewer
{
    public class GraphData
    {
        public GraphData(Brush brush, double[] data, string name)
        {
            Brush = brush;
            Data = data;
            Name = name; 
        }

        public Brush Brush { get; set; }
        public double[] Data { get; set; }
        public string Name { get; set; }
    }

    public class GraphHelper
    {
        public Chart TheChart { get; private set; }

        public GraphHelper(Chart theChart)
        {
            TheChart = theChart; 
        }

        public void Update(params GraphData[] graphs)
        {
            double largestY = 0.0;
            double smallestY = double.MaxValue; 

            TheChart.Series.Clear();
            for (int c = 0; c < graphs.Length; c++)
            {
                GraphData graphData = graphs[c];

                double[] data = graphData.Data;

                TheChart.Series.Add(new LineSeries { LineStroke = graphData.Brush });

                DataSeries<double, double> points = new DataSeries<double, double>(graphData.Name);
                for (int x = 0; x < data.Length; x++)
                {
                    double y = data[x];
                    if (y > largestY)
                    {
                        largestY = y; 
                    }
                    if (y < smallestY)
                    {
                        smallestY = y; 
                    }
                    points.Add(new DataPoint<double, double> { X = x, Y = y });
                }
                TheChart.Series[c].DataSeries = points;
            }

            TheChart.Series[0].YAxis.Range = new DoubleRange(smallestY, largestY);
        }
    }
}
