with 
  Ada.Command_Line,
  Ada.Text_Io,
  Ada.Strings,
  Ada.Strings.Fixed,
  Messages;
use
  Ada.Command_Line,
  Ada.Text_Io,
  Ada.Strings,
  Ada.Strings.Fixed,
  Messages;

package body Astro.Bls is
   --  For procedure Eebls
   --
   --  n = number of data points. Note: we will keep this parameter
   --  in case there are more array elements than data.
   --
   --  t = array {t(i)}, containing the time values of the time series
   --
   --  x = array {x(i)}, containing the data values of the time series
   --
   --  nf = number of frequency points in which the spectrum is
   --  computed. Note: The number of frequency points should cover the
   --  frequencies from minimum to maximum, (see fmin below) and
   --  should be spaced by the value of df (defined below), i.e., nf =
   --  (frequency_max - frequency_min)/df. Normally, the the user
   --  select some "frequency max" and then calculates the
   --  corrsponding value for this parameter.
   --
   --  fmin = minimum frequency (MUST be > 0) Note: The units of
   --  frequency will generally be 1/day assuming the time series is
   --  specified in JD. The shortest period will probably be about
   --  three hours which corresponds to a frequency 8 cycles per
   --  day. If we expect to see three transits in a season, the
   --  longest period will be about 50 days with a corresponding
   --  frequency of 0.02 cycles per day so this number will generallly
   --  correspond to the minimum frequency.
   --
   --  df = frequency step. Note: We want the frequency step to be
   --  small enough that the phasing at the longest period will be
   --  close enough that the planet transit overlap is easy to
   --  recognize. The worst case will be at the longest period, i.e.,
   --  50 days. Let's assume we have a short transit time but it must
   --  cover at least two consecutive observations. For TrES, this
   --  corresponds to a transit time of 30 minutes. If we test a
   --  period of 50 days +/- 0.25 hr., we will fail to match the first
   --  and last transits (assuming the transit lasts 0.5 hr). If we
   --  test a period of 50 days +/- 0.125 hr (0.0052 days), we will
   --  get a partial match. So our frequency step should be 1/50 -
   --  1/50.0052 = 1.0 X 10^-6
   --
   --  nb = number of bins in the folded time series at any test
   --  period. Note: Some users recommend nb=50. I think that the bin
   --  size should correspond to a time smaller than the minimum
   --  transit time.  The folded time series will have a time t_f such
   --  that 0.125d<=t_f<=50d. The transit time t_t, will be
   --  0.04d<=t_t<=1.0d. So max(t_f)/min(t_t) should give the number
   --  of bins in worst case, i.e., 1250.  This is significantly
   --  larger than the recommended time so I don't know what is going
   --  on.
   --
   --  qmi = minimum fractional transit length to be tested. Note 1:
   --  "Fractional transit length is (transit length)/(trial period).
   --  Note 2: Since the transit can occur near the limb of the star,
   --  the observed value of this parameter can be very short. For a
   --  "distant" planet like Earth, the maximum transit time,
   --  expressed as a ratio, is 13 Hours/365 days or 0.0015. For a
   --  very hot Jupiter orbiting the Sun, the maximum transit time,
   --  expressed as a ratio, is 1.1 hours/0.2 days = 0.046 days/0.2
   --  days = 0.23. As this value gets smaller, the procedure searchs
   --  for exoplanet orbits more distant from the star. At the same
   --  time, the procedure is better able to find transits of small
   --  orbit planets transiting near the limb of the star.
   --
   --  qma = maximum fractional transit length to be tested. See the
   --  notes for qmi. As this value gets larger, the procedure searchs
   --  exoplanet orbits closer to the star.
   --
   --  Output parameters:
   --
   --  p = array {p(i)}, containing the values of the BLS spectrum at
   --  the i-th frequency value.  The frequency values are computed as
   --  f = fmin + (i-1)*df
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
   --  Dimensions of arrays {y(i)} and {ibi(i)} MUST be greater than
   --  or equal to *nbmax*.
   --
   --  The lowest number of points allowed in a single bin is equal to
   --  MAX(minbin,qmi*N), where *qmi* is the minimum transit
   --  length/trial period, *N* is the total number of data points,
   --  *minbin* is the preset minimum number of the data points per
   --  bin.
   --     
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
      In2   : out Astro_Integer) is
      
      Y : F1_Array(1 .. 2000);
      Ibi : I1_Array(1 .. 2000);
      U, V : F1_Array_Ptr;
      Array_Size, Minbin, Nbmax, Kmi, Kma, Kkmi, Nb1,
	Nbkma, J, Jn1, Jn2, Jnb, K, Kk, Nb2 : Astro_Integer;
      Tot, Rn, T1, F0, P0, Ph, S, Power, Rn1, Rn3, S3, Pow : Astro_Float;
      Stored_Error : Boolean;
      Data_Error, User_Error, Programming_Error : exception;
      
   begin
      --
      --  T, X, U, V, P are all to be arrays of the same length. They
      --  must be at least N elements in length. Test it.
      --
      U := new F1_Array(1..N);
      V := new F1_Array(1..N);
      Stored_Error := False;
      Array_Size := T'Last - T'First + 1;
      if Array_Size < N then
	 Stored_Error := True;
      end if;
      Array_Size := X'Last - X'First + 1;
      if Array_Size < N then
	 Stored_Error := True;
      end if;
      Array_Size := P'Last - P'First + 1;
      if Array_Size < N then
	 Stored_Error := True;
      end if;
      if Stored_Error then
	 Error_Msg("Astro.Eelbs",
		   "At least one of T, X, U, V, or P have an array " &
		     "size smaller than N.");
	 raise Programming_Error;
      end if;
      Minbin := 5;
      --
      --  I think Nbmax is a check to make sure there are not too many
      --  bins in the folded time series. I recommended 1250 in the
      --  notes above so 2000 is probably OK.
      --
      Nbmax := 2000;
      if Nb > Nbmax then
	 Error_Msg("Astro.Eelbs",
		   "Nb is larger the NBmax.");
	 raise Programming_Error;
      end if;
      --
      --  This code segment assumes that the time series is sorted in
      --  time.  This may not be a good assumption. I should probably
      --  put in some code to find the minimum and maximum time value.
      --
      Tot := T(N)-T(1);
      if Fmin < 1.0/Tot then 
	 Error_Msg("Astro.Eelbs",
		   "fmin is less than 1/T.");
	 raise Programming_Error;
      end if;
      Rn := Astro_Float(N);
      --  idint is a FORTRAN function that converts real to integer
      --  and rounds toward zero.  The Ada equivalent is
      --  Integer(Float'Truncation(Argument))
      Kmi := Astro_Integer(Astro_Float'Truncation(Qmi*Astro_Float(Nb)));
      if Kmi < 1 then
	 Kmi := 1;
      end if;
      Kma := Astro_Integer(Astro_Float'Truncation(Qma*Astro_Float(Nb)))+1;
      Kkmi := Astro_Integer(Astro_Float'Truncation(Rn*Qmi));
      if Kkmi < Minbin then
	 Kkmi := Minbin;
      end if;
      Bpow := 0.0;
      --
      --  The following variables are defined for the extension of
      --  arrays ibi() and y() [ see below ]
      --
      Nb1 := Nb+1;
      Nbkma := Nb+Kma;
      --
      --  Set temporal time series
      --
      S := 0.0;
      T1 := T(1);
      for I in 1 .. N loop
	 U(I) := T(I)-T1;
	 S := S+X(I);
      end loop;
      S := S/Rn;
      for I in 1 .. N loop
	 V(I) := X(I)-S;
      end loop;
      --
      --  Start period search     *
      --
      for Jf in 1..Nf loop
	 F0 := Fmin+Df*Astro_Float(Jf-1);
	 P0 := 1.0/F0;
	 --
	 --  Compute folded time series with *p0* period
	 --
	 --  Ada considers a loop as a "block" and looping variables
	 --  (Jj) can be used without declaration in the block. They
	 --  become undefined outside the block.  In the original
	 --  FORTRAN code, this looping variable was J.  However, J is
	 --  defined as an integer in the definitions at the top of
	 --  the program. So, we use Jj here to avoid confusion.
	 --
	 for Jj in 1 .. Nb loop
	    Y(Jj) := 0.0;
	    Ibi(Jj) := 0;
	 end loop;
	 for I in 1 .. N loop  
	    Ph := U(I)*F0;
	    Ph := Ph-Astro_Float'Truncation(Ph);
	    J := 1 + 
	      Astro_Integer(Astro_Float'Truncation(Astro_Float(Nb)*Ph));
	    Ibi(J) := Ibi(J) + 1;
	    Y(J) := Y(J) + V(I);
	 end loop;
	 --
	 --  Extend the arrays ibi() and y() beyond nb by wrapping
	 --
	 for Jj in Nb1..Nbkma loop
	    Jnb := Jj-Nb;
	    Ibi(Jj) := Ibi(Jnb);
	    Y(Jj) := Y(Jnb);
	 end loop;
	 --
	 --  Compute BLS statistics for this period
	 --
	 Power := 0.0;
	 for I in 1..Nb loop
	    S := 0.0;
	    K := 0;
	    Kk := 0;
	    Nb2 := I+Kma;
	    for Jj in I .. Nb2 loop
	       K := K+1;
	       Kk := Kk+Ibi(Jj);
	       S := S+Y(Jj);
	       if K < Kmi then
		  goto Two;
	       end if;
	       if Kk < Kkmi then
		  goto One;
	       end if;
	       Rn1 := Astro_Float(Kk);
	       Pow := S*S/(Rn1*(Rn-Rn1));
	       if Pow < Power then
		  goto Two;
	       end if;
	       Power := Pow;
	       Jn1 := I;
	       Jn2 := Jj;
	       Rn3 := Rn1;
	       S3 := S;
	   <<Two>> null;
	    end loop;   
	<<One>> null;
	 end loop;
	 Power := Sqrt(Power);
	 P(Jf) := Power;
	 if Power < Bpow then
	    goto Onehundred;
	 end if;
	 Bpow := Power;
	 In1 := Jn1;
	 In2 := Jn2;
	 Qtran := Rn3/Rn;
	 Depth := -S3*Rn/(Rn3*(Rn-Rn3));
	 Bper := P0;
     <<Onehundred>> null;
      end loop;
      --
      --  Edge correction of transit end index
      --
      if In2 > Nb then
	 In2 := In2-Nb;
      end if;
   end Eebls;
   
   procedure Cli
     (Src_File : out String;
      Dst_File : out String;
      Nf       : out Astro_Integer;
      Fmin     : out Astro_Float;
      Df       : out Astro_Float;
      Nb       : out Astro_Integer;
      Qmi      : out Astro_Float;
      Qma      : out Astro_Float) is
      
      package Lfio is new Float_Io(Astro_Float); use Lfio;
      package Iio is new Integer_Io(Astro_Integer); use Iio;
      Data_Error, User_Error, Programming_Error : exception;
      Number_Str1 : String(1..16);
      Fmax : Astro_Float;

      procedure Case_Error (Ndx : in Astro_Integer) is
      begin
	 Error_Msg
	   ("Astro.Bls",
	    "Command line flag " & Argument(2*Integer(Ndx) - 1) &
	      " is not a valid flag. The valid flags are " &
	      "-freq_max, -freq_min, -freq_delta, -bin_count, " &
	      "-transit_max, and -transit_min. This error may be " &
	      "generated if the first two command line arguments " &
	      "are not the input and output file names");
	 raise User_Error;
      end Case_Error;
      
      procedure Get_Iarg
	(I : in Astro_Integer;
	 J : out Astro_Integer) is
	 Last : Natural;
      begin
	 begin
	    Get(Argument(2*Integer(I)),J,Last);
	 exception
	    when others =>
	       Error_Msg
		 ("Astro.Bls",
		  "The argument for the " & 
		    Argument(2*Integer(I)-1) & " flag " &
		    "cannot be converted into an integer number.");
	       raise User_Error;
	 end;
	 --
	 --  Now perform a sanity check on the value.  The sanity
	 --  check verifies only the absolute range of the value. It
	 --  does not check its relationship to other values.  That
	 --  goes at the end of the procedure
	 --
	 if Argument(2*Integer(I)-1) = "-bin_count" then 
	    --  The bin count should be at least 50. It can get very
	    --  large but that increases execution time.
	    if J < 50 then
	       Error_Msg
		 ("Astro.Bls",
		  "The bin count should be at least 50 " &
		    "to get some resolution on the width of the transit.");
	       raise User_Error;
	    end if;
	    if J > 2000 then
	       Error_Msg
		 ("Astro.Bls",
		  "The bin count should be less than 2000 " &
		    "so the program will complete in a reasonable time.");
	       raise User_Error;
	    end if;
	 end if;
      end Get_Iarg;
      
      procedure Get_Farg
	(I : in Astro_Integer;
	 R : out Astro_Float) is
	 Last : Natural;
      begin
	 begin
	    Get(Argument(2*Integer(I)),R,Last);
	 exception
	    when others =>
	       Error_Msg
		 ("Astro.Bls",
		  "The argument for the " & 
		    Argument(2*Integer(I)-1) & " flag " &
		    "cannot be converted into a floating point number.");
	       raise User_Error;
	 end;
	 --
	 --  Now perform a sanity check on the value.  The sanity
	 --  check verifies only the absolute range of the value. It
	 --  does not check its relationship to other values.  That
	 --  goes at the end of the procedure
	 --
	 if Argument(2*Integer(I)-1) = "-freq_max" then 
	    --  The maximum frequency should be less than the
	    --  frequency corresponding to a one hour period,
	    --  i.e., 24.0 cycles/day.
	    if R > 24.0 then
	       Error_Msg
		 ("Astro.Bls",
		  "The maximum frequency ""-freq_max"" should be " &
		    "less than 24.0 cycles per day.");
	       raise User_Error;
	    end if;
	 elsif Argument(2*Integer(I)-1) =  "-freq_min" then
	   --  The minimum frequency should be less than the
	   --  frequency corresponding to a 180 day period,
	   --  i.e., 0.005555 cycles/day.
	   if R < 0.0055555555 then
	      Error_Msg
		("Astro.Bls",
		 "The minimum frequency ""-freq_min"" should be " &
		   "greater than 0.005555 cycles per day.");
	      raise User_Error;
	   end if;
	 elsif Argument(2*Integer(I)-1) = "-freq_delta" then
	    --  The frequency step should be greater than
	    --  zero. There are other checks on this parameter
	    --  that can only be done when all the other
	    --  parameters are known.
	    if R <= 0.0 then
	       Error_Msg
		 ("Astro.Bls",
		  "The frequency step ""-freq_delta"" should be " &
		    "greater than 0.0.");
	       raise User_Error;
	    end if;
	 elsif Argument(2*Integer(I)-1) = "-transit_max" then
	    --  The maximum fractional transit time normally
	    --  corresponds to the transit of a planet very near
	    --  a star. For a Sun-like transit, this corresponds
	    --  to 1.1 hours/4.8 hours.  For a more massive star
	    --  the transit time could remain the same but the
	    --  period could get shorter.  To allow for such
	    --  situations let's say 1 hour/3 hours.
	    if R >= 0.3333333 then
	       Error_Msg
		 ("Astro.Bls",
		  "The maximum fractional transit time " &
		    """-transit_max"" will never be greater " &
		    "than 0.333333333.");
	       raise User_Error;
	    end if;
	 elsif Argument(2*Integer(I)-1) = "-transit_min" then
	    --  The minimum fractional transit time should
	    --  correspond to a very short transit for a planet
	    --  with a very long period. The shortest transit we
	    --  can reasonably observe is 30 minutes (1 day
	    --  /48).  The longest period we can reasonably
	    --  expect to find is 180 days. So the minimum value
	    --  permitted is 1 / (48 * 180).
	    if R < 0.0001157407 then
	       Error_Msg
		 ("Astro.Bls",
		  "The minimum fractional transit " &
		    "time ""-transit_min"" " &
		    "should be greater than 0.0001158.");
	       raise User_Error;
	    end if;
	    --  The final "else" is not required because that test
	    --  has already been done.
	 end if;
      end Get_Farg;
	       
   begin
      --
      --  Basic command line error check
      --
      if Argument_Count < 2 or
	Argument_Count > 14 then
	 Put(Number_Str1,Astro_Integer(Argument_Count));
	 Error_Msg
	   ("Astro.Bls",
	    "There must be at least two and no more than 14 " &
	      "command line arguments (including flags). " &
	      "This procedure found " & Trim(Number_Str1,Both) & 
	      " arguments.");
	 raise User_Error;
      end if;
      if (Argument_Count/2) * 2 /= Argument_Count then
	 Error_Msg
	   ("Astro.Bls",
	    "There must be an even number of arguments " &
	      "in the command line. " &
	      "This procedure found an odd number.");
	 raise User_Error;
      end if;
      --
      --  Set the default values
      --
      Df := 1.0e-4;
      Fmax := 8.0;
      Fmin := 0.02;
      Nb := 400;
      Qmi := 0.0015;
      Qma := 0.25;
      --
      --  Parse the arguments
      --
      for I in 1 .. Astro_Integer(Argument_Count/2) loop
	 --  The arguments are presented in pairs so the index
	 --  I represents the pair index.
	 if I = 1 then
	    --  The first pair is the input and output file names.
	    Move(Argument(1),Src_File);
	    Move(Argument(2),Dst_File);
	 end if;
	 if I > 1 then
	    --  First of pair is the flag (argument keyword)
	    --  Second of pair is the value.
	    if Argument(2*Integer(I) - 1) = "-freq_max" then
	       Get_Farg(I,Fmax);
	    elsif Argument(2*Integer(I) - 1) = "-freq_min" then
	       Get_Farg(I,Fmin);
	    elsif Argument(2*Integer(I) - 1) = "-freq_delta" then
	       Get_Farg(I,Df);
	    elsif Argument(2*Integer(I) - 1) = "-bin_count" then
	       Get_Iarg(I,Nb);
	    elsif Argument(2*Integer(I) - 1) = "-transit_max" then
	       Get_Farg(I,Qma);
	    elsif Argument(2*Integer(I) - 1) = "-transit_min" then
	       Get_Farg(I,Qmi); 
	    else 
	       Case_Error(I);
	    end if;
	 end if;
      end loop;
      --
      --  Final error check
      --
      if Fmax <= Fmin then
	 Error_Msg
	   ("Astro.Bls",
	    "The frequency maximum (freq_max) must be greater than " &
	      "the frequency minimum (freq_min).");	 
	 raise User_Error;
      end if;
      if (Fmax - Fmin) <= Df then
	 Error_Msg
	   ("Astro.Bls",
	    "The difference between the maximum and minimum orbital " &
	      "frequency (freq_max - freq_min) must be greater than " &
	      "the change in " &
	      "frequency (freq_delta).");
	 raise User_Error;
      end if;
      Nf := Astro_Integer((Fmax - Fmin)/Df);
      if Qmi >= Qma then
	 Error_Msg
	   ("Astro.Bls",
	    "The transit maximum (transit_max) must be greater " &
	      "than the transit minimum (transit_min). " &
	      "The transit min and max are the ratio of the transit time " &
	      "to the orbital period.");
	 raise User_Error;
      end if;
      --  Nb has already been checked in Iarg.
   end Cli;
   
end Astro.Bls;
