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

--  Copyright 2013 Bruce W. Koehn, Lowell Observatory
--
--  <description> 
--
--  This package provides an implementation of the Box Least-Squares
--  fitting (BLS) algorithm described by Kovacs, G., Zucker, S. and
--  Mazeh, T. "A box-fitting algorithm in the search for periodic
--  transits."  A&A 391:369-377 (2002). The code has been translated
--  from FORTRAN to Ada.  The FORTRAN was provided by Kovacs at
--  http://www.konkoly.hu/staff/kovacs/index.html.  The source FORTRAN
--  code was slightly modified from the original BLS routine by Kovacs
--  to consider Edge Effect (EE) as suggested by Peter R.  McCullough
--  [ pmcc@stsci.edu ].
--
--  This modification was motivated by considering the cases when the
--  low state (the transit event) happened to be divided between the
--  first and last bins. In these rare cases the original BLS yields
--  lower detection efficiency because of the lower number of data
--  points in the bin(s) covering the low state.
--
--  For further comments/tests see www.konkoly.hu/staff/kovacs.html
--
--  </description>
--
--  n = number of data points
--
--  t = array {t(i)}, containing the time values of the time series
--
--  x = array {x(i)}, containing the data values of the time series
--
--  nf = number of frequency points in which the spectrum is computed
--
--  fmin = minimum frequency (MUST be > 0)
--
--  df = frequency step
--
--  nb = number of bins in the folded time series at any test period
--
--  qmi = minimum fractional transit length to be tested
--
--  qma = maximum fractional transit length to be tested
--
--  Output parameters:
--
--  p = array {p(i)}, containing the values of the BLS spectrum at the
--  i-th frequency value.  The frequency values are computed as f =
--  fmin + (i-1)*df
--  
--  bper = period at the highest peak in the frequency spectrum
--
--  bpow = value of {p(i)} at the highest peak
--
--  depth= depth of the transit at *bper*
--  
--  qtran= fractional transit length [ T_transit/bper ]
--
--  in1 = bin index at the start of the transit [ 0 < in1 < nb+1 ]
--
--  in2 = bin index at the end of the transit [ 0 < in2 < nb+1 ]
--
--  Remarks: 
--
--  *fmin* MUST be greater than *1/total time span*
--
--  *nb* MUST be lower than *nbmax*
--
--  Dimensions of arrays {y(i)} and {ibi(i)} MUST be greater than or
--  equal to *nbmax*.
--
--  The lowest number of points allowed in a single bin is equal to
--  MAX(minbin,qmi*N), where *qmi* is the minimum transit length/trial
--  period, *N* is the total number of data points, *minbin* is the
--  preset minimum number of the data points per bin.
--
--  The package also provides a command line interface for the parameters
--  of Eebls.
--
generic

package Astro.Bls is
   
   procedure Eebls
     (N     : in  Astro_Integer;
      T     : in  F1_Array;
      X     : in  F1_Array;
      Nf    : in  Astro_Integer;
      Fmin  : in  Astro_Float;
      Df    : in  Astro_Float;
      Nb    : in  Astro_Integer;
      Qmi   : in  Astro_Float;
      Qma   : in  Astro_Float;
      P     : out F1_Array;
      Bper  : out Astro_Float;
      Bpow  : out Astro_Float;
      Depth : out Astro_Float;
      Qtran : out Astro_Float;
      In1   : out Astro_Integer;
      In2   : out Astro_Integer);
   
   procedure Cli
     (Src_File : out String;
      Dst_File : out String;
      Nf       : out Astro_Integer;
      Fmin     : out Astro_Float;
      Df       : out Astro_Float;
      Nb       : out Astro_Integer;
      Qmi      : out Astro_Float;
      Qma      : out Astro_Float);
   
end Astro.Bls;
