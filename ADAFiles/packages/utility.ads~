   --  <description>
   --
   --  These routines sort a list of numbers using the
   --  Quick Sort algorithm. It returns a list of integers
   --  which are the indices of the sorted numbers in ascending
   --  sorted order. The original list of numbers is unchanged.
   --
   --  The generic packages provides two versions of the algorithm:
   --  one for integers and one for float numbers. They are placed in
   --  separate subpackages and are instantiated in a way analogous to
   --  the Integer_io and Float_io packages.
   --
   --  A third procedure, Sort_Randomizer, randomizes the indices
   --  of the array to be sorted.  Because Quick Sort performs as N^2
   --  when the input array is already sorted, the randomizing of
   --  the array tries to insure that the input array is unsorted
   --  where the sort performs as N*(log(N)).
   --  However, there is an extremely small probability that the
   --  randomizer will actually sort the array.  But, this would be
   --  a serious violation of the second law of thermodynamics.
   --
   --  Errors:
   --
   --  The size of the input array cannot exceed 2**64.  If the number
   --  of numbers to be sorted is less than 1, an exception is
   --  raised. If it is 1, no sorting can occur.
   --
   --  Implementation details:
   --
   --  This algorithm is normally implemented recursively.
   --  This implementation, instead, uses an internal
   --  stack to keep track of the unsorted segments which obviates the
   --  need for recursion. This seems important because the recursive
   --  depth can be as many as the number of numbers to be sorted.
   --
   --  Some years later now and I have concluded that if the sort is
   --  implemented recursively and the algorithm first chooses the shorter
   --  of the two strings generated in the recursion, the recursion
   --  depth will never be greater than log(N). Not bad at all and perfectly
   --  permissible for this algorithm. The speed may suffer a little with
   --  recursion.
   --  </description>
   --
package Utility is
   generic
      type Local_Integer is range <>;
      type Local_Float is digits <>;
      type Flt_Array is array (Local_Integer range <>) of Local_Float;
      type Int_Array is array (Local_Integer range <>) of Local_Integer;

   package Float_Sort is

      procedure Sort_Randomizer
        (Order  : in out Int_Array;
         Length : in     Local_Integer);

      procedure Qsort
        (Data   : in     Flt_array;
         Order  : in out Int_Array;
         Length : in     Local_Integer);

   end Float_Sort;

   generic
      type Local_Integer is range <>;
      type Int_Array is array (Local_Integer range <>) of Local_Integer;
   package Integer_Sort is

      procedure Sort_Randomizer
        (Order  : in out Int_Array;
         Length : in     Local_Integer);

      procedure Qsort
        (Data   : in     Int_Array;
         Order  : in out Int_Array;
         Length : in     Local_integer);

   end Integer_Sort;

end Utility;
