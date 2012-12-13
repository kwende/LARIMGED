--  <description>
--  This package is a container for a set of astronomical procedures.
--  It creates some commonly used types and low level procedures that
--  are used by many of the astronomical procedures.
--  </description>
with
  Ada.Unchecked_Deallocation,
  Ada.Numerics,
  Ada.Numerics.Generic_Elementary_Functions,
  Ada.Numerics.Generic_Complex_Types;
use
  Ada.Numerics;

generic

   type Astro_Integer is range <>;
   type Astro_Float is digits <>;

package Astro is

   package Gef is new Ada.Numerics.Generic_Elementary_Functions(Astro_Float);
   use Gef;
   package Cmplx is new Ada.Numerics.Generic_Complex_Types(Astro_Float);
   use Cmplx;

   type F1_Array is array (Astro_Integer range <>) of Astro_Float;
   type F2_Array is array (Astro_Integer range <>,
                           Astro_Integer range <>) of Astro_Float;
   type I1_Array is array (Astro_Integer range <>) of Astro_Integer;
   type I2_Array is array (Astro_Integer range <>,
                           Astro_Integer range <>) of Astro_Integer;
   type C1_Array is array (Astro_Integer range <>) of Complex;
   type C2_Array is array (Astro_Integer range <>,
                           Astro_Integer range <>) of Complex;
   type L1_Array is array (Astro_Integer range <>) of Boolean;
   type L2_Array is array (Astro_Integer range <>,
                           Astro_Integer range <>) of Boolean;

   type F1_Array_Ptr is access F1_Array;
   type F2_Array_Ptr is access F2_Array;
   type I1_Array_Ptr is access I1_Array;
   type I2_Array_Ptr is access I2_Array;
   type C1_Array_Ptr is access C1_Array;
   type C2_Array_Ptr is access C2_Array;
   type L1_Array_Ptr is access L1_Array;
   type L2_Array_Ptr is access L2_Array;

   type Basis_Functions is access procedure
     (X      : in     Astro_Float;
      Values :    out F1_Array;
      N      : in     Astro_Integer);

   type Basis_Functions_2d is access procedure
     (X      : in     Astro_Float;
      Y      : in     Astro_Float;
      Values :    out F1_Array;
      N      : in     Astro_Integer);

   type General_Function_1d is access procedure
     (X      : in     Astro_Float;
      Y      :    out Astro_Float);

   type General_Function_2d is access procedure
     (X      : in     Astro_Float;
      Y      : in     Astro_Float;
      Z      :    out Astro_Float);

   procedure Free_F1_Array is new
     Ada.Unchecked_Deallocation(F1_Array,F1_Array_Ptr);
   procedure Free_F2_Array is new
     Ada.Unchecked_Deallocation(F2_Array,F2_Array_Ptr);
   procedure Free_I1_Array is new
     Ada.Unchecked_Deallocation(I1_Array,I1_Array_Ptr);
   procedure Free_I2_Array is new
     Ada.Unchecked_Deallocation(I2_Array,I2_Array_Ptr);
   procedure Free_C1_Array is new
     Ada.Unchecked_Deallocation(C1_Array,C1_Array_Ptr);
   procedure Free_C2_Array is new
     Ada.Unchecked_Deallocation(C2_Array,C2_Array_Ptr);
   procedure Free_L1_Array is new
     Ada.Unchecked_Deallocation(L1_Array,L1_Array_Ptr);
   procedure Free_L2_Array is new
     Ada.Unchecked_Deallocation(L2_Array,L2_Array_Ptr);

   Pio180 : constant := Pi / 180.0;
   Twopi : constant := 2.0 * Pi;
   Pio2 : constant := Pi / 2.0;

end Astro;
