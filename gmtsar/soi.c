char *input_file;
char *led_file;
char *out_amp_file;
char *out_data_file;
char *deskew;
char *iqflip;
char *off_vid;
char *srm;
char *ref_file;
char *orbdir;
char *lookdir;

int debug_flag;
int bytes_per_line;
int good_bytes;
int first_line;
int num_patches;
int first_sample;
int num_valid_az;
int st_rng_bin;
int num_rng_bins;
int nextend;
int nlooks;
int xshift;
int yshift;
int fdc_ystrt;
int fdc_strt;

/*New parameters 4/23/97 -EJP */
int rec_start;
int rec_stop;
/* End new parameters 4/23/97 -EJP */

/* New parameters 4/23/97 -DTS */
int SC_identity;       /* (1)-ERS1 (2)-ERS2 (3)-Radarsat (4)-Envisat (5)-ALOS
                          (6)-Envisat_SLC  (7)-TSX (8)-CSK (9)-RS2 (10)-S1A*/
int ref_identity;      /* (1)-ERS1 (2)-ERS2 (3)-Radarsat (4)-Envisat (5)-ALOS
                          (6)-Envisat_SLC  (7)-TSX (8)-CSK (9)-RS2 (10)-S1A*/
double SC_clock_start; /* YYDDD.DDDD */
double SC_clock_stop;  /* YYDDD.DDDD */
double icu_start;      /* onboard clock counter */
double clock_start;    /* DDD.DDDDDDDD  clock without year has more precision */
double clock_stop;     /* DDD.DDDDDDDD  clock without year has more precision */
/* End new parameters 4/23/97 -DTS */

double caltone;
double RE;   /* Local Earth radius */
double raa;  /* ellipsoid semi-major axis - added by RJM */
double rcc;  /* ellipsoid semi-minor axis - added by RJM */
double vel1; /* Equivalent SC velocity */
double ht1;  /* (SC_radius - RE) center of frame*/
double ht0;  /* (SC_radius - RE) start of frame */
double htf;  /* (SC_radius - RE) end of frame */
double near_range;
double far_range;
double prf1;
double xmi1;
double xmq1;
double az_res;
double fs;
double slope;
double pulsedur;
double lambda;
double rhww;
double pctbw;
double pctbwaz;
double fd1;
double fdd1;
double fddd1;
double sub_int_r;
double sub_int_a;
double stretch_r;
double stretch_a;
double a_stretch_r;
double a_stretch_a;

/* New parameters 8/28/97 -DTS */
double baseline_start;
double baseline_center;
double baseline_end;
double alpha_start;
double alpha_center;
double alpha_end;
/* New parameters 9/25/18 -EXU */
double B_offset_start;
double B_offset_center;
double B_offset_end;
/* End new parameters 8/28/97 -DTS */
double bparaa; /* parallel baseline - added by RJM */
double bperpp; /* perpendicular baseline - added by RJM */

/* New parameters 4/26/06 */
int nrows;
int num_lines;

/* New parameters 09/18/08 */
double TEC_start;
double TEC_end;
