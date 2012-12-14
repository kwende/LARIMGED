with
Astro;

package tsa_pkg is

   package Ast is new Astro(Integer,Long_Float); use Ast;

   function Maximum
     (Numbers : in F1_Array) return Long_Float;

   function Minimum
     (Numbers : in F1_Array) return Long_Float;

   function Median (Data : in F1_Array) return Long_Float;

   function Total (Data : in F1_Array) return Long_Float;

   function Median_Skew (Data : in F1_Array) return Long_Float;

end tsa_pkg;
