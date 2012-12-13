generic
   type Pfloat is digits <>;

package Polynomial_Pkg is

   function Chebyshev
     (Order    : Natural;
      Argument : Pfloat) return Pfloat;

end Polynomial_Pkg;
