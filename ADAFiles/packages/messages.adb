with
Ada.Calendar,
     Ada.Calendar.Time_Zones,
     Ada.Calendar.Formatting,
     Ada.Strings,
     Ada.Strings.Maps,
     Ada.Strings.Fixed;
use
  Ada.Calendar,
    Ada.Calendar.Time_Zones,
    Ada.Calendar.Formatting,
    Ada.Strings,
    Ada.Strings.Maps,
    Ada.Strings.Fixed;

package body Messages is

   package Iio is new Integer_Io (Integer); use Iio;

   type Month_Name_Array is array (1 .. 12) of String (1 .. 3);
   Month_Name : constant Month_Name_Array :=
                  ( 1 => "Jan",  2 => "Feb",  3 => "Mar",  4 => "Apr",
                    5 => "May",  6 => "Jun",  7 => "Jul",  8 => "Aug",
                    9 => "Sep", 10 => "Oct", 11 => "Nov", 12 => "Dec");
   Yr : Year_Number;
   Mo : Month_Number;
   Dy : Day_Number;
   Hr : Hour_Number;
   Mn : Minute_Number;
   Sc : Second_Number;
   Ss : Second_Duration;
   Tz : Time_Offset;
   S : String (1 .. 2);

   --  This local procedure breaks the "source" string into lines at
   --  word boundaries.  The maximum line length is specifed by "width".
   --  The text will be written to the "Dest" file (which should be
   --  open).
   procedure Justify_Text
     (Source : in String;
      Width  : in Positive;
      Dest   : in File_Type) is
      Delimiter                      : Character_Set;
      First, Last, Tail, String_Size : Integer;
      Done                           : Boolean;
   begin
      Delimiter := To_Set (" ");
      Done := False;
      Last := Source'First - 1;
      Tail := Source'Last;
      String_Size := 0;
      --  Find each token in the source string
      while not Done loop
         Find_Token (Source (Last + 1 .. Tail), Delimiter, Outside,
                     First, Last);
         if Last = 0 then
            Done := True;
         else
            --  Write the token as long as the length of the
            --  output line will be less than "width". If it
            --  is greater than width, go to a new line and
            --  then write the token.
            String_Size := String_Size + (Last - First + 2);
            if String_Size - 1 > Width then
               New_Line (Dest);
               Put (Dest, Source (First .. Last) & " ");
               String_Size := (Last - First + 2);
            else
               Put (Dest, Source (First .. Last) & " ");
            end if;
         end if;
      end loop;
      New_Line (Dest);
   end Justify_Text;

   procedure Error_Msg (Procedure_Name : in String;
                        Message        : in String;
                        Dest           : in File_Type := Standard_Error) is
   begin
      -- Tz := Utc_Time_Offset (Clock);
      Tz := Time_Offset(0);  -- For UT.
      Split (Clock, Yr, Mo, Dy, Hr, Mn, Sc, Ss, Tz);
      Put (Dest, "***ERROR***  ");
      Put (Dest, Integer (Yr), 4);
      Put (Dest, " " & Month_Name (Integer (Mo)) & " ");
      Put (S, Integer (Dy));
      if Dy < 10 then
         S (1 .. 1) := "0";
      end if;
      Put (Dest, S & " ");
      Put (S, Hr);
      if Hr < 10 then
         S (1 .. 1) := "0";
      end if;
      Put (Dest, S & ":");
      Put (S, Mn);
      if Mn < 10 then
         S (1 .. 1) := "0";
      end if;
      Put (Dest, S & ":");
      Put (S, Integer (Sc));
      if Integer (Sc) < 10 then
         S (1 .. 1) := "0";
      end if;
      Put_Line (Dest, S & " UT (" & Procedure_Name & ") ");
      Justify_Text (Trim (Message, Both), 60, Dest);
   end Error_Msg;

   procedure Status_Msg (Procedure_Name : in String;
                         Message        : in String;
                         Dest           : in File_Type := Standard_Output) is
   begin
      -- Tz := UTC_Time_Offset(Clock);
      Tz := Time_Offset(0); -- for UT
      Split (Clock, Yr, Mo, Dy, Hr, Mn, Sc, Ss, Tz);
      Put (Dest, "***STATUS*** ");
      Put (Dest, Integer (Yr), 4);
      Put (Dest, " " & Month_Name (Integer (Mo)) & " ");
      Put (S, Integer (Dy));
      if Dy < 10 then
         S (1 .. 1) := "0";
      end if;
      Put (Dest, S & " ");
      Put (S, Hr);
      if Hr < 10 then
         S (1 .. 1) := "0";
      end if;
      Put (Dest, S & ":");
      Put (S, Mn);
      if Mn < 10 then
         S (1 .. 1) := "0";
      end if;
      Put (Dest, S & ":");
      Put (S, Integer (Sc));
      if Integer (Sc) < 10 then
         S (1 .. 1) := "0";
      end if;
      Put_Line (Dest, S & " UT (" & Procedure_Name & ") ");
      Justify_Text (Trim (Message, Both), 60, Dest);
   end Status_Msg;

end Messages;
