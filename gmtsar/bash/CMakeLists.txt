install (PROGRAMS
    align_tops.bash  dem2topo_ra.bash  gmtsar_sharedir.bash  m2s.bash                        p2p_S1_TOPS_Frame.bash  slc2amp.bash
    all.bash         filter.bash       grd2kml.bash          merge_unwrap_geocode_tops.bash  pre_proc.bash           snaphu.bash
    cleanup.bash     fitoffset.bash    intf.bash             p2p_processing.bash             proj_ll2ra.bash         snaphu.conf.brief
    pop_config.bash   geocode.bash      landmask.bash         p2p_S1_TOPS.bash                proj_ra2ll.bash         snaphu_interp.bash
	DESTINATION bin
	COMPONENT Runtime)
