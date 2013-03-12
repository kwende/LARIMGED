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
--  This procedure calculates the local mean of a phased data set,
--  typically consisting of magnitudes as a function of time,
--  and subtracts the local mean magnitude from the magnitude. The
--  result should be a dataset where the value of the resulting
--  subtraction should be near zero.
--
--  We calcualte the mean from phased data by creating a "boxcar"
--  bin about each value on the time axis.  The bin is either
--  1/64, 1/128, or 1/192 of the total length of the time axis.
--  (A algorithic change to allow more bin sizes might be useful.)
--  As the data becomes sparse, the bins become larger.  Bins larger
--  than 1/64 will start to get "lumpy" and bins smaller than 1/196
--  will add nothing to the detail of the mean.  Each bin should
--  contain at least 8 data or the mean will not be statistically
--  viable.  Fewer than an average of 8 data will result in an error
--  condition
--  and the mean will not be calculated. (The value 8 is the mean
--  number of data over all the bins.  Some bins will have less than
--  8 data.)
--
--  The procedure requires two command line arguments:
--  The first is the name of the source data file.
--  The second is the name of the output data file.
--
--  The source data file must be in a table format. It may be
--  in CSV format or there may be spaces between each of the
--  numbers. Each line should contain data for one measurement.
--  The first column should be the phased time of the
--  measurement in days specified with at least five decimal digits.
--  The second column should be the magnitude specified with at least
--  three decimal digits. The third column must be present and it must
--  be a number. Normally it is the standard error (uncertainty) in
--  the magnitude. Other columns may be present after the error column.
--
--  The output data file will be written in CSV format and the data
--  will be written so that one measurement appears on each line. The
--  order of the data will match the input file.
--  Column 1, and 2 will match the values of columns 1, and 2 of
--  of the input file. Four additional columns will be
--  appended at the end of each record. Column 3 will be the
--  magnitude error,
--  Column 4 will be the mean magnitude, Column 5 will be
--  the RMS magnitude deviation from the mean. Column 6 will be the
--  line index number.
--
--  Note: The mged_data_pdm procedure produces a file call pdmcurve.csv.
--  This file contains a column similar to the local mean value of the
--  magnitude.  However, we have found that it is not a particularly
--  good mean. This procedure was written to address that deficiency.
--  </description>
--
with
Ada.Text_IO,
     Ada.Command_Line,
     Ada.Strings,
     Ada.Strings.Fixed,
     Ada.Strings.Maps,
     Ada.Numerics,
     Ada.Numerics.Generic_Elementary_Functions,
     Messages,
     Utility,
     Astro;
use
  Ada.Text_IO,
    Ada.Command_Line,
    Ada.Strings,
    Ada.Strings.Fixed,
    Ada.Strings.Maps,
    Ada.Numerics,
    Messages;

procedure Mged_Data_Subtract_Phased_Mean is
   package Ast is new Astro (Integer, Long_Float); use Ast;
   package Lfio is new Float_Io (Long_Float); use Lfio;
   package Iio is new Integer_Io (Integer); use Iio;
   package Gef is new Generic_Elementary_Functions (Long_Float);
   use Gef;
   package Sort is new Utility.Float_Sort (Integer, Long_Float,
                                           F1_Array, I1_Array);
   use Sort;
   Src, Dst : File_Type;
   Delimiter : Character_Set;
   Buffer : String (1 .. 512);
   Number_Str : String (1..16);
   Tail, Fini, Line_Count, Total_Line_Count, Bin_Count,
   Token_Count, First, Last, Data_Count, T_Count, S_Count : Natural;
   Time, Magnitude, Error, Mean, Temp, Rms : F1_Array_Ptr;
   Sort_Ndx : I1_Array_Ptr;
   Data : F1_Array (1 .. 3);
   Density, Bin_Width, Half_Bin_Width, Lo_Limit, Hi_Limit,
   Sum, Target_A, Target_B, T_Mean, Limit  : Long_Float;
   User_Error : exception;
begin
   --
   --  Verify two command line arguments are present
   --
   if Argument_Count /= 2 then
      Error_Msg ("mged_data_subtract_phased_mean",
                 "This procedure requires exactly two " &
                   "command line arguments. The first is the source data " &
                   "file name. The second is the output file name. " &
                   "The procedure did not find two command " &
                   "line arguments.");
      raise User_Error;
   end if;
   --
   --  Verify the command lines are not empty
   --
   if Trim (Argument (1), Both) = "" then
      Error_Msg ("mged_data_subtract_phased_mean",
                 "The input file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty input file name.");
      raise User_Error;
   end if;
   if Trim (Argument (2), Both) = "" then
      Error_Msg ("mged_data_subtract_phased_mean",
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
         Error_Msg ("mged_data_subtract_phased_mean",
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
         Error_Msg ("mged_data_subtract_phased_mean",
                    "The procedure could not open the specified output " &
                      "file. Often this error occurs when the user does " &
                      "not have write privleges in the destination " &
                      "directory.");
         raise User_Error;
   end;
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
   Mean := new F1_Array (1 .. Line_Count);
   Temp := new F1_Array (1 .. Line_Count);
   Rms := new F1_Array (1 .. Line_Count);
   Sort_Ndx := new I1_Array (1 .. Line_Count);
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
         Find_Token (Buffer (Last + 1 .. Tail), Delimiter, Outside, First, Last);
         exit when Last = 0;
         Token_Count := Token_Count + 1;
         begin
            Get (Buffer (First .. Last), Data (Token_Count), Fini);
         exception
            when others =>
               Status_Msg ("mged_data_subtract_phased_mean",
                           "The procedure found a token it could not " &
                             "convert to a number as part of the input " &
                             "data. The offending line is """ &
                             Buffer (1 .. Tail) & """.");
         end;
      end loop;
      if Token_Count /= 3 then
         Status_Msg ("mged_data_subtract_phased_mean",
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
   --
   --  Set the number of bins and then the bin size.
   --  Overview: Since we can detect changes in a graph at about
   --  the 1% level, we will use approximately 1% of the time
   --  range to define the bins and bin size. This value can be slightly
   --  modified to maintain a statistically significant number of data
   --  in the bin.
   --
   Bin_Count := 128;
   --
   --  If there are insufficient data to support this number of
   --  bins, then decrease the number of bins to 64.  A further
   --  decrease of the number of bins to 32 is too few.  The data
   --  will not appear smooth and averaging will not be helpful. We make
   --  the decision on number of bins by requiring between 16 and 32
   --  data per bin.  This should be enough to provide a reliable
   --  mean value. If we have fewer than 16 data per bin, then
   --  increase the bin size.  If we have more than 32, then decrease
   --  the bin size. If the number of data become too few, raise
   --  an error condition.
   --
   Density := Long_Float (Total_Line_Count) / Long_Float (Bin_Count);
   if Density < 16.0 then
      Bin_Count := 64;
      Density := Long_Float (Total_Line_Count) / Long_Float (Bin_Count);
      if Density > 8.0 then
         Status_Msg ("mged_data_subtract_phased_mean",
                     "Warning: There are too few data to calculate a " &
                       "robust mean. Treat the resulting data with caution.");
      else
         Error_Msg ("mged_data_subtract_phased_mean",
                    "There are too few data to calculate a reliable mean. " &
                      "This procedure is terminating without producing an " &
                      "output file");
         Delete (Dst);
         Close (Src);
         raise User_Error;
      end if;
   elsif Density > 32.0 then
      --
      --  No need to raise the bin count higher than 192 because
      --  a smaller bin size will add no new information.
      --
      Bin_Count := 192;
   end if;
   --
   --  Sort the data by phased time.
   --
   Qsort (Time.all, Sort_Ndx.all, Total_Line_Count);
   Bin_Width := (Time (Sort_Ndx (Total_Line_Count)) -
                   Time (Sort_Ndx (1))) / Long_Float (Bin_Count);
   Half_Bin_Width := Bin_Width / 2.0;
   for I in 1 .. Total_Line_Count loop
      Sum := 0.0;
      Data_Count := 0;
      T_Count := 0;
      Target_A := Time (Sort_Ndx (I));
      Lo_Limit := Target_A - Half_Bin_Width;
      Hi_Limit := Target_A + Half_Bin_Width;
      if Target_A < Half_Bin_Width then
         for J in 1 .. Total_Line_Count loop
            Target_B := Time (Sort_Ndx (J));
            if Target_B < Hi_Limit or
              Target_B > Lo_Limit + Time (Sort_Ndx (Total_Line_Count)) then
               Sum := Sum + Magnitude (Sort_Ndx (J));
               Data_Count := Data_Count + 1;
               --
               --  Copy the selected data into another array for
               --  further processing.  We repeat this operation in
               --  each of the "else/elsif" blocks below;
               --
               T_Count := T_Count + 1;
               Temp (T_Count) := Magnitude (Sort_Ndx (J));
            end if;
         end loop;
      elsif Target_A > Time (Sort_Ndx (Total_Line_Count)) - Half_Bin_Width then
         for J in 1 .. Total_Line_Count loop
            Target_B := Time (Sort_Ndx (J));
            if Target_B > Lo_Limit or
              Target_B < Hi_Limit - Time (Sort_Ndx (Total_Line_Count)) then
               Sum := Sum + Magnitude (Sort_Ndx (J));
               Data_Count := Data_Count + 1;
               T_Count := T_Count + 1;
               Temp (T_Count) := Magnitude (Sort_Ndx (J));
            end if;
         end loop;
      else
         for J in 1 .. Total_Line_Count loop
            Target_B := Time (Sort_Ndx (J));
            if Target_B > Lo_Limit and Target_B < Hi_Limit then
               Sum := Sum + Magnitude (Sort_Ndx (J));
               Data_Count := Data_Count + 1;
               T_Count := T_Count + 1;
               Temp (T_Count) := Magnitude (Sort_Ndx (J));
            end if;
            exit when Target_B > Hi_Limit;
         end loop;
      end if;
      --
      --  In the code below, we often divide by the data count. This
      --  division is always safe because we select each bin
      --  centered on a datum.  Therefore, there will always be at least
      --  one dataum.
      --
      T_Mean := Sum / Long_Float (Data_Count);
      --
      --  Calculate the RMS magnitude deviation for bin I.
      --
      Sum := 0.0;
      for J in 1 .. T_Count loop
         Sum := Sum + (T_Mean - Temp (J)) ** 2;
      end loop;
      Rms (Sort_Ndx (I)) := Sqrt (Sum / Long_Float (T_Count));
      --
      --  Calculate the mean again but this time do no use any
      --  magnitudes that are more than 3*Rms from the mean.
      --
      Sum := 0.0;
      S_Count := 0;
      Limit := 2.0 * Rms (Sort_Ndx (I));
      for J in 1 .. T_Count loop
         --
         --  Again, there will always be at least one dataum selected
         --  even though we omit outliers. The division is safe.
         --
         if abs (Temp (J) - T_Mean) < Limit then
            Sum := Sum + Temp (J);
            S_Count := S_Count + 1;
         end if;
      end loop;
      if S_Count > 1 then
         Mean (Sort_Ndx (I)) := Sum / Long_Float (S_Count);
      else
         Mean (Sort_Ndx (I)) := Sum;
      end if;
      --
      --  Re-calculate the RMS magnitude deviation for bin I but
      --  omit outliers.
      --
      Sum := 0.0;
      S_Count := 0;
      Limit := 2.0 * Rms (Sort_Ndx (I));
      T_Mean := Mean (Sort_Ndx (I));
      for J in 1 .. T_Count loop
         if abs (Temp (J) - T_Mean) < Limit then
            Sum := Sum + (T_Mean - Temp (J)) ** 2;
            S_Count := S_Count + 1;
         end if;
      end loop;
      if S_Count > 1 then
         Rms (Sort_Ndx (I)) := Sqrt (Sum / Long_Float (S_Count));
      else
         Rms (Sort_Ndx (I)) := Sqrt (Sum);
      end if;
   end loop;
   for I in 1 .. Total_Line_Count loop
      Put (Dst, Time (I), 8, 8, 0); Put (Dst, ",");
      Put (Dst, Magnitude (I), 8, 8, 0); Put (Dst, ",");
      Put (Dst, Error (I), 8, 8, 0); Put (Dst, ",");
      Put (Dst, Mean (I), 8, 8, 0); Put (Dst, ",");
      Put (Dst, Magnitude (I)-Mean (I), 8, 8, 0); Put (Dst, ",");
      Put (Dst, Rms (I), 8, 8, 0); Put (Dst, ",");
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
end Mged_Data_Subtract_Phased_Mean;
