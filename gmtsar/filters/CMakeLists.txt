install(FILES
		box5x3          gauss15x5        gauss1x1    gauss33x9   gauss_alos_100m    gauss_alos_500m.m  gauss_ers_200m    gauss_tsx_50m.m  ydir
		gauss15x5_53km   gauss21x21  gauss3x21   gauss_alos_100m.m  gauss_alos_700m    gaussian.m        sanandreas11x7
		fill.3x3        gauss15x5.m      gauss25x25  gauss5x3    gauss_alos_200m    gauss_alos_700m.m  gauss_tsx_100m    sanandreas13x9
		gauss13x13      gauss17x17       gauss25x7   gauss5x5    gauss_alos_200m.m  gauss_dir_azi.m    gauss_tsx_100m.m  sanandreas2
		gauss15x15      gauss17x17_2sig  gauss29x29  gauss5x5.m  gauss_alos_300m    gauss_dir_range.m  gauss_tsx_200m    slcfilter
		gauss15x3       gauss17x5        gauss29x9   gauss9x5    gauss_alos_300m.m  gauss_ers_100m     gauss_tsx_200m.m  smooth3x3
		gauss15x3.m     gauss19x19       gauss33x33  gauss9x9    gauss_alos_500m    gauss_ers_100m.m   gauss_tsx_50m     xdir
	DESTINATION ${SHARE_DIR}/filters
	COMPONENT Runtime)
