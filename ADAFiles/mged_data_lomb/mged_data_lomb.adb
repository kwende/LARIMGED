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
--  <description> This procedure uses the Lomb (/Scargle) algorithm
--  descirbed in "Numerical Recipes" to find periods in non-uniform
--  times series of stellar photometric observations.  It creates a
--  frequency/power relation much like a Fourier analysis but it
--  performs well with sparse or non-uniform time series. The
--  procedure is non-windowed and must be invoked from a terminal (or
--  virtual terminal). It expects two comand line arguments: an input
--  file name and an output file name.
--
--  The first command line argument is the name of the input file. The
--  input file is normally the output from the TrES data web site,
--  http://asteroid.lowell.edu/LARI/mged.html or a CSV formatted file
--  with each record in the same general general format as the web
--  output. The header and trailer lines of the raw input file should
--  be removed.  The expected order of the data for each record is
--  Julian date, Magnitude, Magnitude uncertainty (error). No other
--  data may be included in the file becausew the procedure will
--  recognize extraneous data as an error condition.
--
--  The second argument is the name of the output file. The output
--  file is in CSV format which and it contains the frequency and the
--  "power" of the frequency in columns 1 and 3.  The corresponding
--  period is in column 2. The frequency is the inverse of the the
--  input times.  That is, if the input time is specified in days
--  (Julian Date, e.g.) then the frequency is in cycles/day. The unit
--  for the period is the same at the input time.
--
--  </description>
--
--  Error Correction Log
--  2013-03-12 Fixed some error message problems.
--  2013-03-12 Removded some debug statements.
--
with Astro,
  Astro.Lomb,
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

procedure Mged_Data_Lomb is
   package Ast is new Astro(Integer, Long_Float); use Ast;
   package Al is new Ast.Lomb; use Al;
   package Lfio is new Float_IO (Long_Float);
   use Lfio;
   package Iio is new Integer_Io (Integer); use Iio;
   Time, Mag, Error, Px, Py             : F1_Array_Ptr;
   Tail, First, Last, Line_Count, Line_Count_2, 
     Nout, Jmax, Array_Length,
     Selector, From, Ptr, Fini          : Natural;
   Src, Dst                             : File_Type;
   Buffer                               : String (1 .. 512);
   Number_Str                           : String (1 .. 32);
   Delimiter                            : Character_Set;
   Ofac, Hyfac, Prob, T1                : Long_Float;
   User_Error, Data_Error : exception;
   
begin
   --
   --  Verify the correct number of command line arguments are present.
   --
   if Argument_Count /= 2 then
      Error_Msg
        ("mged_data_lomb",
         "This procedure requires exactly two " &
           "command line arguments. The first is the source data " &
           "file name. The second is the output file name for " &
           "the result file.");
      raise User_Error;
   end if;
   --
   --  Verify the command lines arguments are not empty
   --
   if Trim (Argument (1), Both) = "" then
      Error_Msg ("mged_data_lomb",
                 "The input file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty input file name.");
      raise User_Error;
   end if;
   if Trim (Argument (2), Both) = "" then
      Error_Msg ("mged_data_lomb",
                 "The output file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty output file name.");
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
           ("mged_data_lomb",
            "The procedure could not open the specified input file, " &
	      Trim(Argument(1),Both) & ".  " &
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
	("mged_data_lomb",
	 "The the specified input file, " & Trim(Argument(1),Both) &
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
	 Error_Msg("mged_data_lomb",
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
	   ("mged_data_lomb",
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
   --  We have read the data so invoke the Lomb algorithm.
   --
   --  Normalize the time. This operation assumes the time is in
   --  increasing order.
   --
   T1 := Time(1);
   --for I in 1 .. Line_Count loop
   --   Put(Time(I),7,7,0);Put(" ");
   --   Time(I) := Time(I) - T1;
   --   Put(Time(I),7,7,0);New_Line;
   --end loop; 
   Ofac := 4.0; -- Oversampling factor
   Hyfac := 8.0; -- Multiple of the Nyquist freq, defines frequency search limit
   Array_length := Integer(Long_Float'Floor
			     (0.5*Ofac*Hyfac*Long_Float(Line_Count)));
   Px := new F1_Array(1..Array_Length);
   Py := new F1_Array(1..Array_Length);
   --
   --  Invoke the Lomb algorithm
   --
   Period(Time.all,Mag.all,Line_Count,Ofac,Hyfac,Px.all,Py.all,Nout,Jmax,Prob);
   --
   -- Print some statistics
   --
   Put("Data Count = ");Put(Line_Count);New_Line;
   --Put("mag'last = ");Put(Mag'Last);New_Line;
   Put("Oversampling factor = ");Put(Ofac,4,4,0);New_Line;
   Put("Nyquist factor multiplier = ");Put(Hyfac,4,4,0);New_Line;
   Put("Number of output frequencies  = ");Put(Nout);New_Line;
   Put("Index of largest ""power"" = ");Put(Jmax);New_Line;
   Put("Probability of non-noise in most powerful (smaller is better) = ");Put(Prob,4,4,0);New_Line;
   --
   --  Open the output (destination) file.
   --
   begin
      Create (Dst, Out_File, Argument (2));
   exception
      when others =>
         Error_Msg
           ("mged_data_lomb",
            "The procedure could not open the specified output " &
              "file. Often this error occurs when the user does " &
              "not have write privleges in the destination " &
              "directory.");
         raise User_Error;
   end;
   for I in 1 .. Nout loop
      if abs(Px(I)) > 0.00001 then
	 Put(Dst,Px(I),3,9,0);Put(Dst,",");
	 Put(Dst,1.0/Px(I),7,7,0);Put(Dst,",");
	 Put(Dst,Py(I),7,7,0);
	 New_Line(Dst);
      end if;
   end loop;
   Put (Number_Str, Line_Count);
   Status_Msg
     ("mged_data_lomb",
      "This procedure successfully processed " &
	Trim (Number_Str, Both) & " input records from " & Argument (1) &
	" into " & Argument (2) & ".");
   Close (Dst);
   Free_F1_Array(Time);
   Free_F1_Array(Mag);
   Free_F1_Array(Error);
   Free_F1_Array(Px);
   Free_F1_Array(Py);
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
      if Px /= null then
	 Free_F1_Array(Px);
      end if;
      if Py /= null then
	 Free_F1_Array(Py);
      end if;
      --Put (Number_Str, Line_Count);
      --Error_Msg ("mged_data_lomb",
      --           "This procedure experienced an error on or near line " &
      --             Trim (Number_Str, Both) & ". The output file may be " &
      --             "valid up to that line. Terminating.");
      raise;
end Mged_Data_Lomb;
