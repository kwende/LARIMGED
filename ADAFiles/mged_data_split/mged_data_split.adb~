--  <description>
--  This procedure breaks a single data file containing TrES data into
--  multiple data files.  Normally, the data will come from
--  http://asteroid.lowell.edu/LARI/mged.html
--  Each of the new files contains TrES data from
--  a single day. Some tools, notably MPO Canopus, prefer to have data
--  files with all the data from the same date.
--
--  The input file should be formatted in an ASCII table with three columns:
--  1) Julian Date, 2) Magnitude, 3) Magnitude Uncertainty
--  The Julian Date must be in the first position so that the procedure will
--  be able to create new files as appropriate.  Each line is copied, verbatum,
--  into the output file.
--
--  The procedure requires two input arguments.  The first is the name of the
--  source data file.  The second is a prototype name for the output.  All
--  the output names are based on the prototype name.  In general, if the
--  prototype name is "base.ext", the output file names will be
--  base_index.ext".  The index will be formed from the last four integer
--  digits of the Julian date. Missiing base or ext parts of the prototype
--  name will be replaced by a default output filename, "data.txt".
--  </description>

with
Ada.Text_IO,
     Ada.Command_Line,
     Ada.Strings,
     Ada.Strings.Fixed,
     Ada.Strings.Maps,
     Ada.Directories,
     Messages;
use
  Ada.Text_IO,
    Ada.Command_Line,
    Ada.Strings,
    Ada.Strings.Fixed,
    Ada.Strings.Maps,
    Ada.Directories,
    Messages;

procedure Mged_Data_Split is
   package Lfio is new Float_Io (Long_Float); use Lfio;
   package Iio is new Integer_Io (Integer); use Iio;
   User_Error       : exception;
   Src, Dst              : File_Type;
   Buffer, New_File_Name           : String (1 .. 512);
   Ext, Bas, Pat, Jd_Ndx_Str : String (1 .. 128);
   Line_Count_Str, File_Count_Str : String(1 .. 16);
   Tail, Current_Jd, Jd_Id, Line_Count, File_Count,
   First, Last, Fini, Jd_Ndx : Natural;
   Jd : Long_Float;
   Delimiter : Character_Set;
begin
   --
   --  Verify the required command line arguments are present.
   --
   if Argument_Count /= 2 then
      Error_Msg ("mged_data_split",
                 "This procedure requires exactly two command line " &
                   "arguments. Two arguments were not found. The first " &
                   "argument is the name of the file containing the " &
                   "data. The second argument is the prototype file " &
                   "name of the output files.");
      raise User_Error;
   end if;
   --
   --  Verify the command lines are not empty
   --
   if Trim (Argument (1), Both) = "" then
      Error_Msg ("mged_data_split",
                 "The input file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty input file name.");
      raise User_Error;
   end if;
   if Trim (Argument (2), Both) = "" then
      Error_Msg ("mged_data_split",
                 "The output prototype file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty output prototype file name.");
      raise User_Error;
   end if;
   --
   --  Verify that the specified source file is present and open it.
   --
   begin
      Open (Src, In_File, Argument (1));
   exception when others =>
         Error_Msg ("mged_data_split",
                    "The procedure is unable to open the input data " &
                      "file. This error ususally occurs if the data " &
                      "file name is misspelled or if the data file " &
                      "does not exist.");
         raise User_Error;
   end;
   --
   --  Loop through all the lines of the source file. Each time a new
   --  date is found, create a new output file and copy all the data
   --  with matching dates into that file.
   --
   Current_Jd := 0;
   Delimiter := To_Set (" ,");
   --
   --  Loop through each line of the input file.
   --
   Line_Count := 0;
   File_Count := 0;
   while not End_Of_File (Src) loop
      Get_Line (Src, Buffer, Tail);
      Line_Count := Line_Count + 1;
      Find_Token (Buffer (Buffer'First .. Tail),
                  Delimiter, Outside, First, Last);
      Get (Buffer (First .. Last), Jd, Fini);
      Jd_Id := Natural (Long_Float'Floor (Jd));
      Jd_Ndx := Jd_Id mod 10000;
      --
      --  Is the current data part of the same day.
      --
      if Current_Jd /= Jd_Id then
         --
         --  If a different day, create a new file and
         --  close the old output file if it was open.
         --
         if Current_Jd > 0 then
            Close (Dst);
         end if;
         --
         --  Create the new file name.
         --
         File_Count := File_Count + 1;
         Put (Jd_Ndx_Str, Jd_Ndx);
         Move(Containing_Directory(Argument(2)),Pat);
         Move (Extension (Argument (2)), Ext);
         if Trim (Ext, Both) = "" then
            Move ("txt", Ext);
         end if;
         Move (Base_Name (Argument (2)), Bas);
         if Trim (Bas, Both) = "" then
            Move ("data", Bas);
         end if;
         Move (Trim (Pat, Both) & "\" &
                 Trim (Bas, Both) & "_" &
                 Trim (Jd_Ndx_Str, Both) & "." &
                 Trim (Ext, Both), New_File_Name);
         -- Status_Msg ("mged_data_split",
         --             "Creating file " & Trim(New_File_Name,Both));
         --
         --  Create the new file
         --
         begin
            Create (Dst, Out_File, Trim (New_File_Name, Both));
         exception
            when others =>
               Error_Msg ("mged_data_split",
                          "The procedure filed to create a new file named " &
                            Trim (New_File_Name, Both) & ". This error " &
                            "often occurs when the user does not have " &
                            "write privledges in the selected directory.");
               raise User_Error;
         end;
         --
         --  Write the first line into the new file
         --
         Put_Line (Dst, Buffer (Buffer'First .. Tail));
         Current_Jd := Jd_Id;
      else
         --
         --  Write a "non-first" line into the new file
         --
         Put_Line (Dst, Buffer (Buffer'First .. Tail));
      end if;
   end loop;
   --
   --  Close the source file.
   --
   Close (Src);
   --
   --  The last output file will be open when we get here so close it.
   --
   Close (Dst);
   Put (Line_Count_Str, Line_Count);
   Put(File_Count_Str, File_Count);
   Status_Msg ("mged_data_split",
               "The procedure successfully read " &
                 Trim (Line_Count_Str, Both) &
                 " lines from " & Argument (1) &
                 " and copied them into " &
                 Trim (File_Count_Str, Both) &
                 " distinct files with a prototype name of " &
                 Argument (2));
end Mged_Data_Split;
