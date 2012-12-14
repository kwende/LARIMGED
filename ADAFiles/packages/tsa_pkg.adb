with
Utility,
     Ada.Numerics,
     Ada.Numerics.Generic_Elementary_Functions;
use
  Utility,
    Ada.Numerics;

package body Tsa_Pkg is

   package Sort is new Float_Sort (Integer, Long_Float, F1_Array, I1_Array); use Sort;
   package Gef is new Generic_Elementary_Functions (Long_Float); use Gef;

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

end Tsa_Pkg;
