with
Ada.Text_Io,
     Primes,
     Interfaces;
use
  Ada.Text_Io,
    Interfaces;

package body Utility is

   package body Float_Sort is

      package Iprimes is new Primes (Local_Integer); use Iprimes;

      procedure Sort_Randomizer
        (Order  : in out Int_Array;
         Length : in     Local_Integer) is

         Lo, Hi, Count, Ndx : Local_Integer;
         A, C, M, B : Integer_64;
         F : Factors;

      begin
         --  This algorithm is adapted from Knuth's Seminumerical Algorithms.
         --  Theorem A.
         --  The linear congruential sequence { X_(n+1) = (aX_(n) - c) mod m }
         --  defined by m, a, c, and X_0
         --  has a period length m if and only if
         --    i) c is relatively prime to m;
         --   ii) b = a - 1 is a multiple of p, for every prime p dividing m;
         --  iii) b is a multiple of 4, if m is a multiple of 4.
         --
         --  We wish to produce a sequence of M (or m) numbers that have
         --  no duplicates and have values between the lowest and highest
         --  subscript value of the Order array.
         --
         --  Programming note: M, A, C are all 64 bits in length so the
         --  MOD function will work correctly. It should handle Order
         --  arrays of up to 1_000_000_000 elements.
         --
         Lo := Order'First;
         Hi := Lo + Length - 1;
         M := Integer_64(Hi - Lo + 1);
         --
         --  B (= A-1) must be a multiple of every prime factor of M.
         --
         Prime_Factors(Local_Integer(M), F, Count);
         if Count = 0 then
            Count := 1;
            F(Count) := Local_Integer(M);
         end if;
         B := 1;
         for I in 1 .. Count loop
            B := B * Integer_64(F(I));
         end loop;
         --
         --  C and M must be relatively prime.
         --
         Ndx := 2000;
         while (Local_Integer(M) mod P(Ndx) = 0) loop
            Ndx := Ndx + 1;
         end loop;
         C := Integer_64(P(Ndx));
         --
         --  If M is a multiple of 4 then B must be a multiple of 4.
         --
         if (M/4)*4 = M then
            loop
               if (B/4)*4 = B then
                  exit;
               else
                  B := B * 2;
               end if;
            end loop;
         end if;
         A := B + 1;
         --
         --  Use the linear congruential method (LCM) to generate a
         --  'random' set of indices. The preceding requirements insure
         --  that every integer in the range Lo to Hi has been generated
         --  exactly once.
         --
         --  Set the first value. Note that the values generated will be
         --  in the range 0 .. M-1
         --
         Order(Lo) := Local_Integer((M-1)/2);
         --
         --  Generate the rest of the values using the LCM. Note that all
         --  the values of order lie between 0 and M-1.
         --
         for I in Lo+1 .. Hi loop
            Order(I) := Local_Integer(( (A * Integer_64(Order(I-1))) -
                                        C ) mod M);
         end loop;
         --
         --  Offset the values so they match the index range. Since the
         --  smallest value of Order is 0, adding Lo will make the
         --  smallest value Lo, just as we desire.
         --
         for I in Lo .. Hi loop
            Order(I) := Order(I) + Lo;
         end loop;

      end Sort_Randomizer;

      procedure Qsort (Data   : in     Flt_Array;
                       Order  : in out Int_Array;
                       Length : in     Local_Integer) is

         Array_Length_Inconsistancy : exception;

         type Stacktype is array ( Local_Integer(0) .. Local_Integer(63) ,
                                   Local_Integer(1) .. Local_Integer(2) )
           of Local_Integer;
         Sp , First, Last, Low, High, Keyndx,
           Dlength, Olength, Ooffset : Local_Integer;
         Stack : Stacktype;
         Key : Local_Float;

      begin
         -- Implementation notes;
         -- This algorithm was originally written for Data and Order arrays
         -- to be of equal length and starting at index 1. Since, in this
         -- implementation, the arrays can be of unequal length and can start
         -- at an arbitrary index, two changes have been made. 1. Checks are
         -- made at the beginning to verify that the lengths of the arrays
         -- are sensible. 2. All references to the Order array have
         -- an offset applied. The order array is initialized so that
         -- it points to elements in the data array no matter what the
         -- starting index. All loops will run from 1 .. Length.
         Dlength := Data'Last - Data'First + 1;
         Olength := Order'Last - Order'First + 1;
         if (Length > Dlength) or (Length > Olength) then
           raise Array_Length_Inconsistancy;
         end if;
         Ooffset := Order'First - 1;
         Sp:=0;
         if  Length > 1 then
            -- This loop points each element of the order array to a
            -- unique element of the data array. From now on, every
            -- reference to the data array will be made through the
            -- order array. The loop should be changed so that Order
            -- is randomized if data is likely to be pre-sorted.
            Sort_Randomizer(Order,Length);
            Stack(Sp,1) := 1;
            Stack(Sp,2) := Length;
            Sp:=1;
            while Sp > 0 loop
               Sp:=Sp-1;
               First:=Stack(Sp,1);
               Last:=Stack(Sp,2);
               while First < Last loop
                  Low:=First;
                  High:=Last;
                  Key:=Data(Order(First + Ooffset));
                  Keyndx:=Order(First + Ooffset);
                  while High > Low loop
                     while (Data(Order(High + Ooffset)) > Key)
                       and (High > Low) loop
                        High:=High-1;
                     end loop;
                     if High > Low then
                        Order(Low + Ooffset) := Order(High + Ooffset);
                        Low:=Low+1;
                     end if;
                     while (Data(Order(Low + Ooffset)) <  Key)
                       and (High > Low) loop
                        Low:=Low+1;
                     end loop;
                     if High > Low then
                        Order(High + Ooffset):=Order(Low + Ooffset);
                        High:=High-1;
                     end if;
                  end loop ;
                  Order(High + Ooffset):=Keyndx;
                  if (High-First >= Last-High) then
                     Stack(Sp,1):=First;
                     Stack(Sp,2):=High-1;
                     Sp:=Sp+1;
                     First:=High+1;
                  else
                     Stack(Sp,1):=High+1;
                     Stack(Sp,2):=Last;
                     Sp:=Sp+1;
                     Last:=High-1;
                  end if;
               end loop ;
            end loop ;
         elsif Length = 1 then
            Order(1 + Ooffset) := Data'First;
         end if;
      end Qsort;

   end Float_Sort;

   package body Integer_Sort is

      package Iprimes is new Primes(Local_Integer); use Iprimes;
      package Iio is new Integer_Io(Local_Integer); use Iio;

      procedure Sort_Randomizer
        (Order  : in out Int_Array;
         Length : in     Local_integer) is

         Lo, Hi, Count, Ndx : Local_Integer;
         A, C, M, B : Integer_64;
         F : Factors;

      begin
         --  This algorithm is adapted from Knuth's Seminumerical Algorithms.
         --  Theorem A.
         --  The linear congruential sequence { X_(n+1) = (aX_(n) - c) mod m }
         --  defined by m, a, c, and X_0
         --  has a period length m if and only if
         --    i) c is relatively prime to m;
         --   ii) b = a - 1 is a multiple of p, for every prime p dividing m;
         --  iii) b is a multiple of 4, if m is a multiple of 4.
         --
         --  We wish to produce a sequence of M (or m) numbers that have
         --  no duplicates and have values between the lowest and highest
         --  subscript value of the Order array.
         --
         --  Programming note: M, A, C are all 64 bits in length so the
         --  MOD function will work correctly. It should handle Order
         --  arrays of up to 1_000_000_000 elements.
         --
         Lo := Order'First;
         Hi := Lo + Length - 1;
         M := Integer_64(Hi - Lo + 1);
         --
         --  B (= A-1) must be a multiple of every prime factor of M.
         --
         Prime_Factors(Local_Integer(M), F, Count);
         if Count = 0 then
            Count := 1;
            F(Count) := Local_Integer(M);
         end if;
         B := 1;
         for I in 1 .. Count loop
            B := B * Integer_64(F(I));
         end loop;
         --
         --  C and M must be relatively prime.
         --
         Ndx := 2000;
         while (Local_Integer(M) mod P(Ndx) = 0) loop
            Ndx := Ndx + 1;
         end loop;
         C := Integer_64(P(Ndx));
         --
         --  If M is a multiple of 4 then B must be a multiple of 4.
         --
         if (M/4)*4 = M then
            loop
               if (B/4)*4 = B then
                  exit;
               else
                  B := B * 2;
               end if;
            end loop;
         end if;
         A := B + 1;
         --
         --  Use the linear congruential method (LCM) to generate a
         --  'random' set of indices. The preceding requirements insure
         --  that every integer in the range Lo to Hi has been generated
         --  exactly once.
         --
         --  Set the first value. Note that the values generated will be
         --  in the range 0 .. M-1
         --
         Order(Lo) := Local_Integer((M-1)/2);
         --
         --  Generate the rest of the values using the LCM. Note that all
         --  the values of order lie between 0 and M-1.
         --
         for I in Lo+1 .. Hi loop
            Order(I) := Local_Integer(( (A * Integer_64(Order(I-1))) -
                                        C ) mod M);
         end loop;
         --
         --  Offset the values so they match the index range. Since the
         --  smallest value of Order is 0, adding Lo will make the
         --  smallest value Lo, just as we desire.
         --
         for I in Lo .. Hi loop
            Order(I) := Order(I) + Lo;
         end loop;

      end Sort_Randomizer;

      procedure Qsort (Data : in int_array;
                       Order : in out Int_Array;
                       Length : Local_Integer) is

         Array_Length_Inconsistancy : exception;

         type Stacktype is array ( Local_Integer(0) .. Local_Integer(63) ,
                                   Local_Integer(1) .. Local_Integer(2) )
           of Local_Integer;
         Sp , First, Last, Low, High, Keyndx,
           Dlength, Olength, Ooffset : Local_Integer;
         Stack : Stacktype;
         Key : Local_Integer;

      begin
         Dlength := Data'Last - Data'First + 1;
         Olength := Order'Last - Order'First + 1;
         if (Length > Dlength) or (Length > Olength) then
           raise Array_Length_Inconsistancy;
         end if;
         Ooffset := Order'First - 1;
         Sp:=0;
         if  Length > 1 then
            Sort_Randomizer(Order,Length);
            Stack(Sp,1) := 1;
            Stack(Sp,2) := Length;
            Sp:=1;
            while Sp > 0 loop
               Sp:=Sp-1;
               First:=Stack(Sp,1);
               Last:=Stack(Sp,2);
               while First < Last loop
                  Low:=First;
                  High:=Last;
                  Key:=Data(Order(First + Ooffset));
                  Keyndx:=Order(First + Ooffset);
                  while High > Low loop
                     while (Data(Order(High + Ooffset)) > Key)
                       and (High > Low) loop
                        High:=High-1;
                     end loop;
                     if High > Low then
                        Order(Low + Ooffset) := Order(High + Ooffset);
                        Low:=Low+1;
                     end if;
                     while (Data(Order(Low + Ooffset)) <  Key)
                       and (High > Low) loop
                        Low:=Low+1;
                     end loop;
                     if High > Low then
                        Order(High + Ooffset):=Order(Low + Ooffset);
                        High:=High-1;
                     end if;
                  end loop ;
                  Order(High + Ooffset):=Keyndx;
                  if (High-First >= Last-High) then
                     Stack(Sp,1):=First;
                     Stack(Sp,2):=High-1;
                     Sp:=Sp+1;
                     First:=High+1;
                  else
                     Stack(Sp,1):=High+1;
                     Stack(Sp,2):=Last;
                     Sp:=Sp+1;
                     Last:=High-1;
                  end if;
               end loop ;
            end loop ;
         elsif Length = 1 then
            Order(1 + Ooffset) := Data'First;
         end if;
      end Qsort;

   end Integer_Sort;

end Utility;
