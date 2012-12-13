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
--  This procedure converts an ASCII data table
--  to a comma separated variable list (CSV) in, essentially, the
--  same format as the original table. For each line of the source file,
--  it replaces any consectutive sequence of blank spaces and/or commas
--  into a single comma and then prints the line into the output file.
--
--  The user may easily apply this procedure inappropriately. There
--  are no checks to verify the source file is in a space/comma separated
--  table format. The user could apply the procedure to any
--  random text file and the procedure will happily replace all the
--  existing delimiters with commas.
--  </description>
with
Ada.Text_IO,
     Ada.Command_Line,
     Ada.Strings,
     Ada.Strings.Fixed,
     Ada.Strings.Maps,
     Messages;
use
  Ada.Text_IO,
    Ada.Command_Line,
    Ada.Strings,
    Ada.Strings.Fixed,
    Ada.Strings.Maps,
    Messages;
--  <summary>
--  Convert a TrES photometric data file into a CSV formated file.
--  </summary>
--  <parameter name="Source data file name">
--  A command line argument naming the source file.</parameter>
--  <parameter name="Destination data file name">
--   A Command line argument naming the output file.</parameter>
--  <exception>User_Error - Raised for any file or data error.</exception>

procedure Mged_Data_Csv is
   package Iio is new Integer_Io (Integer); use Iio;
   Src, Dst                : File_Type;
   Tail, First, Last,
   Data_Count, Line_Count  : Natural;
   Done                    : Boolean;
   Buffer                  : String (1 .. 512);
   Number_Str              : String (1 .. 16);
   Delimiter               : Character_Set;
   User_Error              : exception;

begin
   --
   --  Verify two command line arguments are present
   --
   if Argument_Count /= 2 then
      Error_Msg ("mged_data_csv", "This procedure requires exactly two " &
                   "command line arguments. The first is the source data " &
                   "file name. The second is the output file name for " &
                   "the CSV file. The procedure did not find two command " &
                   "line arguments.");
      raise User_Error;
   end if;
   --
   --  Verify the command lines are not empty
   --
   if Trim (Argument (1), Both) = "" then
      Error_Msg ("mged_data_csv",
                 "The input file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty input file name.");
      raise User_Error;
   end if;
   if Trim (Argument (2), Both) = "" then
      Error_Msg ("mged_data_csv",
                 "The output file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty output file name.");
      raise User_Error;
   end if;
   --
   --  Open the source file
   --
   begin
      Open (Src, In_File, Argument (1));
   exception
      when others =>
         Error_Msg ("mged_data_csv",
                    "The procedure could not open the specified input file. " &
                      "Often, this error occurs when the file name is " &
                      "misspelled or the file does not exist.");
         raise User_Error;
   end;
   --
   --  Create the destination file.
   --
   begin
      Create (Dst, Out_File, Argument (2));
   exception
      when others =>
         Error_Msg ("mged_data_csv",
                    "The procedure could not open the specified output " &
                      "file. Often this error occurs when the user does " &
                      "not have write privleges in the destination " &
                      "directory.");
         raise User_Error;
   end;
   Delimiter := To_Set (", ");
   Last := Buffer'First - 1;
   Line_Count := 0;
   --  Loop through every line of the input file.
   while not End_Of_File (Src) loop
      --  Read the next line
      Get_Line (Src, Buffer, Tail);
      Line_Count := Line_Count + 1;
      Done := False;
      Data_Count := 0;
      --  Loop through all the tokens in the line
      while not Done loop
         Find_Token (Buffer (Last + 1 .. Tail), Delimiter, Outside,
                     First, Last);
         if Last = 0 then
            --  If no token can be found, go to a new output line
            --  and stop looking for more tokens
            New_Line (Dst);
            Done := True;
            Data_Count := 0;
         else
            --  If a token exits, write the token in the output file
            --  with appropriate commas.
            if Data_Count = 0 then
               Put (Dst, Buffer (First .. Last));
            else
               Put (Dst, ","); Put (Dst, Buffer (First .. Last));
            end if;
            Data_Count := Data_Count + 1;
         end if;
      end loop;
   end loop;
   --  Close both the input and output files.
   Close (Dst);
   Close (Src);
   Put (Number_Str, Line_Count);
   if Line_Count < 1 then
      Error_Msg ("mged_data_csv",
                 "The procedure found no records in the source file, " &
                   Argument (1) & ". The output file, " &
                   Argument (2) & ", will be empty.");
   else
      Status_Msg ("mged_data_csv",
                  "The procedure successfully created " &
                    Trim (Number_Str, Both) &
                    " csv records from the source file " &
                    Argument (1) &
                    " into " & Argument (2) & ".");
   end if;
exception
   when others =>
      Close (Dst);
      Close (Src);
      Put (Number_Str, Line_Count);
      Error_Msg ("mged_data_csv",
                 "The procedure experienced an " &
                   "error on line " & Trim (Number_Str, Both) &
                   " of the input file. Terminating. The output file " &
                   "may be good up to " &
                   "the line containing the error.");
      raise;
end Mged_Data_Csv;
