generic

   type Tf_Float is digits <>;

package Text_Format is

----------------------------------------------------------------------
   --
   --  This package is designed to convert numbers to/from
   --  strings.  Although the Ada.Text_Io package does the
   --  same thing, it does not handle unusual format such as
   --  sexagesimal, and it does not put in leading zeros.
   --  These routines seem easier to use in many cases.
   --
----------------------------------------------------------------------
--
-- This function returns true when the string contains only
-- consecutive digits.
--
   function Is_Unsigned_Integer(Source : in String) return Boolean;
--
----------------------------------------------------------------------
--
--  This function returns true when the string contains only
--  an unsigned Integer possibly preceded immediately by a
--  sign (+ / -).
--
   function Is_Integer(Source : in String) return Boolean;
--
----------------------------------------------------------------------
--
--  This function returns true when the string contains only a
--  period immediately followed by an unsigned integer or
--  immediately-- preceeded by a signed integer or both. It
--  will also return true when the period is followed by an
--  unsigned integer and the period is immediately preceeded by
--  a sign alone.
--
   function Is_Float(Source : in String) return Boolean;
--
----------------------------------------------------------------------
--
-- This function returns true when the string contains only a float
-- followed immediately by an 'E' character (upper or lower case)
-- which in turn must be followed immediately by an integer.
--
   function Is_Scientific_Notation(Source : in String) return Boolean;
--
----------------------------------------------------------------------
--
-- This function returns true when the string contains only a number
-- in sexagesimal notation. In astronomy, this notation can be realized
-- in the following ways: (dd is a pair of digits, one of which
-- is optional, d is a digit, s is an optional sign, . is a period,
-- : is a delimiter (only a colon is valid in this routine), ...
-- indicates the preceeding character repeated an arbitrary number of
-- times.)
--
-- sdd:dd:dd.d...
-- sdd:dd:dd
-- sdd:dd.d...
-- sdd:dd
--
-- No imbedded spaces are allowed.
--
-- Further simplifications are sometimes used but the format then
-- degenerates into float or integer format so this routine will
-- only consider the preceeding formats as valid sexagesimal notation.
--
   function Is_Sexagesimal (Source : in String) return Boolean;
--
----------------------------------------------------------------------
--
-- This procedure is similar to the text_io.integer_io procedure
--
--   procedure Get(From : in  String;
--                 Item : out Num;
--                 Last : out Positive);
--
   procedure String_To_Integer(From : in String;
                               Item : out Integer);
--
-- This procedure is similar the the text_io.integer_io procedure
--
--   procedure Put(To   : out String;
--                 Item : in Num;
--                 Base : in Number_Base := Default_Base);
--
-- However, the Ada version of 'Put' does not allow the programmer
-- to specify that leading zeros should
-- be present. The following procedure rectifies these problems.
--
-- Integer 'Item' is converted to its equivalent string
-- representation. The numeric characters are  right justified in
-- the 'To' string. The integer is represented in base 'base'
-- which can be any integer between 2 and 36. An 'Invalid_Base'
-- exception is raised if the base is out of range. The 'width'
-- is the maximum number of characters used to represent the number.
-- If the number is too large to be represented in 'width'
-- a characters, an 'Insufficient_Width' exception is raised.
-- Normally, the characters to the right of the number characters
-- are filled with blanks but, if 'Fill' is true, the characters
-- will be filled with zeros. Only 'Width' characters will be
-- filled. If the string is longer than 'Width', the remaining
-- characters will remain blank.
--
   procedure Integer_To_String(To    : out String;
                               Item  : in integer;
                               Width : in Natural := Integer'Width;
                               Fill  : in Boolean := False;
                               Base  : in Natural := 10);
--
----------------------------------------------------------------------
--
   procedure String_To_Float(Source : in String;
                             Value : out Tf_Float);
--
----------------------------------------------------------------------
--
   procedure Float_To_String(To           : out String;
                             Item         : in Tf_Float;
                             Left_Width   : in Natural := Tf_Float'Width;
                             Right_Width  : in Natural := Tf_Float'Width;
                             Left_Fill    : in Boolean := False;
                             Right_Fill   : in Boolean := False;
                             Base         : in Natural := 10);
--
--
----------------------------------------------------------------------
--
--  This procedure converts a real number representing an
--  angle in radians, to a sexagesimal string representing
--  the same angle in "hours". The character "Separator" is
--  inserted
--  between hours and minutes, and between minutes and seconds.
--  Normally the separator is a blank character or a colon.
--
   procedure Radian_To_Hms_String(Radian : in Tf_Float;
                                  Separator : in Character;
                                  Hms_String : out String);
--
----------------------------------------------------------------------
--
--  This procedure converts a string in sexagesimal format to
--  a real number representing the same angle in radians.  The
--  units of the sexagesimal string are assumed to be "Hours".
--
   procedure Hms_String_To_Radian(Hms_String : in String;
                                  Radian : out Tf_Float);
--
----------------------------------------------------------------------
--
--
--  This procedure converts a real number representing an
--  angle in radians, to a sexagesimal string representing
--  the same angle in "degrees". The character "Separator" is
--  inserted
--  between degrees and minutes, and between minutes and seconds.
--  Normally the separator is a blank character or a colon.
--
   procedure Radian_To_Dms_String (Radian : in Tf_Float;
                                  Separator : in Character;
                                  Include_Plus : in Boolean;
                                  Dms_String : out String);
--
----------------------------------------------------------------------
--
--  This procedure converts a string in sexagesimal format to
--  a real number representing the same angle in radians.  The
--  units of the sexagesimal string are assumed to be "degrees".
--
   procedure Dms_String_To_Radian(Dms_String : in String;
                                  Radian : out Tf_Float);
--
----------------------------------------------------------------------

end Text_Format;
