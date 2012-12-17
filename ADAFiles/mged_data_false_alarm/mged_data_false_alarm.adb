
with Ada.Text_Io,
     Ada.Command_Line,
     Ada.Strings,
     Ada.Strings.Fixed,
     Ada.Strings.Maps,
     Astro,
     Messages,
     Tsa_Pkg;
use Ada.Text_Io,
    Ada.Command_Line,
    Ada.Strings,
    Ada.Strings.Fixed,
    Ada.Strings.Maps,
    Messages,
    Tsa_Pkg;

procedure Mged_Data_False_Alarm is
   package Ast is new Astro (Integer, Long_Float); use Ast;
   package Fio is new Float_Io (Long_Float); use Fio;
   package Iio is new Integer_Io (Integer); use Iio;
   type S1_Array is array (Integer range <>) of String (1 .. 64);
   type S1_Array_Ptr is access S1_Array;
   Src, Dst : File_Type;
   Line_Count, N_Lcs, Tail, Ndx, Ptr, First, Last,
   Terminus, N_Points : Natural;
   K : Integer;
   Delimiter : Character_Set;
   Done : Boolean;
   Buffer : String (1 .. 512);
   All_Lcs : S1_Array_Ptr;
   Minps, Maxps, Scrambled_Pxs, Cumulative, Mag, Timestamp,
   Epoch : Tsa_Pkg.Ast.F1_Array_Ptr;
   N_Ps, N_Trials : I1_Array_Ptr;
   Minimum_Time, Max_Mag, Min_Mag, Mag_Difference : Long_Float;
   User_Error : exception;

begin
   --
   --  Verify the required command line arguments are present.
   --
   if Argument_Count /= 2 then
      Error_Msg ("mged_data_false_alarm",
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
      Error_Msg ("mged_data_false_alarm",
                 "The input file name is empty. The " &
                   "procedure cannot proceed without a " &
                   "non-empty input file name.");
      raise User_Error;
   end if;
   if Trim (Argument (2), Both) = "" then
      Error_Msg ("mged_data_false_alarm",
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
         Error_Msg ("mged_data_false_alarm",
                    "The procedure is unable to open the input data " &
                      "file. This error ususally occurs if the data " &
                      "file name is misspelled or if the data file " &
                      "does not exist.");
         raise User_Error;
   end;
   --
   --  Read data from the source file
   --
   --  Read all the lines.  Count them but do nothing else.
   --
   Line_Count := 0;
   while not End_Of_File (Src) loop
      Get_Line (Src, Buffer, Tail);
      Line_Count := Line_Count + 1;
   end loop;
   Reset (Src);
   --
   --  There must be at least one line.
   --
   if Line_Count > 0 then
      N_Lcs := Line_Count;
   else
      Error_Msg ("mged_data_false_alarm",
                 "The source data file is empty. Its " &
                   "name is " & Argument(1) & ".");
      raise User_Error;
   end if;
   --
   --  Allocate the required arrays.
   --
   All_Lcs := new S1_Array (1 .. Line_Count);
   Minps := new Tsa_Pkg.Ast.F1_Array (1 .. Line_Count);
   Maxps := new Tsa_Pkg.Ast.F1_Array (1 .. Line_Count) ;
   N_Ps := new I1_Array (1 .. Line_Count);
   N_Trials := new I1_Array (1 .. Line_Count);
   --
   --  Read the all the lines again but assign the values to the variables.
   --
   Delimiter := To_Set (" ,");
   Ndx := 0;
   while not End_Of_File (Src) loop
      Get_Line (Src, Buffer, Tail);
      Ndx := Ndx + 1;
      Ptr := 0;
      Last := 0;
      Done := False;
      --
      --  Find each token in the line and convert it to a float.
      --  There must be at least 5 tokens. If not, raise an error;
      --
      while not Done loop
         Find_Token (Buffer (Last + 1 .. Tail), Delimiter, Outside,
                    First,Last);
         if Last > 0 then
            Ptr := Ptr + 1;
            case Ptr is
               when 1 => Move (Buffer (First .. Last), All_Lcs (Ptr));
               when 2 => Get(Buffer(First..Last),Minps(Ptr),Terminus);
               when 3 => Get(Buffer(First..Last),Maxps(Ptr),Terminus);
               when 4 => Get(Buffer(First..Last),N_Ps(Ptr),Terminus);
               when 5 => Get(Buffer(First..Last),N_Trials(Ptr),Terminus);
               when others => exit;
            end case;
         else
            exit;
         end if;
      end loop;
      if Ptr /= 5 then
         Error_Msg ("mged_data_false_alarm",
                    "A line in the input file did not have the " &
                      "required five numbers. The offending line is """ &
                   Buffer(1..Tail) & """");
         raise User_Error;
      end if;
   end loop;
   Close(Src);
   --
   --  Open the output file
   begin
      Create (Dst, Out_File, Argument (2));
   exception
      when others =>
         Error_Msg
           ("mged_data_false_alarm",
            "The procedure could not open the specified output " &
              "file. Often this error occurs when the user does " &
              "not have write privleges in the destination " &
              "directory.");
         raise User_Error;
   end;
   --
   --  Loop through all the files specified in the input file.
   --  Each time through the loop we read another file.
   --
   for I in 1 .. N_Lcs loop
      Scrambled_Pxs := new Tsa_Pkg.Ast.F1_Array(1 .. N_Trials(I));
      Cumulative := new Tsa_Pkg.Ast.F1_Array (1 .. N_Trials (I));
      for J in 1 .. N_Trials (I) loop
         Cumulative (J) := Long_Float (J) / Long_Float (N_Trials (I));
      end loop;
      --
      --  Open the next file in sequence
      --
      --  Just to hurry through this, I won't program this in
      --  a safe way.
      --
      Open (Src, In_File, Trim (All_Lcs (I), Both));
      Timestamp := new Tsa_Pkg.Ast.F1_Array (1 .. N_Trials (I));
      Mag := new Tsa_Pkg.Ast.F1_Array (1 .. N_Trials (I));
      K := 0;
      while not End_Of_File (Src) loop
         K := K+1;
         Get (Src, Timestamp (K), Terminus);
         Get(Src,Mag(K),Terminus);
      end loop;
      --  Should check that K matches N_Trials.
      Put_Line ("Processing " & Trim (All_Lcs (I), Both) & ".");
      Minimum_Time := Minimum (Timestamp.all);
      Epoch := new Tsa_Pkg.Ast.F1_Array(Timestamp'First..Timestamp'Last);
      for J in Timestamp'First .. Timestamp'Last loop
         Epoch (J) := Timestamp (J) - Minimum_Time;
      end loop;
      N_Points := Timestamp'Last - Timestamp'First + 1;
      Min_Mag := Minimum (Mag.all);
      Max_Mag := Maximum (Mag.all);
      Mag_Difference := Max_Mag - Min_Mag;
      --  Output the data for a plot file here.
      Tsa_Pkg.Ast.Free_F1_Array (Mag);
      Tsa_Pkg.Ast.Free_F1_Array (Timestamp);
      Tsa_Pkg.Ast.Free_F1_Array (Scrambled_Pxs);
      Tsa_Pkg.Ast.Free_F1_Array (Cumulative);
      Tsa_Pkg.Ast.Free_F1_Array (Epoch);
   end loop;
end Mged_Data_False_Alarm;
