with
  Messages;
use
  Messages;
package body Polynomial_Pkg is

   function Chebyshev
     (Order    : Natural;
      Argument : Pfloat) return Pfloat is

      X          : Pfloat;
      N          : Natural;
      User_Error : exception;

   begin
      X := Argument;
      N := Order;
      if abs (X) > 1.0 then
         Error_Msg ("Chebyshev",
                    "The argument for the Chebyshev function " &
                      "is outside the range -1.0 .. 1.0.");
         raise User_Error;
      end if;
      case N is
         --  Put in several of the low order Chebyshev terms
         --  to avoid recursion.
         when 0 => return 1.0;
         when 1 => return X;
         when 2 => return 2.0 * X ** 2 - 1.0;
         when 3 => return 4.0 * X ** 3 - 3.0 * X;
         when 4 => return 8.0 * (X ** 4 - X ** 2) + 1.0;
         when 5 => return 16.0 * X ** 5 - 20.0 * X ** 3 + 5.0 * X;
         when others => return
              2.0 * X * Chebyshev (N - 1, X) - Chebyshev (N - 2, X);
      end case;
   end Chebyshev;

end Polynomial_Pkg;
