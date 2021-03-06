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
