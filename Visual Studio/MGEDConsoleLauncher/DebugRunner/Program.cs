using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DebugRunner
{
    class Program
    {
        const string DebugFilePath = "debugtrace.txt"; 

        static void Debug(string format, params object[] args)
        {
            //File.AppendAllText(DebugFilePath, string.Format(format + "\r\n", args));
            Console.WriteLine(string.Format(format, args)); 
        }

        static void Main(string[] args)
        {
            try
            {
                if (File.Exists(DebugFilePath))
                {
                    File.Delete(DebugFilePath); 
                }

                Debug("DebugRunner executed at {0}", DateTime.Now);
                Debug("Present working directory is {0}", Directory.GetCurrentDirectory());

                for (int c = 0; c < args.Length; c++)
                {
                    Debug("\tArguments {0} is '{1}'", c + 1, args[c]);
                }

                Debug("DebugRunner finished execution with {0} arguments", args.Length);
            }
            catch (Exception ex)
            {
                Debug("DebugRunner ran into an unhandled exception {0}", ex.ToString());
            }
        }
    }
}
