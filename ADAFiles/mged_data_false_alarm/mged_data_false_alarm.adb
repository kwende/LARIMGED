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
-- This procedure computes the lomb-scargle periodogram of an
-- unevenly sampled lightcurve.
--
-- The Lomb Scargle power spectral density (PSD) is computed
-- according to the
-- definitions given by Scargle, 1982, ApJ, 263, 835, and Horne
-- and Baliunas, 1986, MNRAS, 302, 757. Beware of patterns and
-- clustered data points as the Horne results break down in
-- this case! Read and understand the papers and this
-- code before using it! For the fast algorithm read W.H. Press
-- and G.B. Rybicki 1989, ApJ 338, 277.
--
-- The code is still stupid in the sense that it wants normal
-- frequencies, but returns angular frequency...
--
--
-- CALLING SEQUENCE:
--   scargle,t,c,om,px,fmin=fmin,fmax=fmax,numf=numf,pmin=pmin,pmax=pmax,
--            nu=nu,period=period,omega=omega,fap=fap,signi=signi
--
--
-- INPUTS:
--         time: The times at which the time series was measured
--         rate: the corresponding count rates
--
--
-- OPTIONAL INPUTS:
--         fmin,fmax: minimum and maximum frequency (NOT ANGULAR FREQ!)
--                to be used (has precedence over pmin,pmax)
--         pmin,pmax: minimum and maximum PERIOD to be used
--         omega: angular frequencies for which the PSD values are
--                desired
--         fap : false alarm probability desired
--               (see Scargle et al., p. 840, and signi
--               keyword). Default equal to 0.01 (99% significance)
--         noise: for the normalization of the periodogram and the
--            compute of the white noise simulations. If not set, equal to
--            the variance of the original lc.
--         multiple: number of white  noise simulations for the FAP
--            power level. Default equal to 0 (i.e., no simulations).
--         numf: number of independent frequencies
--
--
-- KEYWORD PARAMETERS:
--         old : if set computing the periodogram according to J.D.Scargle
--            1982, ApJ 263, 835. If not set, computing the periodogram
--            with the fast algorithm of W.H. Press and G.B. Rybicki,
--            1989, ApJ 338, 277.
--         debug: print out debugging information if set
--         slow: if set, a much slower but less memory intensive way to
--            perform the white noise simulations is used.
--
-- OUTPUTS:
--            om   : angular frequency of PSD
--            psd  : the psd-values corresponding to omega
--
--
-- OPTIONAL OUTPUTS:
--            nu    : normal frequency  (nu=omega/(2*!DPI))
--            period: period corresponding to each omega
--            signi : power threshold corresponding to the given
--                    false alarm probabilities fap and according to the
--                    desired number of independent frequencies
--            simsigni : power threshold corresponding to the given
--                    false alarm probabilities fap according to white
--                    noise simulations
--            psdpeaksort : array with the maximum peak pro each simulation
--
--  </description>
with Ada.Text_Io,
     Ada.Command_Line,
     Ada.Strings,
     Ada.Strings.Fixed,
     Ada.Strings.Maps,
     Astro,
     Messages,
     Tsa_Pkg;
use Ada.Text_Io,
    Ada.Command_Line,
    Ada.Strings,
    Ada.Strings.Fixed,
    Ada.Strings.Maps,
    Messages,
    Tsa_Pkg;

procedure Mged_Data_False_Alarm is
   package Ast is new Astro (Integer, Long_Float); use Ast;
   package Fio is new Float_Io (Long_Float); use Fio;
   package Iio is new Integer_Io (Integer); use Iio;
   type S1_Array is array (Integer range <>) of String (1 .. 64);
   type S1_Array_Ptr is access S1_Array;
   Src, Dst : File_Type;
   Line_Count, N_Lcs, Tail, Ndx, Ptr, First, Last,
   Terminus, N_Points : Natural;
   K : Integer;
   Delimiter : Character_Set;
   Done : Boolean;
   Buffer : String (1 .. 512);
   All_Lcs : S1_Array_Ptr;
   Minps, Maxps, Scrambled_Pxs, Cumulative, Mag, Timestamp,
     Epoch : F1_Array_Ptr;
   N_Ps, N_Trials : I1_Array_Ptr;
   Minimum_Time, Max_Mag, Min_Mag, Mag_Difference : Long_Float;
   User_Error : exception;

   function Minimum
     (Numbers : in F1_Array) return Long_Float is
      Min_Number : Long_Float;
      Argument_Error : Exception;
   begin
      if Numbers'First - Numbers'Last = 0 then
         raise Argument_Error;
      end if;
      Min_Number := Numbers(Numbers'First);
      for I in Numbers'First .. Numbers'Last loop
         if Numbers (I) < Min_Number then
            Min_Number := Numbers (I);
         end if;
      end loop;
      return Min_Number;
   end Minimum;


   function Maximum
     (Numbers : in F1_Array) return Long_Float is
      Argument_Error : Exception;
      Max_Number : Long_Float;
   begin
      if Numbers'First - Numbers'Last = 0 then
         raise Argument_Error;
      end if;
      Max_Number := Numbers(Numbers'First);
      for I in Numbers'First .. Numbers'Last loop
         if Numbers (I) > Max_Number then
            Max_Number := Numbers (I);
         end if;
      end loop;
      return Max_Number;
   end Maximum;

begin
   --
   --  Verify the required command line arguments are present.
   --
   if Argument_Count /= 2 then
      Error_Msg ("mged_data_false_alarm",
                 "This procedure requires exactly two command line " &
                   "arguments. Two arguments were not found. The first " &
                   "argument is the name of the file containing the " &
                   "data. The second argument is the prototype file " &
                   "name of the output files.");
      raise User_Error;
   end if;
   --
   --  Verify the command lines are not empty
   --
   if Trim (Argument (1), Both) = "" then
      Error_Msg ("mged_data_false_alarm",
                 "The input file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty input file name.");
      raise User_Error;
   end if;
   if Trim (Argument (2), Both) = "" then
      Error_Msg ("mged_data_false_alarm",
                 "The output prototype file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty output prototype file name.");
      raise User_Error;
   end if;
   --
   --  Verify that the specified source file is present and open it.
   --
   begin
      Open (Src, In_File, Argument (1));
   exception when others =>
         Error_Msg ("mged_data_false_alarm",
                    "The procedure is unable to open the input data " &
                      "file. This error ususally occurs if the data " &
                      "file name is misspelled or if the data file " &
                      "does not exist.");
         raise User_Error;
   end;
   --
   --  Read data from the source file
   --
   --  Read all the lines.  Count them but do nothing else.
   --
   Line_Count := 0;
   while not End_Of_File (Src) loop
      Get_Line (Src, Buffer, Tail);
      Line_Count := Line_Count + 1;
   end loop;
   Reset (Src);
   --
   --  There must be at least one line.
   --
   if Line_Count > 0 then
      N_Lcs := Line_Count;
   else
      Error_Msg ("mged_data_false_alarm",
                 "The source data file is empty. Its " &
                   "name is " & Argument(1) & ".");
      raise User_Error;
   end if;
   --
   --  Allocate the required arrays.
   --
   All_Lcs := new S1_Array (1 .. Line_Count);
   Minps := new F1_Array (1 .. Line_Count);
   Maxps := new F1_Array (1 .. Line_Count) ;
   N_Ps := new I1_Array (1 .. Line_Count);
   N_Trials := new I1_Array (1 .. Line_Count);
   --
   --  Read the all the lines again but assign the values to the variables.
   --
   Delimiter := To_Set (" ,");
   Ndx := 0;
   while not End_Of_File (Src) loop
      Get_Line (Src, Buffer, Tail);
      Ndx := Ndx + 1;
      Ptr := 0;
      Last := 0;
      Done := False;
      --
      --  Find each token in the line and convert it to a float.
      --  There must be at least 5 tokens. If not, raise an error;
      --
      while not Done loop
         Find_Token (Buffer (Last + 1 .. Tail), Delimiter, Outside,
                    First,Last);
         if Last > 0 then
            Ptr := Ptr + 1;
            case Ptr is
               when 1 => Move (Buffer (First .. Last), All_Lcs (Ptr));
               when 2 => Get(Buffer(First..Last),Minps(Ptr),Terminus);
               when 3 => Get(Buffer(First..Last),Maxps(Ptr),Terminus);
               when 4 => Get(Buffer(First..Last),N_Ps(Ptr),Terminus);
               when 5 => Get(Buffer(First..Last),N_Trials(Ptr),Terminus);
               when others => exit;
            end case;
         else
            exit;
         end if;
      end loop;
      if Ptr /= 5 then
         Error_Msg ("mged_data_false_alarm",
                    "A line in the input file did not have the " &
                      "required five numbers. The offending line is """ &
                   Buffer(1..Tail) & """");
         raise User_Error;
      end if;
   end loop;
   Close(Src);
   --
   --  Open the output file
   begin
      Create (Dst, Out_File, Argument (2));
   exception
      when others =>
         Error_Msg
           ("mged_data_false_alarm",
            "The procedure could not open the specified output " &
              "file. Often this error occurs when the user does " &
              "not have write privleges in the destination " &
              "directory.");
         raise User_Error;
   end;
   --
   --  Loop through all the files specified in the input file.
   --  Each time through the loop we read another file.
   --
   for I in 1 .. N_Lcs loop
      Scrambled_Pxs := new F1_Array(1 .. N_Trials(I));
      Cumulative := new F1_Array (1 .. N_Trials (I));
      for J in 1 .. N_Trials (I) loop
         Cumulative (J) := Long_Float (J) / Long_Float (N_Trials (I));
      end loop;
      --
      --  Open the next file in sequence
      --
      --  Just to hurry through this, I won't program this in
      --  a safe way.
      --
      Open (Src, In_File, Trim (All_Lcs (I), Both));
      Timestamp := new F1_Array (1 .. N_Trials (I));
      Mag := new F1_Array (1 .. N_Trials (I));
      K := 0;
      while not End_Of_File (Src) loop
         K := K+1;
         Get (Src, Timestamp (K), Terminus);
         Get(Src,Mag(K),Terminus);
      end loop;
      --  Should check that K matches N_Trials.
      Put_Line ("Processing " & Trim (All_Lcs (I), Both) & ".");
      Minimum_Time := Minimum (Timestamp.all);
      Epoch := new F1_Array(Timestamp'First..Timestamp'Last);
      for J in Timestamp'First .. Timestamp'Last loop
         Epoch (J) := Timestamp (J) - Minimum_Time;
      end loop;
      N_Points := Timestamp'Last - Timestamp'First + 1;
      Min_Mag := Minimum (Mag.all);
      Max_Mag := Maximum (Mag.all);
      Mag_Difference := Max_Mag - Min_Mag;
      --  output the data for a plot file
      Free_F1_Array (Mag);
      Free_F1_Array (Timestamp);
      Free_F1_Array (Scrambled_Pxs);
      Free_F1_Array (Cumulative);
      Free_F1_Array (Epoch);
   end loop;
end Mged_Data_False_Alarm;
