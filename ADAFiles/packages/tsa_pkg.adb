with
Utility,
     Ada.Numerics.Generic_Elementary_Functions,
     Ada.Text_IO;

use
  Utility,
    Ada.Text_IO;

package body Tsa_Pkg is

   package Sort is new Float_Sort (Integer, Long_Float, F1_Array, I1_Array); use Sort;
   package Gef is new Generic_Elementary_Functions (Long_Float); use Gef;
   package Iio is new Integer_Io (Integer); use Iio;
   package Fio is new Float_Io (Long_Float); use Fio;

   function Minimum
     (Numbers : in F1_Array) return Long_Float is
      Min_Number     : Long_Float;
      Argument_Error : exception;
   begin
      if Numbers'First - Numbers'Last = 0 then
         raise Argument_Error;
      end if;
      Min_Number := Numbers (Numbers'First);
      for I in Numbers'First .. Numbers'Last loop
         if Numbers (I) < Min_Number then
            Min_Number := Numbers (I);
         end if;
      end loop;
      return Min_Number;
   end Minimum;

   function Maximum
     (Numbers : in F1_Array) return Long_Float is
      Argument_Error : exception;
      Max_Number     : Long_Float;
   begin
      if Numbers'First - Numbers'Last = 0 then
         raise Argument_Error;
      end if;
      Max_Number := Numbers (Numbers'First);
      for I in Numbers'First .. Numbers'Last loop
         if Numbers (I) > Max_Number then
            Max_Number := Numbers (I);
         end if;
      end loop;
      return Max_Number;
   end Maximum;

   function Median (Data : in F1_Array) return Long_Float is
      Ndx         : I1_Array_Ptr;
      Length      : Integer;
      Temp        : Long_Float;
      Empty_Array : exception;
   begin
      Length := Data'Last - Data'First + 1;
      if Length < 1 then
         raise Empty_Array;
      end if;
      Ndx := new I1_Array (Data'First .. Data'Last);
      Qsort (Data, Ndx.all, Length);
      Temp := Data (Ndx ((Data'Last + Data'First) / 2));
      Free_I1_Array (Ndx);
      return Temp;
   exception
      when others =>
         Free_I1_Array (Ndx);
         raise;
   end Median;

   function Total (Data : in F1_Array) return Long_Float is
      Sum         : Long_Float;
      Empty_Array : exception;
   begin
      if Data'Last - Data'First + 1 < 1 then
         raise Empty_Array;
      end if;
      Sum := 0.0;
      for I in Data'First .. Data'Last loop
         Sum := Sum + Data (I);
      end loop;
      return Sum;
   end Total;

   procedure Moment
     ( Data    : in F1_Array;
      Mean     : out Long_Float;
      Variance : out Long_Float;
      Skewness : out Long_Float;
      Kurtosis : out Long_Float) is

      Data_Length : Integer;
      Sum, Sigma : Long_Float;
      Data_Error : exception;

   begin
      Data_Length := Data'Last - Data'First + 1;
      if Data_Length < 1 then
         raise Data_Error;
      end if;
      --
      Sum := 0.0;
      for I in Data'First .. Data'Last loop
         Sum := Sum + Data (I);
      end loop;
      Mean := Sum / Long_Float (Data_Length);
      --
      Sum := 0.0;
      for I in Data'First .. Data'Last loop
         Sum := Sum + (Data (I) - Mean) ** 2;
      end loop;
      Variance := Sum / Long_Float (Data_Length - 1);
      --
      Sigma := Sqrt (Variance);
      Sum := 0.0;
      for I in Data'First .. Data'Last loop
         Sum := Sum + ((Data (I) - Mean) / Sigma) ** 3;
      end loop;
      Skewness := Sum / Long_Float (Data_Length);
      --
      Sum := 0.0;
      for I in Data'First .. Data'Last loop
         Sum := Sum + ((Data (I) - Mean) / Sigma) ** 4;
      end loop;
      Kurtosis := Sum / Long_Float (Data_Length) - 3.0;
   end Moment;

   function Median_Skew (Data : in F1_Array) return Long_Float is
      Skewtop, Skewbottom, Med : Long_Float;
      N_Array                  : Integer;
      Empty_Array              : exception;
   begin
      if Data'Last - Data'First + 1 < 1 then
         raise Empty_Array;
      end if;
      N_Array := Data'Last - Data'First + 1;
      Med := Median (Data);
      Skewtop := 0.0;
      Skewbottom := 0.0;
      for I in Data'First .. Data'Last loop
         Skewtop := Skewtop + (Data (I) - Med) ** 3;
      end loop;
      Skewtop := Skewtop / Long_Float (N_Array);
      for I in Data'First .. Data'Last loop
         Skewbottom := Skewbottom + (Data (I) - Med) ** 2;
      end loop;
      Skewbottom := (Skewbottom / Long_Float (N_Array)) ** 1.5;
      return Skewtop / Skewbottom;
   end Median_Skew;

   --  Implementation details: In IDL, this procedure is implmented as a
   --  function.  In Ada, there is some awkwardness in that approach
   --  because we have to use a "return" statement with the value
   --  to be returned as the argument.  Since we are returning an array
   --  and it is not given as an argument, we have to dynamically allocate
   --  the array to put things into. Then we have to issue the return
   --  statement but we cannot deallocate the array prior to the statement
   --  because the array is what we are returning.  We cannot deallocate
   --  after the return statement because we have returned. So, if we
   --  use this function multiple times, we have a memory leak. We solve
   --  the whole problem by implementing this thing as a procedure where
   --  we have the output array available and we need no dynamic memory
   --  allocation.
   procedure Interpolate
     (X1, Y1, X2 : in F1_Array;
      Y2         : out F1_Array) is

      Size_X1, Size_Y1, Size_X2, Size_Y2, Lo_Lim, Hi_Lim,
      Ptr, Ptr_Lo, Ptr_Hi                                      : Integer;
      Increasing, Done                                         : Boolean;
      X, Y                                                     : F1_Array_Ptr;
      Array_Size_Error, Non_Monotonic_Array, Programming_Error : exception;

   begin
      --  Verify that X1 has some elements. Interpolation will
      --  require at least two elements.
      Size_X1 := X1'Last - X1'First + 1;
      if Size_X1 < 2 then
         raise Array_Size_Error;
      end if;
      --  Verify that Y1 has the same number of elements as X1.
      Size_Y1 := Y1'Last - Y1'First + 1;
      if Size_Y1 /= Size_X1 then
         raise Array_Size_Error;
      end if;
      --  Determine if X1 is monotonic.
      if X1 (X1'First + 1) - X1 (X1'First) > 0.0 then
         --  The array seems to be increaseing. Test that all elements
         --  are increasing.
         for I in X1'First .. X1'Last - 1 loop
            Increasing := True;
            if X1 (I + 1) - X1 (I) < 0.0 then
               raise Non_Monotonic_Array;
            end if;
         end loop;
      else
         --  The array seems to be decreasing. Test that all elements
         --  are decreasing.
         for I in X1'First .. X1'Last - 1 loop
            Increasing := False;
            if X1 (I) - X1 (I + 1) < 0.0 then
               raise Non_Monotonic_Array;
            end if;
         end loop;
      end if;
      --  To simplify programming later on, we will make the X1 array
      --  monotonically increasing.  If it is decreasing, we will have to
      --  reverse the order of both the X1 and Y1 arrays. And to get a
      --  consistent name, we have to copy X1 and Y1 for both the increasing
      --  and decreasing array order.
      --
      --  We know that both X1 and Y1 have the same number of elements
      --  It will be convienient if both start with index 1. We will make
      --  that change here too.
      X := new F1_Array (1 .. Size_X1);
      Y := new F1_Array (1 .. Size_X1);
      if Increasing then
         for I in 1 .. Size_X1 loop
            X (I) := X1 (I);
         end loop;
         for I in 1 .. Size_X1 loop
            Y (I) := Y1 (Y1'First + I - 1);
         end loop;
      else
         for I in 1 .. Size_X1 loop
            X (I) := X1 (Size_X1 - I + 1);
         end loop;
         for I in X1'First .. X1'Last loop
            Y (I) := Y1 (Y1'Last - I + 1);
         end loop;
      end if;
      --  The X2 array is not necessarily required to have some elements.
      --  However, the X2 and Y2 arrays should be the same length.
      Size_X2 := X2'Last - X2'First + 1;
      Size_Y2 := Y2'Last - Y2'First + 1;
      if Size_X2 /= Size_Y2 then
         raise Array_Size_Error;
      end if;
      --  For now, this procedure implements only linear interpolation.
      --
      --  Use a binary search to find the two values of X that surround
      --  a value of X2.  If the binary search shows that X2 is less
      --  (or greater) than all values of X, then use the two end values
      --  of X closest to X2.
      for I in X2'First .. X2'Last - 1 loop
         --  Check for end conditions before staring the binary search.
         if X2 (I) <= X (X'First) then
            Lo_Lim := X'First;
            Hi_Lim := X'First + 1;
         elsif X2 (I) >= X (X'Last) then
            Lo_Lim := X'Last - 1;
            Hi_Lim := X'Last;
         else
            --  Because X is monotonic, we can use a Binary Search
            --  to speed things along.
            Ptr_Lo := X'First;
            Ptr_Hi := X'Last;
            Done := False;
            while not Done loop
               Ptr := (Ptr_Hi + Ptr_Lo) / 2;
               if X (Ptr) <= X2 (I) and X (Ptr + 1) >= X2 (I) then
                  Done := True;
                  Lo_Lim := Ptr;
                  Hi_Lim := Ptr + 1;
               elsif X2 (I) >= X1 (Ptr) then
                  Ptr_Lo := Ptr;
               elsif X2 (I) < X1 (Ptr) then
                  Ptr_Hi := Ptr;
               else
                  raise Programming_Error;
               end if;
            end loop;
         end if;
         --  At this point, we have everything we need for the linear
         --  interpolation. We know the indices of the nearest X interpolation
         --  points and we know that the same indicies are good for y.
         Y2 (I) := Y (Lo_Lim) + (Y (Hi_Lim) - Y (Lo_Lim)) * (X2 (I) - X (Lo_Lim)) /
           (X (Hi_Lim) - X (Lo_Lim));
      end loop;
      Free_F1_Array (X);
      Free_F1_Array (Y);
   end Interpolate;

   function Normal_Distribution
     (Gen  : Generator)  return Long_Float is
   begin
      return
        (Sqrt (-2.0 * Log (Long_Float (Random (Gen)), 10.0)) *
           Cos (2.0 * Pi * Long_Float (Random (Gen))));
   end Normal_Distribution;

   procedure Random_Walk
     (Time_Stamps        : in F1_Array;
      Delta_T            : in Long_Float;
      Delta_Mag          : in Long_Float;
      Random_Walk_Result : out F1_Array;
      Full_Time_Stamps   : out F1_Array_Ptr;
      Full_Walk          : out F1_Array_Ptr) is

      Min_Time_Stamp, Max_Time_Stamp : Long_Float;
      N_Points                       : Integer;
      Offsets                        : F1_Array_Ptr;
      Gen                            : Generator;

   begin
      Min_Time_Stamp := Minimum (Time_Stamps);
      Max_Time_Stamp := Maximum (Time_Stamps);
      N_Points := Integer (Long_Float'Floor ((Max_Time_Stamp - Min_Time_Stamp) / Delta_T));
      if Full_Time_Stamps /= null then
         Free_F1_Array (Full_Time_Stamps);
      end if;
      Full_Time_Stamps := new F1_Array (1 .. N_Points);
      for I in 1 .. N_Points loop
         Full_Time_Stamps (I) := Min_Time_Stamp + Long_Float (I - 1) * Delta_T;
      end loop;
      Offsets := new F1_Array (1 .. N_Points);
      Reset (Gen);
      for I in 1 .. N_Points loop
         Offsets (I) := Delta_Mag * Normal_Distribution (Gen);
      end loop;
      if Full_Walk /= null then
         Free_F1_Array (Full_Walk);
      end if;
      Full_Walk := new F1_Array (1 .. N_Points);
      for I in 1 .. N_Points loop
         if I = 1 then
            Full_Walk (I) := Offsets (I);
         else
            Full_Walk (I) := Full_Walk (I - 1) + Offsets (I);
         end if;
      end loop;
      Free_F1_Array (Offsets);
      Interpolate (Full_Walk.all, Full_Time_Stamps.all, Time_Stamps, Random_Walk_Result);
   end Random_Walk;

   procedure Scargle
     (T           : in F1_Array;
      C           : in F1_Array;
      Om          : out F1_Array;
      Px          : out F1_Array; -- Does this correspond to psd above?
      Fmin        : in Long_Float := -1.0;
      Fmax        : in Long_Float := -1.0;
      Numf        : in Integer := -1;
      Nu          : out F1_Array;
      Period      : out F1_Array;
      Omega       : in F1_Array_Ptr := null;
      Fap         : in Long_Float := 0.01;
      Signi       : out Long_Float;
      Simsigni    : out Long_Float;
      Pmin        : in Long_Float := -1.0;
      Pmax        : in Long_Float := -1.0;
      Old         : in Boolean := False;
      Psdpeaksort : out Long_Float;
      Multiple    : in Long_Float := 0.0;
      Noise       : in Long_Float := 0.0;
      Debug       : Boolean := False;
      Slow        : Boolean := False) is

      Time, Temp, Cn: F1_Array_Ptr;
      Array_Length, Numf_Local, N0, Horne : Integer;
      Noise_Local, Mean, Variance, Skewness, Kurtosis, Tau, Var,
        Fmin_Local, Fmax_Local, Sum_A, Sum_B, Sum_C, Sum_D : Long_Float;

   begin
      if Noise = 0.0 then
         Moment (C, Mean, Variance, Skewness, Kurtosis);
         Noise_Local := Sqrt (Variance);
      else
         Noise_Local := Noise;
      end if;
      --  After this point, never use Noise. Always use Noise_Local.
      --  Multiple needs no massaging.
      --  Fap needs no massaging.
      --  Start time at T(0)
      Array_Length := T'Last - T'First + 1;
      Time := new F1_Array (1 .. Array_Length);
      for I in 1 .. Array_Length loop
         Time (I) := T (I) - T (1);
      end loop;
      N0 := Array_Length;
      Horne := Integer (Long_Float'Floor (-6.362 + 1.193 *
          Long_Float (N0) + 0.00098 * Long_Float (N0 ** 2)));
      if Horne < 0 then
         Horne := 5;
      end if;
      if Numf <= 0 then
         Numf_Local := Horne;
      else
         Horne := Numf;
         Numf_Local := Numf;
      end if;
      --  After this point, Numf should never be used but always use Numf_Local
      if Fmin < 0.0 then
         if Pmax < 0.0 then
            Fmin_Local := 1.0 / Maximum (Time.all);
         else
            Fmin_Local := 1.0 / Pmax;
         end if;
      else
         Fmin_Local := Fmin;
      end if;
      --  After this point, Fmin should never be used but always use Fmin_Local.
      if Fmax < 0.0 then
         if Pmin < 0.0 then
            Fmax_Local := Long_Float(N0) / (2.0 * Maximum (Time.all));
         else
            Fmax_Local := 1.0 / Pmin;
         end if;
      else
         Fmax_Local := Fmax;
      end if;
      --  After this point, Fmax should never be used but always use Fmax_local.
      if Omega = null then
         Temp := new F1_Array (1 .. Numf_Local);
         for I in 1 .. Numf_Local loop
            Temp (I) := Long_Float (I - 1);
            Om (I) := 2.0 * Pi * (Fmin_Local +
                                  ( Fmax_Local - Fmin_Local) * Temp (I) /
                                  Long_Float(Numf_Local - 1));
         end loop;
      else
         -- No checking for sizes here.  Probably dangerous.
         Om := Omega.all;
      end if;
      Signi := -Log (1.0 - ((1.0 - Fap) ** (1.0 / Long_Float (Horne))), 10.0);

      if Old then
         Cn := new F1_Array(C'First..C'Last);
         Moment (C, Mean, Variance, Skewness, Kurtosis);
         for I in C'First .. C'Last loop
            Cn (I) := C(I) - Mean;
         end loop;
         for I in 1 .. Numf_Local loop
            Sum_A := 0.0;
            Sum_B := 0.0;
            for J in Time'First .. Time'Last loop
               Sum_A := Sum_A + Sin (2.0 * Om (I) * Time (J));
               Sum_B := Sum_B + Cos (2.0 * Om (I) * Time (J));
            end loop;
            Tau := Arctan (Sum_A / Sum_B);
            Tau := Tau/(2.0*Om(I));
            Sum_A := 0.0;
            Sum_B := 0.0;
            Sum_C := 0.0;
            Sum_D := 0.0;
            for J in Time'First .. Time'Last loop
               Sum_A := Sum_A + Cn (J) * Cos (Om (I) * (Time (J)-Tau));
               Sum_B := Sum_B + Cos (Om (I) * (Time (J)-Tau)) ** 2;
               Sum_C := Sum_C + Cn (J) * Sin (Om (I) * (Time (J) - Tau));
               Sum_D := Sum_D + Sin (Om (I) * (Time (J)-Tau)) ** 2;
            end loop;
            Px(I) := 0.5 * (Sum_A**2/Sum_B + Sum_C**2/Sum_D);
         end loop;
         Moment (Cn.all, Mean, Variance, Skewness, Kurtosis);
         Var := Variance;
         if Var /= 0.0 then
            for I in 1 .. Numf_Local loop
               Px (I) := Px (I) / Var;
            end loop;
         else
            Put_Line ("Scargle Warning: Variance is zero.");
         end if;
         for I in 1 .. Numf_Local loop
            Nu (I) := Om (I) / (2.0 * Pi);
            Period (I) := 1.0 / Nu (I);
         end loop;
         return;
      end if;

   end Scargle;

end Tsa_Pkg;
