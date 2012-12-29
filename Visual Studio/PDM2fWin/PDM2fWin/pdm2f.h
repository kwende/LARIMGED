#include "stdafx.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdio.h>
#include <ctype.h>

extern "C" {
	int pdm2_2(char* file, char* base_directory); 
	int pdm2( int ne, double datx[], double daty[], double sig[] );
	int p_sort( int n, double dat1[], double dat2[], double dat3[], int sgn );
	int i_sort( int n, int dat1[], double dat2[], int sgn );
	double inc_beta( double a, double b, double x );
	double rnd( void );
	double ran1(long *idum);

	static int binner( double datx[], double daty[], double sig[], double f, int bin10, int first, int last );
	static double dophase( double tt, double t0, double tn, double f );
	static int segset( int ne, double datx[], double daty[], double segdev );
	static double sqrc( double x );
	static void error( char *str );
	static double mcurve( double phase );
	double bspl3( double z );
	static double table_interp( double x0, int n, double xt[], double yt[] );
	static int read_data_file( char *file, int title_lines );
	static int fgetline(FILE *fp, char *buffer, int max_len);
}