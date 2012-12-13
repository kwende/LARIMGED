with
Ada.Strings,
     Ada.Strings.Fixed,
     Ada.Strings.Maps,
     Ada.Strings.Maps.Constants,
     Ada.Text_Io,
     Ada.Numerics,
     Ada.Numerics.Generic_Elementary_Functions;
use
  Ada.Strings,
    Ada.Strings.Fixed,
    Ada.Strings.Maps,
    Ada.Strings.Maps.Constants,
    Ada.Text_Io,
    Ada.Numerics;
--
-- Programming Notes:
--
-- package Ada.Strings defines the following types:
-- alignment, truncation, membership, direction, trim_end
--
-- package Ada.Strings.Fixed provides the following procedures:
-- move, index, count, find_token, translate, replace_slice
-- insert, overwrite, delete, trim, head, tail, * (constructor)
--
-- package Ada.Strings.Maps defines the following types:
-- character_set, character_ranges, character_mapping
-- and it defines the following functions:
-- to_set, to_ranges, and, or, not, xor, =, <=, -, is_in, is_subset,
-- to_sequence, value, to_mapping, to_domain, to_range
--
-- package Ada.Strings.Maps.Constants defines the following
-- constants:
-- control_set, graphic_set, letter_set, lower_set, upper_set,
-- basic_set, decimal_digit_set, hexadecimal_digit_set,
-- alphanumeric_set, special_set, ISO_646_set, lower_case_map,
-- upper_case_map, basic_map
--
-- package Ada.Characters.Handling has the following procedures:
-- is_control, is_graphic, is_letter, is_lower, is_upper,
-- is_basic, is_digit, is_deciaml_digit, is_hexadecimal_digit,
-- is_alphanumeric, is_special, to_lower, to_upper, to_basic,
-- is_ISO_646, to_ISO_646, is_character, is_string, to_character,
-- to_string, to_wide_character, to_wide_string
--

package body Text_Format is

   package Iio is new Integer_Io(Integer);
   use Iio;
   package Lfio is new float_Io(Tf_Float);
   use Lfio;
   package Gef is new
     Ada.Numerics.Generic_Elementary_Functions(Tf_Float);
   use Gef;

   Twopi : constant Tf_Float := 2.0*Pi;
   Pio2 : constant Tf_Float := Pi/2.0;

   function "mod" (Arg1, Arg2 : Tf_Float) return Tf_Float is
   begin
      return (Arg1 - Arg2 * Tf_Float'Floor (Arg1 / Arg2));
   end;

   function Is_Unsigned_Integer(Source : String) return Boolean is
      First : Positive;
      Last : Natural;
      begin
         Find_Token(Source,Decimal_Digit_Set,Inside,First,Last);
         if Last = 0 and First = Source'First then
            return False;
         end if;
         return Index_Non_Blank(Source,Forward) = First and
           Index_Non_Blank(Source,Backward) = Last;
      end Is_Unsigned_Integer;

   function Is_Integer(Source : String) return Boolean is
      First : Positive;
      Last : Natural;
      begin
         Find_Token(Source,Decimal_Digit_Set,Inside,First,Last);
         if Last = 0 and First = Source'First then
            return False;
         end if;
         if Source'First < First then
            if Source(First-1) = '+' or Source(First-1) = '-' then
               return Index_Non_Blank(Source,Forward) = First-1 and
                 Index_Non_Blank(Source,Backward) = Last;
            else
               return Index_Non_Blank(Source,Forward) = First and
                 Index_Non_Blank(Source,Backward) = Last;
            end if;
         else
            return Index_Non_Blank(Source,Backward) = Last;
         end if;
      end Is_integer;

   function Is_Float(Source : String) return Boolean is
      Ptr : Integer;
      Leftside, Rightside : Boolean;
   begin
      Ptr := Index(Source,".");
      if Ptr /= 0 then
         if Ptr = Source'First then
            Leftside := False;
         else
            Leftside := (Is_Integer(Source(Source'First .. Ptr-1)) and
                         Source(Ptr-1) /= ' ') or
              (( Source(Ptr-1) = '+' or Source(Ptr-1) = '-' ) and
               Index_Non_Blank(Source,Forward) = Ptr-1);
         end if;
         if Ptr = Source'Last then
            Rightside := False;
         else
            Rightside := Is_Unsigned_Integer(Source(Ptr+1 .. Source'Last)) and
              Source(Ptr+1) /= ' ';
         end if;
         return
           (Leftside and Rightside) or
           (Leftside and Index_Non_Blank(Source,Backward) = Ptr) or
           (Index_Non_Blank(Source,Forward) = Ptr and Rightside);
      else
         return False;
      end if;
   end Is_Float;

   function Is_Scientific_Notation(Source : String) return Boolean is
      Ptr : Integer;
   begin
      Ptr := Index(Source,"E");
      if Ptr = 0 then
         Ptr := Index(Source,"e");
         if Ptr = 0 then
            return False;
         end if;
      end if;
      if Ptr = 1 then
         return False;
      end if;
      if Source(Ptr-1) = ' ' or Source(Ptr+1) = ' ' then
         return False;
      else
         return
           Is_Float(Source(Source'First .. Ptr-1)) and
           Is_Integer(Source(Ptr+1 .. Source'Last));
      end if;
   end Is_Scientific_Notation;

   function Is_Sexagesimal(Source: in String) return Boolean is
      Ptr1,Ptr2,ptr3 : Integer;
   begin
--
-- There must be one or two colons. Find their locations.
      Ptr1 := Index(Source,":");
      if Ptr1 = 0 then
         return False;
      else
         Ptr2 := Index(Source(Ptr1+1 .. Source'Last),":");
         if Ptr2 /= 0 then
            Ptr3 := Index(Source(Ptr2+1 .. Source'Last),":");
            if Ptr3 /= 0 then
               return False;
            end if;
         end if;
      end if;
      if Ptr2 = 0 then
--
-- If there is one colon, the left side must be an integer. The
-- right side must be an unsigned integer or an unsigned real.
--
         if Is_Integer(Source(Source'First .. Ptr1-1)) and
           (Is_Unsigned_Integer(Source(Ptr1+1 .. Source'Last)) or
            Is_Float(Source(Ptr1+1 .. Source'Last))) then
            return (Source(Ptr1-1) /= ' ' and
                    Source(Ptr1+1) /= ' ' and
                    Source(Ptr1+1) /= '-' and
                    Source(Ptr1+1) /= '+');
         else
            return False;
         end if;
      else
--
-- If there are two colons, the left side must be an integer. The
-- center section must be a unsigned integer with one or more digits.
-- The right side must be an unsigned integer or an unsigned real.
--
         if (Ptr2 - Ptr1) < 2 then
            return False;
         else
            if Is_Integer(Source(Source'First .. Ptr1-1)) and
              Is_Unsigned_Integer(Source(Ptr1+1 .. Ptr2-1)) and
              (Is_Unsigned_Integer(Source(Ptr2+1 .. Source'Last)) or
               Is_Float(Source(Ptr2+1 .. Source'Last))) then
               return (Source(Ptr1-1) /= ' ' and Source(Ptr1+1) /= ' ' and
                       Source(Ptr2-1) /= ' ' and Source(Ptr2+1) /= ' ' and
                       Source(Ptr2+1) /= '-' and Source(Ptr2+1) /= '+');
            else
               return False;
            end if;
         end if;
      end if;
   end Is_Sexagesimal;

   procedure String_To_Integer(From : in String;
                               Item : out Integer) is
      String_Not_Integer_Format : exception;
      L , R, Sign : Integer;

      function Val(X : Character) return Integer is
         Y : constant String := "0123456789";
         Z : String (1 .. 1);
      begin
         Z(1) := X;
         return Index(Y,Z)-1;
      end;

   begin
      if Is_Integer(From) then
         L := Index_Non_Blank(From,Forward);
         R := Index_Non_Blank(From,Backward);
         if From(L) = '-' then
            Sign := (-1);
            L:=L+1;
         elsif From(L) = '+' then
            Sign := 1;
            L:=L+1;
         else
            Sign := 1;
         end if;
         Item:=0;
         for I in L .. R loop
            Item := Item*10 + Val(From(I));
         end loop;
         Item:=Sign*Item;
      else
         raise String_Not_Integer_Format ;
      end if;
   end;

   procedure Integer_To_String(To    : out String;
                               Item  : in integer;
                               Width : in Natural := integer'Width;
                               Fill  : in Boolean := False;
                               Base  : in Natural := 10) is
      Insufficient_Width, Invalid_Base : exception;
      Str_End : constant Integer := 128;
      Sign, Str_Ptr, Digit_Ptr, Local_Item, Rep_Length : Integer;
      Proto : String(1 .. Str_End);
      Master_Digits : constant String := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   begin
      Local_Item := Item;
      if Local_Item < 0 then
         Sign := -1;
         Local_Item := -Local_Item;
      else
         Sign := 1;
      end if;
      if Base > 36 or Base < 2 then
        raise Invalid_Base;
      end if;
      Rep_Length:=Integer(Tf_Float'Ceiling(Log(Tf_Float(Local_Item))/
                      Log(Tf_Float(Base))));
      if Sign < 0 then
         Rep_Length:=Rep_Length+1;
      end if;
      if To'Length < Rep_Length or Width < Rep_Length then
         raise Insufficient_Width;
      end if;
      Str_Ptr := Proto'Length;
      if Fill then
         Proto := ((Str_End - Width) * ' ') & (Width * '0');
      else
         Proto := Str_Ptr * ' ';
      end if;
      while Local_Item > 0 loop
         Digit_Ptr := 1 + (Local_Item rem Base);
         Local_Item := Local_Item/Base;
         Proto(Str_Ptr) := Master_Digits(Digit_Ptr);
         Str_Ptr := Str_Ptr-1;
      end loop;
      if Sign = -1 then
         if Fill then
            Proto(Str_End - Width + 1) := '-';
         else
            Proto(Str_Ptr) := '-';
            Str_Ptr := Str_Ptr-1;
         end if;
      end if;
      To(To'First .. To'Last):=Proto((Str_End+1 - To'Length) .. Str_End);
   end;

   procedure String_To_Float(Source : in String;
                             Value : out Tf_Float) is

      String_Not_Float_Format : exception;
      Decimal_Ptr,Start_Ptr,End_Ptr : Integer;
      Sign,Left_Value,Right_Value : Tf_Float;

      function Val(X : Character) return Tf_Float is
         Y : constant String := "0123456789";
         Z : String (1 .. 1);
      begin
         Z(1) := X;
         return Tf_Float(Index(Y,Z)-1);
      end;

   begin
      if Is_Float(Source) then
         Decimal_Ptr := Index(Source,".",Forward);
         Start_Ptr := Index_Non_Blank(Source,Forward);
         End_Ptr := Index_Non_Blank(Source,Backward);
         if Source(Start_Ptr) = '-' then
            Sign:=-1.0;
            Start_Ptr:=Start_Ptr+1;
         elsif Source(Start_Ptr) = '+' then
            Sign:=1.0;
            Start_Ptr:=Start_Ptr+1;
         else
            Sign:=1.0;
         end if;
         Right_Value:=0.0;
         for I in reverse Decimal_Ptr+1 .. End_Ptr loop
            Right_Value := 0.1 * (Right_Value + Val(Source(I)));
         end loop;
         Left_Value:=0.0;
         for I in Start_Ptr .. Decimal_Ptr-1 loop
            Left_Value := Left_value*10.0 + Val(Source(I));
         end loop;
         Value:=Left_Value+Right_Value;
         if Value /= 0.0 then
            Value:=Sign*Value;
         end if;
      else
         raise String_Not_Float_Format;
      end if;
   end;

   procedure Float_To_String(To           : out String;
                             Item         : in Tf_Float;
                             Left_Width   : in Natural := Tf_Float'Width;
                             Right_Width  : in Natural := Tf_Float'Width;
                             Left_Fill    : in Boolean := False;
                             Right_Fill   : in Boolean := False;
                             Base         : in Natural := 10) is
      Insufficient_Left_Width, Invalid_Base : exception;
      Str_End : constant Integer := 128;
      Local_Item, F_Item, Sign : Tf_Float;
      Integer_Item, Str_Ptr, Digit_Ptr, Rep_Length, Lo, Hi,
        Max_digits : Integer;
      Proto : String(1 .. Str_End);
      Master_Digits : constant String := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   begin
--
-- If the value is negative, make it positive but remember the sign
-- in either case.
--
      Local_Item := Item;
      if Local_Item < 0.0 then
         Sign := -1.0;
         Local_Item := -Local_Item;
      else
         Sign := 1.0;
      end if;
--
-- Raise an exception if the base is not representable with 36 different
-- characters.
--
      if Base > 36 or Base < 2 then
        raise Invalid_Base;
      end if;
--
-- Determine the number of digits required to represent the integer
-- part of the number, including the negative sign, if required.
--
      Rep_Length:=Integer(Tf_Float'Ceiling(Log(Local_Item)/Log(Tf_Float(Base))));
      if Rep_Length < 1 then
         Rep_Length := 1;
      end if;
      if Sign < 0.0 then
         Rep_Length:=Rep_Length+1;
      end if;
--
-- Verify that the space allotted for the integer part of the
-- number is large enough to contain the digits, sign, and radix point.
--
      if To'Length < Rep_Length+1 or Left_Width < Rep_Length then
         raise Insufficient_Left_Width;
      end if;
--
-- Clear the prototype string and put the radix point in its
-- proper place.
--
      Str_Ptr := Proto'Length;
      Proto := Str_Ptr * ' ';
      Proto(Str_Ptr - Right_Width) := '.';
--
-- Place the digits of the integer part into the prototype string.
--
      Str_Ptr := Str_Ptr - Right_Width - 1;
      Integer_Item := Integer(Tf_Float'Floor(Local_Item));
      while Integer_Item > 0 loop
         Digit_Ptr := 1 + (Integer_Item rem Base);
         Integer_Item := Integer_Item/Base;
         Proto(Str_Ptr) := Master_Digits(Digit_Ptr);
         Str_Ptr := Str_Ptr-1;
      end loop;
--
-- Fill the left side if requested and put any required negative sign
-- on the left end of the fill.
--
      if Left_Fill then
         Lo := Proto'Length - (Left_Width + Right_Width);
         Hi := Str_Ptr;
         if Sign < 0.0 then
            Proto(Lo) := '-';
            Lo:=Lo+1;
         end if;
         for I in Lo .. Hi loop
            Proto(I) := '0';
         end loop;
      else
         if Sign < 0.0 then
            Proto(Str_Ptr):='-';
         end if;
      end if;
--
-- Cosmetic alteration. If the left side is zero,
-- put in a leading zero rather than leave a bare radix point.
--
      Lo := Proto'Length-Right_Width-1;
      if Proto(Lo) = ' ' then
         Proto(Lo) := '0';
      end if;
      if Proto(Lo) = '-' then
         Proto(Lo-1 .. Lo) := "-0";
      end if;
--
-- Place the digits of the fractional part into the prototype string.
-- Calculate the maximum number of significant digits possible in the
-- fractional part.
--
      Max_Digits := Tf_Float'Width - 5;
      Rep_Length := Integer(Tf_Float'Ceiling(Log(Local_Item)/Log(Tf_Float(Base))));
      if Rep_Length < 0 then
         Rep_Length := 0;
      end if;
      Max_Digits := Max_Digits - Rep_Length;
      if Max_Digits > Right_Width then
         Max_Digits := Right_Width;
      end if;
--
-- Put the fractional digits to the right of the radix point.
--
      Str_Ptr:=Proto'Length - Right_Width + 1;
      F_Item := Local_Item - Tf_Float'Floor(Local_Item);
      for I in 1 .. Max_Digits loop
         F_Item:=F_Item*Tf_Float(Base);
         Digit_Ptr := Integer(Tf_Float'Floor(F_Item));
         F_Item:=F_Item-Tf_Float(Digit_Ptr);
         Digit_Ptr := Digit_Ptr+1;
         Proto(Str_Ptr):= Master_Digits(Digit_Ptr);
         Str_Ptr := Str_Ptr+1;
         if F_Item = 0.0 then
            exit;
         end if;
      end loop;
--
-- Fill the remainder of the prototype string if requested.
--
      if Right_Fill then
         for I in Str_Ptr .. Proto'Length loop
            Proto(I):='0';
         end loop;
      end if;
      To(To'First .. To'Last):=Proto((Str_End+1 - To'Length) .. Str_End);
   end;



   procedure Radian_To_Hms_String(Radian : Tf_Float;
                                  Separator : Character;
                                  Hms_String : out String) is
      Short_String : exception;
      Hour_Angle, Lradian : Tf_Float;
      Hour, Minute, Second, Fraction, Slength, Flength, Ptr : Integer;
   begin
      Lradian := Radian;
      Lradian := Lradian mod Twopi;
      Hour_Angle := ( Lradian * 12.0 ) / Pi;
      Hour := Integer(Tf_Float'Floor(Hour_Angle));
      Minute := Integer(Tf_Float'Floor((Hour_Angle - Tf_Float(Hour))*60.0));
      Second := Integer(Tf_Float'Floor((Hour_Angle - Tf_Float(Hour)
                     - Tf_Float(Minute)/60.0) * 3600.0));
      Fraction := Integer(Tf_Float'Floor((Hour_Angle - Tf_Float(Hour)
                       - Tf_Float(Minute)/60.0
                       - Tf_Float(Second)/3600.0) * 3600000.0));
      Slength := Hms_String'Length;
      if Slength >= 8 then
         if Integer'Image(Hour)'Length = 2 then
            Hms_String(1 .. 3) := '0' & Integer'Image(Hour)(2)
              & separator;
         elsif Integer'Image(Hour)'Length = 3 then
            Hms_String(1 .. 3) := Integer'Image(Hour)(2 .. 3) & separator;
         end if;
         if Integer'Image(Minute)'Length = 2 then
            Hms_String(4 .. 6) := '0' & Integer'Image(Minute)(2)
              & separator;
         elsif Integer'Image(Minute)'Length = 3 then
            Hms_String(4 .. 6) := Integer'Image(Minute)(2 .. 3) & separator;
         end if;
         if Integer'Image(Second)'Length = 2 then
            Hms_String(7 .. 8) := '0' & Integer'Image(Second)(2) ;
         elsif Integer'Image(Second)'Length = 3 then
            Hms_String(7 .. 8) := Integer'Image(Second)(2 .. 3) ;
         end if;
         if Slength = 9 then
            Hms_String(9):=' ';
         elsif Slength > 9 then
            Hms_String(9):='.';
            for I in 10 .. Slength loop
               Hms_String(I):=' ';
            end loop;
            --
            -- This pointer sets the maximum significant length of the
            -- resultant Hms_string
            --
            Ptr:=12;
            Flength:=Integer'Image(Fraction)'Length;
            for I in reverse 2 .. Flength loop
               if Ptr <= Slength then
                  Hms_String(Ptr):=Integer'Image(Fraction)(I);
               end if;
               Ptr:=Ptr-1;
            end loop;
            if Ptr >= 10 then
               for I in 10 .. Ptr loop
                  if I <= Slength then
                     Hms_String(I):='0';
                  end if;
               end loop;
            end if;
         end if;
      else
         raise Short_String;
      end if;
   end Radian_To_Hms_String;

   procedure Hms_String_To_Radian(Hms_String : in String;
                                  Radian : out Tf_Float) is

      Invalid_Sexagesimal_Format, Unrecognized_Second_Format : exception;
      Str : String(1 .. 80);
      F1, F2, F3 : String(1 .. 8);
      Ptr1, Ptr2, Ptr3, Hour, Minute, Dummy : Integer;
      Second : Tf_Float;

   begin
      if Is_Sexagesimal(Hms_String) then
         Str := "                                        " &
           "                                        ";
         Ptr1 := Index_Non_Blank(Hms_String,Backward);
         Str(1 .. Ptr1) := Hms_String(1 .. ptr1);
         Trim(Str,Both);
         Ptr1 := Index(Str,":",forward);
         Ptr2 := Index(Str(Ptr1 + 1 .. Str'Last),":",Forward);
         F1:=Str(1 .. Ptr1 - 1) & (9-Ptr1) * " ";
         if Ptr2 /= 0 then
            F2 := Str( (Ptr1 + 1) .. (Ptr2 - 1) ) & (9 - Ptr2 + Ptr1) * " ";
            Ptr3 := Index_Non_Blank(Str,Backward);
            F3 := Str(Ptr2+1 .. Ptr3) & (8 - Ptr3 + Ptr2) * " ";
         else
            Ptr2 := Index_Non_Blank(Str,Backward);
            F2 := Str(Ptr1+1 .. Ptr2) & (8 - Ptr2 + Ptr1) * " ";
            F3 := "        ";
         end if;
         String_To_Integer(F1,Hour);
         String_To_Integer(F2,Minute);
         if F3 /= "        " then
            if Is_Integer(F3) then
               String_To_Integer(F3,Dummy);
               Second := Tf_Float(Dummy);
            elsif Is_Float(F3) then
               String_To_Float(F3,Second);
            else
               raise Unrecognized_Second_Format;
            end if;
         else
            Second := 0.0;
         end if;
         if F1(1 .. 1) = "-" then
            Radian := (Tf_Float(Hour) -
                       (Tf_Float(Minute)/60.0 +
                        Second/3600.0))*Pi/12.0;
         else
            Radian := (Tf_Float(Hour) +
                       Tf_Float(Minute)/60.0 +
                       Second/3600.0)*Pi/12.0;
         end if;
      else
         raise Invalid_Sexagesimal_Format;
      end if;
    end Hms_String_To_radian;


   procedure Radian_To_Dms_String(Radian : Tf_Float;
                                  Separator : Character;
                                  Include_Plus : Boolean;
                                  Dms_String : out String) is
      String_Too_Short, Out_Of_Range : exception;
      Deg_Angle, Lradian : Tf_Float;
      Deg, Minute, Second, Fraction, Slength, Flength, Ptr, Sign : Integer;
   begin
      if Radian < Pio2 and Radian > -Pio2 then
         Lradian := Radian;
         if Lradian < 0.0 then
            Sign:=-1;
            Lradian:=-Lradian;
         else
            Sign:=1;
         end if;
         Deg_Angle := ( Lradian * 180.0 ) / Pi ;
         Deg := Integer(Tf_Float'Floor(Deg_Angle));
         Minute := Integer(Tf_Float'Floor((Deg_Angle - Tf_Float(Deg))*60.0));
         Second := Integer(Tf_Float'Floor((Deg_Angle - Tf_Float(Deg)
                        - Tf_Float(Minute)/60.0) * 3600.0));
         Fraction := Integer(Tf_Float'floor((Deg_Angle - Tf_Float(Deg)
                          - Tf_Float(Minute)/60.0
                          - Tf_Float(Second)/3600.0)* 360000.0));
         Slength := Dms_String'Length;
         if Slength >= 9 then
            if Sign < 0 then
               Dms_String(1):='-';
            else
               if Include_Plus then
                  Dms_String(1):='+';
               else
                  Dms_String(1):=' ';
               end if;
            end if;
            if Integer'Image(Deg)'Length = 2 then
               Dms_String(2 .. 4) := '0' & Integer'Image(Deg)(2) & separator;
            elsif Integer'Image(Deg)'Length = 3 then
               Dms_String(2 .. 4) := Integer'Image(Deg)(2 .. 3) & separator;
            end if;
            if Integer'Image(Minute)'Length = 2 then
               Dms_String(5 .. 7) := '0' & Integer'Image(Minute)(2) & separator;
            elsif Integer'Image(Minute)'Length = 3 then
               Dms_String(5 .. 7) := Integer'Image(Minute)(2 .. 3) & separator;
            end if;
            if Integer'Image(Second)'Length = 2 then
               Dms_String(8 .. 9) := '0' & Integer'Image(Second)(2) ;
            elsif Integer'Image(Second)'Length = 3 then
               Dms_String(8 .. 9) := Integer'Image(Second)(2 .. 3) ;
            end if;
            if Slength = 10 then
               Dms_String(10):=' ';
            elsif Slength > 10 then
               Dms_String(10):='.';
               for I in 11 .. Slength loop
                  Dms_String(I):=' ';
               end loop;
               --
               -- This pointer sets the maximum significant length of the
               -- resultant Dms_string
               --
               Ptr:=12;
               Flength:=Integer'Image(Fraction)'Length;
               for I in reverse 2 .. Flength loop
                  if Ptr <= Slength then
                     Dms_String(Ptr):=Integer'Image(Fraction)(I);
                  end if;
                  Ptr:=Ptr-1;
               end loop;
               if Ptr >= 11 then
                  for I in 11 .. Ptr loop
                     if I <= Slength then
                        Dms_String(I):='0';
                     end if;
                  end loop;
               end if;
            end if;
         else
            raise String_Too_Short;
         end if;
      else
         raise Out_Of_Range;
      end if;
   end Radian_To_Dms_String;

   procedure Dms_String_To_Radian(Dms_String : in String;
                                  Radian : out Tf_Float) is

      Invalid_Sexagesimal_Format, Unrecognized_Second_Format : exception;
      Str : String(1 .. 80);
      F1, F2, F3 : String(1 .. 8);
      Ptr1, Ptr2, Ptr3, Degree, Minute, Dummy : Integer;
      Second : Tf_Float;

   begin
      if Is_Sexagesimal(Dms_String) then
         Str := "                                        " &
                "                                        ";
         Ptr1 := Index_Non_Blank(Dms_String,Backward);
         Str(1 .. Ptr1) := Dms_String(1 .. ptr1);
         Trim(Str,Both);
         Ptr1 := Index(Str,":",forward);
         Ptr2 := Index(Str(Ptr1 + 1 .. Str'Last),":",Forward);
         F1:=Str(1 .. Ptr1 - 1) & (9-Ptr1) * " ";
         if Ptr2 /= 0 then
            F2 := Str((Ptr1 + 1) .. (Ptr2 - 1)) & (9 - Ptr2 + Ptr1) * " ";
            Ptr3 := Index_Non_Blank(Str,Backward);
            F3 := Str(Ptr2+1 .. Ptr3) & (8 - Ptr3 + Ptr2) * " ";
         else
            Ptr2 := Index_Non_Blank(Str,Backward);
            F2 := Str(Ptr1+1 .. Ptr2) & (8 - Ptr2 + Ptr1) * " ";
            F3 := "        ";
         end if;
         String_To_Integer(F1,Degree);
         String_To_Integer(F2,Minute);
         if F3 /= "        " then
            if Is_Integer(F3) then
               String_To_Integer(F3,Dummy);
               Second := Tf_Float(Dummy);
            elsif Is_Float(F3) then
               String_To_Float(F3,Second);
            else
               raise Unrecognized_Second_Format;
            end if;
         else
            Second := 0.0;
         end if;
         if F1(1 .. 1) = "-" then
            Radian := (Tf_Float(Degree) -
                       (Tf_Float(Minute)/60.0 +
                        Second/3600.0))*Pi/180.0;
         else
            Radian := (Tf_Float(Degree) +
                       Tf_Float(Minute)/60.0 +
                       Second/3600.0)*Pi/180.0;
         end if;
      else
         raise Invalid_Sexagesimal_Format;
      end if;
   end Dms_String_To_Radian;

end Text_Format;
