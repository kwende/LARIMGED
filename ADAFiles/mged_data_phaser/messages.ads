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

--  <description>
--  This package provides two procedures for writing informational
--  messages. Both procedures requires two input
--  parameters: 1) the procedure name is intended to be the name of
--  the calling procedure although the programmer can put any string
--  in this field, 2) the message itself.  The procedure name can
--  supply limited traceback information and sometimes helps with
--  debugging.
--
--  An optional destination Argument allows the programmer to send the
--  message to any file. However, error messages default to "Standard_Error"
--  and status messages default to "Standard_Output".
--
--  The output format provides a ***ERROR*** or ***STATUS** banner
--  followed by the date and time. It then prints the calling procedure
--  name in parenthese. Finally the message appears on a new line or lines.
--
--  The Message string is formatted to print in lines of 60 characters
--  or less. This length is hard-coded into the messages.adb file.
--  </description>
--
with Ada.Text_Io;
use Ada.Text_Io;

package Messages is

   procedure Error_Msg (Procedure_Name : in String;
                        Message        : in String;
                        Dest           : in File_Type := Standard_Error);
   --  <summary>Print an error message.</summary>
   --  <parameter name="Procedure_Name">A string that should name the calling procedure.</parameter>
   --  <parameter name="Message">A string containing the error message.</parameter>
   --  <parameter name="Dest">The file to where the error message is written.</parameter>
   --  <exception>No exceptions</exception>

   procedure Status_Msg (Procedure_Name : in String;
                         Message        : in String;
                         Dest           : in File_Type := Standard_Output);
   --  <summary>Print a status message.</summary>
   --  <parameter name="Procedure_Name">A string that should name the calling procedure.</parameter>
   --  <parameter name="Message">A string containing the status message.</parameter>
   --  <parameter name="Dest">The file to where the status message is written.</parameter>
   --  <exception>No exceptions</exception>

end Messages;
