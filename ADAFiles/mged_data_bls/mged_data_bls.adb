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

--  Copyright 2013 Bruce W. Koehn, Lowell Observatory
--
--  <description> 
--  
--  This procedure finds exoplanet transits in time-series photometric
--  data using the Box Least-Squares fitting (BLS) algorithm described
--  by Kovacs, G., Zucker, S. and Mazeh, T. "A box-fitting algorithm
--  in the search for periodic transits."  A&A 391:369-377 (2002).
--
--  The first command line argument is the name of the input file. The
--  input file is normally the output from the TrES data web site,
--  http://asteroid.lowell.edu/LARI/mged.html or a CSV formatted file
--  with each record in the same general general format as the web
--  output. The header and trailer lines of the raw input file should
--  be removed.  The expected column order of the data for each record
--  is Julian date, Magnitude, Magnitude uncertainty (error). No other
--  data may be included in the file because the procedure will
--  recognize extraneous data as an error condition.
--
--  The second argument is the name of the output file. The output
--  file will be provided in CSV format with three columns. The first
--  column contains the sample frequency. The second column is the
--  sample period (1/frequency). The third column is the BLS spectrum
--  at each of the frequency values. One may think of these values as
--  the "power" of the frequency.
--
--  If the algorithm detects a exoplanet transit, the BLS spectrum
--  will show a peak in the spectrum at the frequency corresponding to
--  (1/period) where period is the planetary orbital period. It will
--  also write a few details about the detection at the terminal.
--  
--  </description>
--
with Astro,
  Astro.Bls,
  Ada.Text_IO,
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

procedure Mged_Data_Bls is
   package Ast is new Astro(Integer, Long_Float); use Ast;
   package Bls is new Ast.Bls; use Bls;
   package Lfio is new Float_IO (Long_Float); use Lfio;
   package Iio is new Integer_Io (Integer); use Iio;
   Time, Mag, Error, P                  : F1_Array_Ptr;
   Tail, Line_Count, Line_Count_2, 
     Array_Length, First,
     Selector, From, Ptr, Fini, Last,
     Nf, Nb, In1, In2                   : Natural;
   Src, Dst                             : File_Type;
   Buffer                               : String (1 .. 512);
   Number_Str, Number_Str2              : String (1 .. 32);
   Src_File, Dst_File                   : String(1 .. 128);
   Delimiter                            : Character_Set;
   T1, Df, Frequency_Min,
     Qma, Qmi, Bper,
     Bpow, Depth, Qtran, Freq           : Long_Float;
   User_Error, Data_Error               : exception;
   
begin
   --
   --  Get the command line arguments. The Cli procedure provides
   --  default values for everything except the source file and
   --  destination file names.
   --
   Cli(Src_File, Dst_File, Nf, Frequency_Min, Df, Nb, Qmi, Qma);
   --
   --  Verify the source file is present and, if so, open it.
   --
   begin
      Open (Src, In_File, Trim(Src_File,Both));
   exception
      when others =>
         Error_Msg
           ("mged_data_bls",
            "The procedure could not open the specified input file, " &
	      Trim(Src_File,Both) & ".  " &
              "Often, this error occurs when the file name is " &
              "misspelled or the file does not exist.");
         raise User_Error;
   end;
   --
   --  Count the number of lines in the input file.
   --
   Line_Count := 0;
   while not End_Of_File(Src) loop
      Get_Line(Src,Buffer,Tail);
      Line_Count := Line_Count + 1;
   end loop;
   --
   --  There must be some data in the file if the procedure is to
   --  continue.
   --
   if Line_Count < 3 then
      Error_Msg
	("mged_data_bls",
	 "The the specified input file, " & Trim(Src_File,Both) &
	   ", contained insufficient data to perform the analysis. " &
	   "Often this problem occurs when the file is empty.");
      Close(Src);
      raise Data_Error;
   end if;
   --
   --  Allocate the data arrays
   --
   Time := new F1_Array(1..Line_Count);
   Mag := new F1_Array(1..Line_Count);
   Error := new F1_Array(1..Line_Count);
   --
   -- Make a second pass over the data to read the numbers
   --
   Reset(Src);
   Line_Count_2 := 0;
   Ptr := 0; -- Ptr is the index for the data arrays.
   Delimiter := To_Set(", ");
   while not End_Of_File(Src) loop
      Get_Line(Src,Buffer,Tail);
      Line_Count_2 := Line_Count_2 + 1;
      if Trim(Buffer(1..Tail),Both) = "" then
	 Put(Number_Str,Line_Count_2);
	 Error_Msg("mged_data_bls",
		   "The procedure found an empty line in the data file." &
		     "The offending line number is " &
		     Trim(Number_Str,Both) & ".");
	 raise Data_Error;
      end if;
      Ptr := Ptr + 1;  
      Selector := 0; -- Is the array selector index, i.e. Time,Mag,Error
      From := 1;
      loop
	 Find_Token(Buffer(From..Tail),Delimiter,Outside,First,Last);
	 exit when Last = 0;
	 Selector := Selector + 1;
	 exit when Selector > 3;
	 case Selector is
	    when 1 => Get(Buffer(First..Last),Time(Ptr),Fini);
	    when 2 => Get(Buffer(First..Last),Mag(Ptr),Fini);
	    when 3 => Get(Buffer(First..Last),Error(Ptr),Fini);	
	    when others => raise Data_Error;
	 end case;
	 From := Last + 1;
      end loop;
      if Selector < 3 then
	 Error_Msg
	   ("mged_data_bls",
	    "The procedure encounted a line from the input file " &
	      "that contained fewer than the required three data. " &
	      "The offending line is """ & 
	      Trim(Buffer(1..Tail),Both) & """");
	 raise Data_Error;
      end if;
   end loop;
   Close(Src);
   --for I in 1 .. Line_Count loop
   --   Put(Time(I),5,7,0);Put(" ");
   --   Put(Mag(I),3,4,0);Put(" ");
   --   Put(Error(I),3,4,0);New_Line;
   --end loop;
   --
   --  We have read the data so invoke the BLS algorithm.
   --
   --  Normalize the time. This operation assumes the time is in
   --  increasing order. It is not a serious problem if this is a
   --  wrong assumption
   --
   T1 := Time(1);
   --for I in 1 .. Line_Count loop
   --   Put(Time(I),7,7,0);Put(" ");
   --   Time(I) := Time(I) - T1;
   --   Put(Time(I),7,7,0);New_Line;
   --end loop; 
   Array_length := Nf;
   P := new F1_Array(1..Array_Length);
   --
   --  Invoke the BLS algorithm
   --
   Eebls(Line_Count, Time.all, Mag.all, Nf, Frequency_Min,
	 Df, Nb, Qmi, Qma, P.all, Bper, Bpow, Depth, Qtran, In1, In2);
   --
   -- Print some statistics
   --
   Put("The BLS procedure has read and analyzed "); Put(Line_Count,5);
   Put(" data and produced a ""box spectra"" of "); Put(Array_Length,5);
   Put(" frequencies.");New_Line;
   Put("Input Data Count = ");Put(Line_Count);New_Line;
   --Put("mag'last = ");Put(Mag'Last);New_Line;
   Put("Period at spectrum maximum = ");Put(Bper,4,7,0);New_Line;
   Put("Value of spectrum maximum = ");Put(Bpow,4,7,0);New_Line;
   Put("Depth of transit (mag)  = ");Put(Depth,4,7,0);New_Line;
   Put("Fractional transit length (transit_length/period) = ");
   Put(Qtran,2,7,0);New_Line;
   Put("Bin index (transit start) = ");Put(In1);New_Line;
   Put("Bin index (transit end) = ");Put(In2);New_Line;
   --
   --  Open the output (destination) file.
   --
   begin
      Create (Dst, Out_File, Trim(Dst_File,Both));
   exception
      when others =>
         Error_Msg
           ("mged_data_bls",
            "The procedure could not open the specified output " &
              "file. Often this error occurs when the user does " &
              "not have write privleges in the destination " &
              "directory.");
         raise User_Error;
   end;
   for I in 1 .. Nf loop
      if abs(P(I)) > 0.00000001 then
	 Freq := Frequency_Min + Long_Float(I-1) * Df;
	 Put(Dst,Freq,3,9,0);Put(Dst,",");
	 Put(Dst,1.0/Freq,7,7,0);Put(Dst,",");
	 Put(Dst,P(I),7,7,0);
	 New_Line(Dst);
      end if;
   end loop;
   Put (Number_Str, Line_Count);
   Put (Number_Str2, Array_Length);
   Status_Msg
     ("mged_data_bls",
      "This procedure successfully processed " &
	Trim (Number_Str, Both) & " input records from " & Trim(Src_File,Both) &
	". It wrote a ""box"" frequency spectrum of " & 
	Trim(Number_Str2,Both) & 
	" records into " & Trim(Dst_File,Both) & ".");
   Close (Dst);
   Free_F1_Array(Time);
   Free_F1_Array(Mag);
   Free_F1_Array(Error);
   Free_F1_Array(P);
exception
   when others =>
      if Is_Open(Dst) then
	 Close(Dst);
      end if;
      if Is_Open(Src) then
	 Close(Src);
      end if;
      if Time /= null then
	 Free_F1_Array(Time);
      end if;
      if Mag /= null then
	 Free_F1_Array(Mag);
      end if;
      if Error /= null then
	 Free_F1_Array(Error);
      end if;
      if P /= null then
	 Free_F1_Array(P);
      end if;
      --Put (Number_Str, Line_Count);
      --Error_Msg ("mged_data_bls",
      --           "This procedure experienced an error on or near line " &
      --             Trim (Number_Str, Both) & ". The output file may be " &
      --             "valid up to that line. Terminating.");
      raise;
end Mged_Data_Bls;
