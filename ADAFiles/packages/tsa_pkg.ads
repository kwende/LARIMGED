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
Astro,
     Ada.Numerics,
     Ada.Numerics.Float_Random;
use
  Ada.Numerics,
    Ada.Numerics.Float_Random;

package tsa_pkg is

   package Ast is new Astro(Integer,Long_Float); use Ast;

   --  This function returns the maximum value in a floating point array.
   function Maximum
     (Numbers : in F1_Array) return Long_Float;

   --  This function returns the minimum value in a floating point array.
   function Minimum
     (Numbers : in F1_Array) return Long_Float;

   --  This function returns the median value of a floating point array.
   function Median (Data : in F1_Array) return Long_Float;

   --  This function returns the sum of all the values in a floating point array.
   function Total (Data : in F1_Array) return Long_Float;

   --  This procedure calculates the mean, variance, skewness, and kurtosis
   --  of a one dimensional floating point array.
   procedure Moment
     ( Data : in F1_Array;
      Mean : out Long_Float;
      Variance : out Long_Float;
      Skewness : out Long_Float;
      Kurtosis : out Long_Float);

   --  This function returns the median skew of a floating point array. U
   --  have no idea what that is.
   function Median_Skew (Data : in F1_Array) return Long_Float;

   --  This procedure interpolates. Suppose we have a function y1 = f(x1) specified
   --  by an array of x1 values and an array of y1 values. Further suppose we
   --  want to know the values of y for another set of x values say x2. We define
   --  the x2 in an array and this procedure produces the new values of y in
   --  an array, say y2. The number of elements in y2 is the same as the number
   --  of elements in x2 and the y2 values are calculated by linear interpolation.
   procedure Interpolate
     (X1, Y1, X2 : in F1_Array;
      Y2         : out F1_Array);

   function Normal_Distribution
     (Gen  : Generator)  return Long_Float;

   --  I am not sure what this does.
   procedure Random_Walk
     (Time_Stamps : in F1_Array;
      Delta_T     : in Long_Float;
      Delta_Mag   : in Long_Float;
      Random_Walk_Result : out F1_Array;
      Full_Time_Stamps   : out F1_Array_Ptr;
      Full_Walk          : out F1_Array_Ptr);


--  <description>
--  This procedure computes the lomb-scargle periodogram of an
--  unevenly sampled lightcurve.
--
--  The Lomb Scargle power spectral density (PSD) is computed
--  according to the
--  definitions given by Scargle, 1982, ApJ, 263, 835, and Horne
--  and Baliunas, 1986, MNRAS, 302, 757. Beware of patterns and
--  clustered data points as the Horne results break down in
--  this case! Read and understand the papers and this
--  code before using it! For the fast algorithm read W.H. Press
--  and G.B. Rybicki 1989, ApJ 338, 277.
--
--  The code is still stupid in the sense that it wants normal
--  frequencies, but returns angular frequency...
--
--  CALLING SEQUENCE:
--   scargle,t,c,om,px,fmin=fmin,fmax=fmax,numf=numf,pmin=pmin,pmax=pmax,
--            nu=nu,period=period,omega=omega,fap=fap,signi=signi
--
--  INPUTS:
--         time: The times at which the time series was measured
--         rate: the corresponding count rates
--
--  OPTIONAL INPUTS:
--         fmin,fmax: minimum and maximum frequency (NOT ANGULAR FREQ!)
--                to be used (has precedence over pmin,pmax)
--         pmin,pmax: minimum and maximum PERIOD to be used
--         omega: angular frequencies for which the PSD values are
--                desired
--         fap : false alarm probability desired
--               (see Scargle et al., p. 840, and signi
--               keyword). Default equal to 0.01 (99% significance)
--         noise: for the normalization of the periodogram and the
--            compute of the white noise simulations. If not set, equal to
--            the variance of the original lc.
--         multiple: number of white  noise simulations for the FAP
--            power level. Default equal to 0 (i.e., no simulations).
--         numf: number of independent frequencie
--
--  KEYWORD PARAMETERS:
--         old : if set computing the periodogram according to J.D.Scargle
--            1982, ApJ 263, 835. If not set, computing the periodogram
--            with the fast algorithm of W.H. Press and G.B. Rybicki,
--            1989, ApJ 338, 277.
--         debug: print out debugging information if set
--         slow: if set, a much slower but less memory intensive way to
--            perform the white noise simulations is used.
--
--  OUTPUTS:
--            om   : angular frequency of PSD
--            psd  : the psd-values corresponding to omega
--
--
--  OPTIONAL OUTPUTS:
--            nu    : normal frequency  (nu=omega/(2*!DPI))
--            period: period corresponding to each omega
--            signi : power threshold corresponding to the given
--                    false alarm probabilities fap and according to the
--                    desired number of independent frequencies
--            simsigni : power threshold corresponding to the given
--                    false alarm probabilities fap according to white
--                    noise simulations
--            psdpeaksort : array with the maximum peak pro each simulation
--
--  Programming notes:
--  This procedure is a translation from IDL code. IDL uses a very
--  different paradigm than Ada so the translation is not always
--  straight-forward. From a programming perspective, the optional
--  parameters can be completely undefined in IDL where in Ada, they
--  must have some default value. So, the default values shown in
--  this file are designed to be completely non-sensical to simulate an
--  undefined value.
--  </description>

   procedure Scargle
     (T : in F1_Array;
      C : in F1_Array;
      Om : out F1_Array;
      Px : out F1_Array; -- Does this correspond to psd above?
      Fmin : in Long_Float := -1.0;
      Fmax : in Long_Float := -1.0;
      Numf : in Integer := -1;
      Nu : out F1_Array;
      Period : out F1_Array;
      Omega : in F1_Array_Ptr := null;
      Fap : in Long_Float := 0.01;
      Signi : out Long_Float;
      Simsigni : out Long_Float;
      Pmin : in Long_Float := -1.0;
      Pmax : in Long_Float := -1.0;
      Old : in Boolean := False;
      Psdpeaksort : out Long_Float;
      Multiple : in Long_Float := 0.0;
      Noise : in Long_Float := 0.0;
      Debug : in Boolean := False;
      Slow : in Boolean := False);

end tsa_pkg;
