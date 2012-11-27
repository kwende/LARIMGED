-- This file is part of mged_data_phaser.
-- Foobar is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- Foobar is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

-- Copyright 2012 Bruce W. Koehn

with
Ada.Calendar,
     Ada.Strings,
     Ada.Strings.Maps,
     Ada.Strings.Fixed;
use
  Ada.Calendar,
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
   Hr, Mn : Integer;
   Sc : Day_Duration;
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
   end Justify_Text;

   procedure Error_Msg (Procedure_Name : in String;
                        Message        : in String;
                        Dest           : in File_Type := Standard_Error) is
   begin
      Split ((Clock + Day_Duration (7 * 3600)), Yr, Mo, Dy, Sc);
      Hr := Integer (Sc) / 3600;
      Mn := (Integer (Sc) - (3600 * Hr)) / 60;
      Sc := Day_Duration (Integer (Sc) - (3600 * Hr) - (60 * Mn));
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
      Split ((Clock + Day_Duration (7 * 3600)), Yr, Mo, Dy, Sc);
      Hr := Integer (Sc) / 3600;
      Mn := (Integer (Sc) - (3600 * Hr)) / 60;
      Sc := Day_Duration (Integer (Sc) - (3600 * Hr) - (60 * Mn));
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
