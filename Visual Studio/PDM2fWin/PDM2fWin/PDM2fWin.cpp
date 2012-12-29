// PDM2fWin.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "pdm2f.h"

int _tmain(int argc, _TCHAR* argv[])
{
	if(argc==3)
	{
		char argv1[1024]; 
		char argv2[1024]; 

		wcstombs(argv1, argv[1], sizeof(argv1)); 
		wcstombs(argv2, argv[2], sizeof(argv1)); 

		int ret = pdm2_2(argv1, argv2); 
	}
	return 0;
}

