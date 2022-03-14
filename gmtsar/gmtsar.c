
/* global variables */
int verbose;     /* controls minimal level of output 	*/
int debug;       /* more output 				*/
int swap;        /* whether to swap bytes 		*/
int quad_pol;    /* quad polarization data 		*/
int force_slope; /* whether to force the slope 		*/
int dopp;        /* whether to calculate doppler 	*/
int roi_flag;    /* whether to write roi.in 		*/
int sio_flag;    /* whether to write PRM file 		*/
int nodata;
int quiet_flag;
double forced_slope; /* value to set chirp_slope to		*/
int SAR_mode;        /* 0 => high-res                        */
/* 1 => wide obs                        */
/* 2 => polarimetry                     */
/* from ALOS Product Format 3-2         */