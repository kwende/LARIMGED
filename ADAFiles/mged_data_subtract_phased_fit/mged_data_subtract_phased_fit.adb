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
--  This procedure subtracts the fitted value of a lightcurve
--  from the measured values of the lightcurve. That is, it
--  calculates the local fitted value of a phased lightcurve,
--  typically consisting of magnitudes as a function of time,
--  and subtracts the fitted magnitude from the measured
--  magnitude. The result should be a dataset where the value
--  of the subtraction is near zero.
--
--  We calcualte the fitted value from a Fourier series. The
--  coefficients of the Fourier series are provided externally
--  from a file.  Typically, the coefficients are generated by
--  MPO Canopus so we requre the file format to be the same as
--  that generated by MPO Canopus.  Recall the that Fourier
--  series has the form
--
--  F = (Sum Over i )(C_i * sin ((i * 2 * pi * T) / P) +
--                    D_i * cos ((i * 2 * pi * T) / P))
--  where (Sum over i) means that we sum the terms that follow
--  with i incrementing in each summation term. The value of i
--  usually starts with 1 and, in this case, ends with some
--  small integer value. C_i and D_i are constant coefficients
--  supplied by an external file, T is the time in days and P
--  is the period in days.
--
--  The procedure requires three command line arguments:
--  The first is the name of the source data file.
--  The second is the name of the output data file.
--  The third is a list of fitting coefficients.
--
--  The source data file must be in a table format. It may be in
--  CSV format or there may be spaces between each of the
--  numbers in a record. Each record (or line) should contain
--  data for one measurement. The first column should be the
--  phased time of the measurement in days specified with at
--  least five decimal digits. The second column should be the
--  magnitude specified with at least three decimal digits.
--  Other columns may be present after the second column.
--
--  The output data file will be written in CSV or space
--  separated format (to match the input file format) and the
--  data will be written so that one measurement appears on
--  each line. The order of the data will match the input file.
--  The output file will duplicate the input file but the
--  results of this procedure will be appended to the end of
--  each line. Three additional columns will be appended.
--  Column +1 will be the local fitted value of the magnitude.
--  Column +2 will be the difference between the actual
--  magnitude and the fitted value. Column +3 will be the line
--  index number. This column is sometimes duplicated in the
--  source file.
--  </description>
with
Ada.Text_IO,
     Ada.Command_Line,
     Ada.Strings,
     Ada.Strings.Fixed,
     Ada.Strings.Maps,
     Ada.Numerics,
     Ada.Numerics.Generic_Elementary_Functions,
     Text_Format,
     Messages,
     Astro;
use
  Ada.Text_IO,
    Ada.Command_Line,
    Ada.Strings,
    Ada.Strings.Fixed,
    Ada.Strings.Maps,
    Ada.Numerics,
    Messages;

procedure Mged_Data_Subtract_Phased_Fit is
   package Ast is new Astro (Integer, Long_Float); use Ast;
   package Lfio is new Float_Io (Long_Float); use Lfio;
   package Iio is new Integer_Io (Integer); use Iio;
   package Gef is new Generic_Elementary_Functions (Long_Float);
   use Gef;
   package Tf is new Text_Format (Long_Float); use Tf;
   Src, Dst, Fourier_File : File_Type;
   Delimiter : Character_Set;
   Buffer : String (1 .. 512);
   Number_Str : String(1 .. 16);
   Tail, Fini, Line_Count, Total_Line_Count, Ndx,
   Terminus, Coef_Count, Ptr, P0,
   Token_Count, First, Last : Natural;
   Time, Magnitude, Error, F, Theta : F1_Array_Ptr;
   Data : F1_Array (1 .. 3);
   C, D : F1_Array (1 .. 15);
   T0, K, Dummy, P, Avg  : Long_Float;
   User_Error : exception;
   Found_T0, Found_Coefficients, Found_Period, Found_Average : Boolean;
   --
   --  This mod function is an extension to the existing mod function for
   --  integers.  This one requires floating point arguments.
   --
   function "mod" (Arg1, Arg2 : Long_Float) return Long_Float is
   begin
      return (Arg1 - (Arg2 * Long_Float'Floor (Arg1 / Arg2)));
   end "mod";

begin
   --
   --  Verify three command line arguments are present
   --
   if Argument_Count /= 3 then
      Error_Msg ("mged_data_subtract_phased_fit",
                 "This procedure requires exactly three " &
                   "command line arguments. The first is the source data " &
                   "file name. The second is the output file name. " &
                   "The third is the set of Fourier coefficients. " &
                   "The procedure did not find three command " &
                   "line arguments.");
      raise User_Error;
   end if;
   --
   --  Verify the command lines are not empty
   --
   if Trim (Argument (1), Both) = "" then
      Error_Msg ("mged_data_subtract_phased_fit",
                 "The input file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty input file name.");
      raise User_Error;
   end if;
   if Trim (Argument (2), Both) = "" then
      Error_Msg ("mged_data_subtract_phased_fit",
                 "The output file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty output file name.");
      raise User_Error;
   end if;
   --
   --  Verify the command lines are not empty
   --
   if Trim (Argument (1), Both) = "" then
      Error_Msg ("mged_data_subtract_phased_fit",
                 "The Fourier coefficients file name is empty. " &
                   "The procedure cannot proceed without a " &
                   "non-empty Fourier coefficients file name.");
      raise User_Error;
   end if;
   --
   --  Open the source file
   --
   begin
      Open (Src, In_File, Argument (1));
   exception
      when others =>
         Error_Msg ("mged_data_subtract_phased_fit",
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
         Error_Msg ("mged_data_subtract_phased_fit",
                    "The procedure could not create the specified output " &
                      "file. Often this error occurs when the user does " &
                      "not have write privleges in the destination " &
                      "directory.");
         Close(Src);
         raise User_Error;
   end;
   --
   --  Read the Fourier Coefficients file.
   --
   begin
      Open (Fourier_File, In_File, Argument (3));
   exception
      when others =>
         Close (Src);
         Close (Dst);
         Error_Msg ("mged_data_subtract_phased_fit",
                    "The procedure could not open the specified Fourier " &
                      "coefficients file. Often this error occurs when the " &
                      "file name is misspelled or the file does not exist.");
         raise User_Error;
   end;
   Coef_Count := 0;
   Found_T0 := False;
   Found_Coefficients := False;
   Found_Period := False;
   Ndx := 0;
   Delimiter := To_Set (" ");
   --  Read each line of the Fourier coefficients file.
   while not End_Of_File (Fourier_File) loop
      Get_Line (Fourier_File, Buffer, Tail);
      Ptr := Index (Buffer (1 .. Tail), ":");
      --  Every important value in this file is in a keyword : value format.
      --  So find the colons and parse out the information.
      if Ptr > 0 then
         --  Every colon should be followed by a number and we need the
         --  number (except for one). Get the number.
         P0 := Buffer'First;
         Find_Token (Buffer (Ptr + 1 .. Tail), Delimiter, Outside,
                     First, Last);
         if Last = 0 then
            Error_Msg ("mged_data_subtract_phased_fit",
                       "An expected number in the Fourier coefficients " &
                         "file did not exit. The offending line is """ &
                         Buffer (P0 .. Tail) & """");
            Close (Src);
            Close (Dst);
            Close (Fourier_File);
            raise User_Error;
         end if;
         --  We got the string so convert it to a number.
         if Is_Float (Buffer (First .. Last)) then
            Get (Buffer (First .. Last), Dummy, Terminus);
         else
            Error_Msg ("mged_data_subtract_phased_fit",
                       "An expected number in the Fourier coefficients " &
                         "file do not convert to a number. The offending " &
                         "line is """ & Buffer (P0 .. Tail) & """");
            Close (Src);
            Close (Dst);
            Close (Fourier_File);
            raise User_Error;
         end if;
         -- Now decide what the number represents.
         if Trim (Buffer (P0 .. Ptr - 1), Both) = "T0" then
            --  Zero time.
            T0 := Dummy;
            Found_T0 := True;
         elsif Trim (Buffer (P0 .. Ptr - 1), Both) = "Per" then
            --  Period
            P := Dummy;
            Found_Period := True;
         elsif Trim (Buffer (P0 .. Ptr - 1), Both) = "Avg" then
            --  Average amplitude which we do not need.
            Avg := Dummy;
            Found_Average := True;
         else
            --  A set of Fourier coefficients.
            if Is_Integer (Buffer (P0 .. Ptr - 1)) then
               Get (Buffer (P0 .. Ptr - 1), Ndx, Terminus);
               if Ndx > Coef_Count then
                  Coef_Count := Ndx;
               end if;
               --  Keep the coefficients
               C (Ndx) := Dummy;
               Find_Token (Buffer (Last + 1 .. Tail), Delimiter, Outside,
                           First, Last);
               if Is_Float (Buffer (First .. Last)) then
                  Get (Buffer (First .. Last), D (Ndx), Terminus);
                  Found_Coefficients := True;
               else
                  Error_Msg ("mged_data_subtract_phased_fit",
                             "Error while converting the second Fourier " &
                               "coefficient to a number. The offending " &
                               "line in the coefficients file is """ &
                               Buffer (P0 .. Tail) & """");
                  Close (Src);
                  Close (Dst);
                  Close (Fourier_File);
                  raise User_Error;
               end if;
            end if;
         end if;
      end if;
   end loop;
   if not (Found_T0 and Found_Coefficients and Found_Period and Found_Average) then
      Error_Msg ("mged_data_subtract_phased_fit",
                 "The procedure failed to find Fourier coefficients " &
                   "or a starting time or a period in the Fourer data file, " &
                   Argument (3) & ".");
      Close (Src);
      Close (Dst);
      Close (Fourier_File);
      raise User_Error;
   end if;
   --
   --  Read the data the first time to get the size.  Then read it
   --  again to put it into arrays.  We expect phased time, magnitude,
   --  and error (uncertainty) as the first three numbers in a table row.
   --  Everything after the error will be ignored.
   --
   Line_Count := 0;
   while not End_Of_File (Src) loop
      Get_Line (Src, Buffer, Tail);
      Line_Count := Line_Count + 1;
   end loop;
   Total_Line_Count := Line_Count;
   --
   --  Allocate the data arrays
   --
   Time := new F1_Array (1 .. Line_Count);
   Magnitude := new F1_Array (1 .. Line_Count);
   Error := new F1_Array (1 .. Line_Count);
   F := new F1_Array (1 .. Line_Count);
   Theta := new F1_Array (1 .. Line_Count);
   Reset (Src);
   --
   --  Read the source file again but get the time, magnitude and error values.
   --
   Delimiter := To_Set (" ,");
   Line_Count := 0;
   while not End_Of_File (Src) loop
      Get_Line (Src, Buffer, Tail);
      Line_Count := Line_Count + 1;
      Token_Count := 0;
      Last := 0;
      --
      --  Find the first 3 tokens, convert them to long float numbers,
      --  and put them in the temporary Data array.
      --
      while Token_Count < 3 loop
         Find_Token (Buffer (Last + 1 .. Tail),
                     Delimiter, Outside, First, Last);
         exit when Last = 0;
         Token_Count := Token_Count + 1;
         begin
            Get (Buffer (First .. Last), Data (Token_Count), Fini);
         exception
            when others =>
               Status_Msg ("mged_data_subtract_phased_fit",
                           "The procedure found a token it could not " &
                             "convert to a number as part of the input " &
                             "data. The offending line is """ &
                             Buffer (1 .. Tail) & """.");
         end;
      end loop;
      if Token_Count /= 3 then
         Status_Msg ("mged_data_subtract_phased_fit",
                     "The procedure did not find a phased time, a magnitude, " &
                       "and an error in a source file line. The procedure " &
                       "will omit that line and continue. The offending " &
                       "line is """ & Buffer (1 .. Tail) & """.");
      else
         --
         --  Copy the Data array values to their final resting place.
         --
         Time (Line_Count) := Data (1);
         Magnitude (Line_Count) := Data (2);
         Error (Line_Count) := Data (3);
      end if;
   end loop;
   for I in 1 .. Line_Count loop
      --
      --  Calculate the Fourier value for the specified time
      --
      F (I) := 0.0;
      Theta (I) := ((Time (I) - T0) mod P) / P;
      for J in 1 .. Coef_Count loop
         K := Long_Float (J);
         F (I) := F (I) +
           C (J) * Sin (K * Twopi * Theta (I)) +
           D (J) * Cos (K * Twopi * Theta (I));
      end loop;
      F (I) := F (I) + Avg;
   end loop;
   for I in 1 .. Total_Line_Count loop
      Put (Dst, Time (I), 8, 8, 0); Put (Dst, ",");
      Put (Dst, Theta (I), 8, 8, 0); Put (Dst, ",");
      Put (Dst, Magnitude (I), 8, 8, 0); Put (Dst, ",");
      Put (Dst, Error (I), 8, 8, 0); Put (Dst, ",");
      Put (Dst, F (I), 8, 8, 0); Put (Dst, ",");
      Put (Dst, Magnitude (I) - F (I), 8, 8, 0); Put (Dst, ",");
      Put (Dst, I);
      New_Line (Dst);
   end loop;
   if Total_Line_Count = 0 then
      Error_Msg
        ("mged_data_subtract_phased_mean",
         "No data were found in the input file. " &
           "Your output file will be empty.");
   else
      Put (Number_Str, Total_Line_Count);
      Status_Msg
        ("mged_data_subtract_phased_mean",
         "This procedure successfully processed " &
           Trim (Number_Str, Both) & " input records from " & Argument (1) &
           " into " & Argument (2) & ".");
   end if;
   Close (Dst);
   Close (Src);
exception
   when others =>
      --
      --  This section closes files and deallocates memory of an
      --  unexpected error occurs. This is note really required
      --  because Ada normally does this anyway, but it is nice to
      --  see it here.
      --
      if Time /= null then
         Free_F1_Array (Time);
      end if;
      if Magnitude /= null then
         Free_F1_Array (Magnitude);
      end if;
      if Error /= null then
         Free_F1_Array (Error);
      end if;
      if F /= null then
         Free_F1_Array (Error);
      end if;
      if Theta /= null then
         Free_F1_Array (Theta);
      end if;
      if Is_Open (Src) then
         Close (Src);
      end if;
      if Is_Open (Dst) then
         Close (Dst);
      end if;
      if Is_Open (Fourier_File) then
         Close (Fourier_File);
      end if;
end Mged_Data_Subtract_Phased_Fit;