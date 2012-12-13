with
  Ada.Numerics.Generic_Elementary_Functions;

package body Primes is

   package Ff is new Ada.Numerics.Generic_Elementary_Functions(Float);

   procedure Prime_Factors (Target       : in     Local_Integer;
                            F            :    out Factors;
                            Factor_Count :    out Local_Integer) is

      Limit, Prime_Ptr, Factor_Ptr, Ltarget : Local_Integer;

   begin
      --  Ltarget and Target are the value for which this procedure is
      --  to find factors.
      Ltarget := Target;
      --  Prime factors can be no larger than sqrt(target).
      Limit := Local_Integer(Float'Floor(Ff.Sqrt(Float(Ltarget))));
      Prime_Ptr := 1;
      Factor_Ptr := 1;
      --  Loop through primes looking for even divisors.
      while Ltarget > 1 loop
         if (Ltarget/P(Prime_Ptr))*P(Prime_Ptr) = Ltarget then
            --  Found an even divisor so record it as a factor.
            F(Factor_Ptr) := P(Prime_Ptr);
            Factor_Ptr := Factor_Ptr + 1;
            --  Remove the factor from the target by dividing the
            --  target by the factor.
            Ltarget := Ltarget/P(Prime_Ptr);
            Limit := Local_Integer(Float'Floor(Ff.Sqrt(Float(Ltarget))));
            loop
               --  Remove all other factors of the same value from
               --  target by dividing.
               if (Ltarget/P(Prime_Ptr))*P(Prime_Ptr) = Ltarget then
                  Ltarget := Ltarget/P(Prime_Ptr);
                  Limit := Local_Integer(Float'Floor(Ff.Sqrt(Float(Ltarget))));
               else
                  exit;
               end if;
            end loop;
            exit when Ltarget = 1;
         else
            --  If the prime is not a factor, move to the next prime.
            Prime_Ptr := Prime_Ptr + 1;
         end if;
         --  Record anything left as a factor.
         if (P(Prime_Ptr) > Limit) and (Ltarget /= 1) then
            F(Factor_Ptr) := Ltarget;
            Factor_Ptr := Factor_Ptr + 1;
            exit;
         end if;
      end loop;
      --  If there was only one factor and it was the target, the that
      --  does not count as a factor.
      Factor_Count := Factor_Ptr - 1;
      if Factor_Count = 1 then
         if F(Factor_Count) = Target then
            Factor_Count := 0;
         end if;
      end if;
   end Prime_Factors;

   function Is_Prime(Target : in Local_Integer) return Boolean is

      Prime_Ptr, Limit : Local_Integer;

   begin
      --  If a target number is not prime, it must have at least one
      --  factor smaller than sqrt(target).
      Limit := Local_Integer(Float'Floor(Ff.Sqrt(Float(Target))));
      Prime_Ptr := 1;
      --  Loop through primes smaller than sqrt(target). If a prime
      --  evenly divides the target then the target is not prime.
      while (P(Prime_Ptr) <= Limit) and (Prime_Ptr <= Prime_Count) loop
         if (Target/P(Prime_Ptr))*P(Prime_Ptr) = Target then
            return False;
         else
            Prime_Ptr := Prime_Ptr + 1;
         end if;
      end loop;
      --  Otherwise it is prime.
      return True;
   end;

end Primes;
