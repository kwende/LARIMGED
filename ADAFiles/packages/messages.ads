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
--  Modified 2012-11-25
--  1. Changed the date string to UT for any location. This change requires
--  Ada 2005 compiler for the newest calendar packages. (Old behavior was
--  correct only for Mountain Standard Time.)
--  2. Fixed a bug in the message formatter.  The message is now followed by
--  a line feed.
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
