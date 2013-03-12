with 
  Ada.Text_Io;
use
  Ada.Text_Io;

package body Astro.Lomb is
   
   package Fio is new Float_Io(Astro_Float); use Fio;
   
   procedure Avevar
     (Data : in F1_Array;
      Ave : out Astro_Float;
      Var : out Astro_Float) is
      N : Astro_Integer;
      Sum : Astro_Float;
      -- Sums : Astro_Float;
      S : F1_Array_Ptr;
   begin
      N := Data'Last - Data'First + 1;
      Sum := 0.0;
      for I in Data'First .. Data'Last loop
	 Sum := Sum + Data(I);
      end loop;
      Ave := Sum/Astro_Float(N);
      S := new F1_Array(Data'First..Data'Last);
      for I in Data'First .. Data'Last loop
	 S(I) := Data(I) - Ave;
      end loop;
      Var := 0.0;
      for I in Data'First .. Data'Last loop
	 Var := Var + S(I)**2;
      end loop;
      --Sums := 0.0;
      --for I in Data'First .. Data'Last loop
      --  Sums := Sums + S(I)**2;
      --end loop;
      --Var := (Var - (Sums**2/Astro_Float(N)))/Astro_Float(N-1);
      Free_F1_Array(S);
   end Avevar;
   
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
      Prob : out Astro_Float) is

      Ave,C,Cc,Cwtau,Effm,Expy,Pnow,Pymax,S,Ss,Sumc,Sumcy,
	Sums,Sumsh,Sumsy,Swtau,Var,Wtau,Xave,Xdif, 
	Yy,Xmax, Xmin, Arg,Wtemp : Astro_Float;
      Np : Astro_Integer;
      subtype Array_Size is Astro_Integer range 1 .. N;
      Wi,Wpi,Wpr,Wr : F1_Array_Ptr;
      Twopi : constant := 6.2831853071795865;
      User_Error, Data_Error : exception;
      
   begin
      Nout := Astro_Integer(Astro_Float'Floor(0.5*Ofac*Hifac*Astro_Float(N)));
      Np := Px'Last - Px'First + 1;
      if Nout > Np then
	 Put_Line("Output arrays are too short to contain all periods.");
	 raise User_Error;
      end if;
      --Get mean and variance of the input data.
      Avevar(Y, Ave, Var); 
      -- Put("Average magnitude = ");Put(Ave,5,5,0);New_Line;
      -- Put("Variance magnitude = ");Put(Var,5,5,0);New_Line;
      if Var = 0.0 then
	 Put_Line("Zero variance in the period.");
	 raise Data_Error;
      end if;
      Wi := new F1_Array(1..N);
      Wpi := new F1_Array(1..N);
      Wpr := new F1_Array(1..N);
      Wr := new F1_Array(1..N);
      --Go through data to get the range of abscissas.
      Xmax := X(1);
      Xmin := X(1);
      Put_Line("Inside Lomb");
      Put("First time value = ");Put(X(1),7,7,0);New_Line;
      Put("Last time value = ");Put(X(Astro_Integer(N)),7,7,0);New_Line;      
      for J in 1 .. Astro_Integer(N) loop
	 if X(J) > Xmax then
	    Xmax := X(J);
	 end if;
	 if X(J) < Xmin then
	    Xmin := X(J);
	 end if;
      end loop;
      Xdif := Xmax - Xmin;
      Xave := 0.5 * (Xmax + Xmin);
      Put("Abcissa range = ");Put(Xdif,4,2,0);New_Line;
      Put("Abcissa mean = ");Put(Xave,4,2,0);New_Line;
      Pymax := 0.0;
      --Starting frequency.
      Pnow := 1.0 / (Xdif * Ofac);
      --Initialize values for the trigonometric recurrences at each data
      --point.
      for J in 1.. Astro_Integer(N) loop
         Arg := Twopi * ((X(J) - Xave) * Pnow); 
         Wpr(J) := -2.0 * Sin(0.50 * Arg)**2; 
         Wpi(J) := Sin(Arg);
         Wr(J) := Cos(Arg);
         Wi(J) := Wpi(J);
      end loop;
      --Main loop over the frequencies to be evaluated.
      for I in 1 .. Nout loop 
         Px(I) := Pnow;
         Sumsh := 0.0;
	 --First, loop over the data to get tau and related quantities.
         Sumc := 0.0;
         for J in 1 .. Astro_Integer(N) loop
            C := Wr(J);
            S := Wi(J);
            Sumsh := Sumsh + (S * C);
            Sumc := Sumc + ((C - S) * (C + S));
         end loop;
         Wtau := 0.5 * Arctan(2.0 * Sumsh, Sumc);
         Swtau := Sin(Wtau);
         Cwtau := Cos(Wtau);
         Sums := 0.0;
         Sumc := 0.0;
	 --Then, loop over the data again to get the periodogram value.
         Sumsy := 0.0;
         Sumcy := 0.0;
         for J in 1 .. Astro_Integer(N) loop
            S := Wi(J);
            C := Wr(J);
            Ss := (S * Cwtau) - (C * Swtau);
            Cc := (C * Cwtau) + (S * Swtau);
            Sums := Sums + (Ss**2);
            Sumc := Sumc + (Cc**2);
            Yy := Y(J)-Ave;
            Sumsy := Sumsy + (Yy * Ss);
            Sumcy := Sumcy + (Yy * Cc);
	    --Update the trigonometric recurrences.
            Wtemp := Wr(J) ;
            Wr(J) := ((Wr(J) * Wpr(J)) - (Wi(J) * Wpi(J))) + Wr(J);
            Wi(J) := ((Wi(J) * Wpr(J)) + (Wtemp * Wpi(J))) + Wi(J);
         end loop;
         Py(I) := 0.5 * (((Sumcy**2) / Sumc) + ((Sumsy**2) / Sums)) / Var;
         if Py(I) >= Pymax then
            Pymax := Py(I);
            Jmax := I;
         end if;
	 --The next frequency.
         Pnow := Pnow + (1.0 / (Ofac * Xdif)); 
      end loop;
      --Evaluate statistical signiﬁcance of the maximum.
      Expy := Exp(-Pymax); 
      Effm := 2.0 * Astro_Float(Nout) / Ofac;
      Prob := Effm * Expy;
      if Prob > 0.01 then
	 Prob := 1.0 - ((1.0 - Expy)**Effm);
      end if;
      Free_F1_Array(Wi);
      Free_F1_Array(Wpi);
      Free_F1_Array(Wr);
      Free_F1_Array(Wpr);
   end Period;
   
end;
