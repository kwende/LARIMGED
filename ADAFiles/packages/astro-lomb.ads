generic

package Astro.Lomb is   
   
   procedure Period
     (X : in F1_Array;
      Y : in F1_Array;
      N : in Astro_Integer;
      Ofac : in Astro_Float;
      Hifac : in Astro_Float;
      Px : out F1_Array;
      Py : out F1_Array;
      Nout : out Astro_Integer;
      Jmax : out Astro_Integer;
      Prob : out Astro_float);

      --
      --  USES avevar 
      --
      --  Given n data points with abscissas x(1:n) (which need not be
      --  equally spaced) and ordinates y(1:n), and given a desired
      --  oversampling factor ofac (a typical value being 4 or
      --  larger), this routine fills array px with an increasing
      --  sequence of frequencies (not angular frequencies) up to
      --  hifac times the "average" Nyquist frequency, and fills array
      --  py with the values of the Lomb normalized periodogram at
      --  those frequencies. The arrays x and y are not altered.  np,
      --  the dimension of px and py, must be large enough to contain
      --  the output, or an error (pause) results. The routine also
      --  returns jmax such that py (jmax) is the maximum element in
      --  py, and prob, an estimate of the signiﬁcance of that maximum
      --  against the hypothesis of random noise. A small value of
      --  prob indicates that a significant periodic signal is
      --  present.
      --
      --  The important changes between the FORTRAN 90 implementation
      --  and the Ada implementation are listed below:
      --   
      --  External:
      --
      --  The the array size of the data (x,y) can be larger than the
      --  number of data so we will keep n to specify the number of
      --  data. We will assume that they are stored in the first n
      --  elements of the arrays.
      --
      --  The number of output frequencies is (ofac * hifac * n / 2)
      --  so allocate at least that many array elements for px and py
      --  before invoking Period.
      --
      --  The np parameter can be determined from the arrays xp and yp
      --  so it is not required in the parameter list.
      --
      --  Internal:
      --
      --  The maximum expected size of the x and y arrays does not
      --  have significance in Ada in the same way as FORTRAN so it
      --  can be omitted.  The internal working arrays will be
      --  dynamically allocated and deallocated as needed.
end;
