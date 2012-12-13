--
--  This file is part of Lowell Observatories MGED software project.
--  MGED software is free software: you can redistribute it and/or
--  modify it under the terms of the GNU General Public License as
--  published by the Free Software Foundation, either version 3 of the
--  License, or (at your option) any later version.

--  MGED software is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--  General Public License for more details.

--  You should have received a copy of the GNU General Public License
--  along with MGED software.  If not, see
--  <http://www.gnu.org/licenses/>.

--  Copyright 2012 Bruce W. Koehn, Lowell Observatory
--
--  <description>
--  This procedure "phases" the Julian dates in a TrES data file
--  so that the dates become time normalized to the
--  putative period. It produces an output file which contains the
--  same information as the input file with the addition of the
--  normalized phased time in an additional column at the beginning of
--  each line.
--
--  The procedure requires three command line arguments.
--
--  The first command line argument is
--  the name of the input file. The input file is normally the output from
--  the TrES data web site, http://asteroid.lowell.edu/LARI/mged.html or
--  a CSV formatted file with each record in the same general general
--  format as the web output. The header and trailer lines of the raw
--  input file should be removed.  The expected order of the data for
--  each record is Julian date, Magnitude, Magnitude uncertainty (error)
--  Other data can be included at the end of the record.
--
--  The second argument is the name of the output file. The output file
--  format is identical to the input file format except that the
--  normalized, phased time will be inserted in column 1 and all the
--  other columns will be shifted to the right by one column. The intent
--  of this format is to keep the source data unchanged but add the
--  phased data in a way that is relatively easy to use in plotting
--  routines.
--
--  The third argument, a real number, is the putative period of the
--  stellar lightcurve. It is normally expressed in days since the
--  input time is a Julian date (also days).
--  </description>
--
with Ada.Text_IO,
     Ada.Command_Line,
     Ada.Strings,
     Ada.Strings.Fixed,
     Ada.Strings.Maps,
     Messages;
use  Ada.Text_IO,
    Ada.Command_Line,
    Ada.Strings,
    Ada.Strings.Fixed,
    Ada.Strings.Maps,
    Messages;

procedure Mged_Data_Phaser is
   package Lfio is new Float_IO (Long_Float);
   use Lfio;
   package Iio is new Integer_Io (Integer); use Iio;
   Period, Time, Phased_Time            : Long_Float;
   Tail, Tail1, First, Last, Line_Count : Natural;
   Src, Dst                             : File_Type;
   Buffer                               : String (1 .. 512);
   Number_Str                           : String (1 .. 32);
   Delimiter                            : Character_Set;
   User_Error : exception;
   --
   --  The "mod" function, below, is a generalization of the Ada "mod"
   --  function. The standard mod function requires integer arguments.
   --  This overload of the mod function requires floating point
   --  arguments.
   --
   function "mod" (Arg1, Arg2 : Long_Float) return Long_Float is
   begin
      return (Arg1 - (Arg2 * Long_Float'Floor (Arg1 / Arg2)));
   end "mod";

begin
   --
   --  Verify the correct number of command line arguments are present.
   --
   if Argument_Count /= 3 then
      Error_Msg
        ("mged_data_phaser",
         "This procedure requires exactly three " &
           "command line arguments. The first is the source data " &
           "file name. The second is the output file name for " &
           "the result file. The third is the period expressed " &
           "in days. The procedure did not find three command " &
           "line arguments.");
      raise User_Error;
   end if;
   --
   --  Verify the command lines arguments are not empty
   --
   if Trim (Argument (1), Both) = "" then
      Error_Msg ("mged_data_phaser",
                 "The input file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty input file name.");
      raise User_Error;
   end if;
   if Trim (Argument (2), Both) = "" then
      Error_Msg ("mged_data_phaser",
                 "The output file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty output file name.");
      raise User_Error;
   end if;
   if Trim (Argument (3), Both) = "" then
      Error_Msg ("mged_data_phase",
                 "The period argument is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty period argument.");
      raise User_Error;
   end if;
   --
   --  Verify the source file is present and, if so, open it.
   --
   begin
      Open (Src, In_File, Argument (1));
   exception
      when others =>
         Error_Msg
           ("mged_data_phaser",
            "The procedure could not open the specified input file. " &
              "Often, this error occurs when the file name is " &
              "misspelled or the file does not exist.");
         raise User_Error;
   end;
   --
   --  Convert the period (third command line argument) from string
   --  format to long_float format.
   --
   begin
      Get (Argument (3), Period, Tail);
   exception
      when others =>
         Error_Msg
           ("mged_data_phaser",
            "The procedure could not convert the third command " &
              "line argument, the period, into a number.");
         raise User_Error;
   end;
   --
   --  Open the output (destination) file.
   --
   begin
      Create (Dst, Out_File, Argument (2));
   exception
      when others =>
         Error_Msg
           ("mged_data_phaser",
            "The procedure could not open the specified output " &
              "file. Often this error occurs when the user does " &
              "not have write privleges in the destination " &
              "directory.");
         raise User_Error;
   end;
   First      := Buffer'First;
   Delimiter  := To_Set (", ");
   Line_Count := 0;
   --
   --  Loop through each line of the input file.
   --
   while not End_Of_File (Src) loop
      --
      --  Read the line and get the first token, under the assumption
      --  that the token is the JD of the observation.
      --
      Get_Line (Src, Buffer, Tail);
      Line_Count := Line_Count + 1;
      Find_Token (Buffer (First .. Tail), Delimiter, Outside, First, Last);
      --
      --  Convert the JD token from string format to long_float format.
      --
      begin
         Get (Buffer (First .. Last), Time, Tail1);
      exception
         when others =>
            Put (Number_Str, Line_Count);
            Error_Msg
              ("mged_data_phaser",
               "The procedure could not convert a Julian date, " &
                 "from the input file, into a number. The " &
                 "offending string is """ &
                 Buffer (First .. Last) &
                 """ in line " & Trim (Number_Str, Both) & ".");
            raise User_Error;
      end;
      --
      --  Convert the JD into phased, normalized time and write that
      --  time into the output file and then append the original source
      --  line.
      --
      Phased_Time := (Time mod Period) / Period;
      Put (Dst, Phased_Time, 4, 8, 0);
      --
      --  Guess as to whether the source file is a CSV or not and put
      --  in a comma as appropriate.
      --
      if Index (Buffer (1 .. Tail), ",", Forward) > 0 then
         Put (Dst, ",");
      else
         Put (Dst, " ");
      end if;
      Put_Line (Dst, Buffer (1 .. Tail));
   end loop;
   if Line_Count = 0 then
      Error_Msg
        ("mged_data_phaser",
         "No data were found in the input file. " &
           "Your output file will be empty.");
   else
      Put (Number_Str, Line_Count);
      Status_Msg
        ("mged_data_phaser",
         "This procedure successfully processed " &
           Trim (Number_Str, Both) & " input records from " & Argument (1) &
           " into " & Argument (2) & " using a period of " &
           Argument (3) & " days.");
   end if;
   Close (Dst);
   Close (Src);
exception
   when others =>
      Close (Dst);
      Close (Src);
      Put (Number_Str, Line_Count);
      Error_Msg ("mged_data_phaser",
                 "This procedure experienced an error on or near line " &
                   Trim (Number_Str, Both) & ". The output file may be " &
                   "valid up to that line. Terminating.");
      raise;
end Mged_Data_Phaser;
