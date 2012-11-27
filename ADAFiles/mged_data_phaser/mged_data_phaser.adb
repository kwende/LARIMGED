-- This file is part of mged_data_phaser.
-- Foobar is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- Foobar is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

-- Copyright 2012 Bruce W. Koehn

--  <description>
--  This procedure "phases" the Julian dates in a TrES data file
--  (or a PDM file) so that the dates become time normalized to the
--  putative period. It produces an output file which contains the
--  same information as the input file except that the Julian dates
--  are re-written in the normalized phased form.
--
--  The procedure requires three command line arguments. The first is
--  the name of the input file. The input file should be the output from
--  the TrES data web site, http://asteroid.lowell.edu/LARI/mged.html.
--  The header and trailer lines of the raw input file should be removed.  Note
--  that any text file can be used if the first token in each line is
--  the Julian date of the datum. That is, this procedure should work
--  on some of the PDM output files.
--
--  The second argument is the name of the output file. The output file
--  format is identical to the input file format except that the JD is
--  converted to a normalized, phased time.
--
--  The third argument, a real number, is the putative period of the
--  stellar lightcurve. It is normally expressed in days since the
--  input time is a Julian date (also days).
--  </description>
with
Ada.Text_Io,
     Ada.Command_Line,
     Ada.Strings,
     Ada.Strings.Fixed,
     Ada.Strings.Maps,
     Messages;
use
  Ada.Text_Io,
    Ada.Command_Line,
    Ada.Strings,
    Ada.Strings.Fixed,
    Ada.Strings.Maps,
    Messages;

procedure Mged_Data_Phaser is
   package Lfio is new Float_Io (Long_Float); use Lfio;
   Period, Time, Phased_Time : Long_Float;
   Tail, Tail1, First, Last, Line_Count : Natural;
   Src, Dst : File_Type;
   Buffer : String (1 .. 512);
   Delimiter : Character_Set;
   User_Error : exception;

   --  The "mod" function is a generalization of the "remainder" function.
   --  This implementation is an "overload" of the mod funtion for
   --  integer input.
   function "mod"
     (Arg1, Arg2 : Long_Float) return Long_Float is
   begin
      return (Arg1 - (Arg2 * Long_Float'Floor (Arg1 / Arg2)));
   end "mod";

begin
   --  Verify the correct number of command line arguments are present.
   if Argument_Count /= 3 then
      Error_Msg ("mged_data_phaser",
                 "This procedure requires exactly three " &
                   "command line arguments. The first is the source data " &
                   "file name. The second is the output file name for " &
                   "the result file. The third is the period expressed " &
                   "in days. The procedure did not find three command " &
                   "line arguments.");
      raise User_Error;
   end if;
   --  Verify the source file is present and, if so, open it.
   begin
      Open (Src, In_File, Argument (1));
   exception
      when others =>
         Error_Msg ("mged_data_phaser",
                    "The procedure could not open the specified input file. " &
                      "Often, this error occurs when the file name is " &
                      "misspelled or the file does not exist.");
         raise User_Error;
   end;
   --  Convert the period (third command line argument) from string
   --  format to long_float format.
   begin
      Get (Argument (3), Period, Tail);
   exception
      when others =>
         Error_Msg ("mged_data_phaser",
                    "The procedure could not convert the third command " &
                      "line argument, the period, into a number.");
         raise User_Error;
   end;
   --  Open the output (destination) file.
   begin
      Create (Dst, Out_File, Argument (2));
   exception
      when others =>
         Error_Msg ("mged_data_phaser",
                    "The procedure could not open the specified output " &
                      "file. Often this error occurs when the user does " &
                      "not have write privleges in the destination " &
                      "directory.");
         raise User_Error;
   end;
   First := Buffer'First;
   Delimiter := To_Set (", ");
   Line_Count := 0;
   --  Loop through each line of the input file.
   while not End_Of_File (Src) loop
      --  Read the line and get the first token, under the assumption
      --  that the token in the JD of the observation.
      Get_Line (Src, Buffer, Tail);
      Line_Count := Line_Count + 1;
      Find_Token (Buffer (First .. Tail), Delimiter, Outside,
                  First, Last);
      --  Convert the JD token from string format to long_float format.
      begin
         Get (Buffer (First .. Last), Time, Tail1);
      exception
         when others =>
            Error_Msg ("mged_data_phaser",
                       "The procedure could not convert a Julian date, " &
                         "from the input file, into a number. The " &
                         "offending string is """ & Buffer (First .. Last) &
                         """.");
            raise User_Error;
      end;
      --  Convert the JD into phased, normalized time and write the source
      --  line into the output file with the JD replaced with the phased
      --  time.
      Phased_Time := (Time mod Period) / Period;
      Put (Dst, Phased_Time, 4, 8, 0); Put_Line (Dst, Buffer (Last + 1 .. Tail));
   end loop;
   if Line_Count = 0 then
      Error_Msg ("mged_data_phaser",
                 "No data were found in the input file. " &
                   "Your output file will be empty.");
   elsif Line_Count = 1 then
      Status_Msg ("mged_data_phaser",
                   "Only one datum was found in the input file. The " &
                     "output file will be unexpectedly short.");
   end if;
   Close (Dst);
   Close (Src);
end Mged_Data_Phaser;
