if(HAVE_M_LIBRARY)
  # link the math library
  set(LINK_LIBS m)
endif(HAVE_M_LIBRARY)

include_directories(include ../../gmtsar ${TIFF_INCLUDE_DIR} ${GMT_INCLUDE_DIR})
if(WIN32)
  add_library(xmlC STATIC lib/xml.c include/xmlC.h include/lib_defs.h)
else()
  add_library(xmlC SHARED lib/xml.c include/xmlC.h include/lib_defs.h)
endif()
target_link_libraries(xmlC ${LINK_LIBS})

set(LINK_LIBS ${LINK_LIBS} xmlC gmtsar ${TIFF_LIBRARY})

add_executable(ext_orb_s1a src_orbit/ext_orb_s1a.c)
target_link_libraries(ext_orb_s1a ${LINK_LIBS})

add_executable(spectral_diversity src_spec_div/spectral_diversity.c)
target_link_libraries(spectral_diversity ${LINK_LIBS})

add_executable(merge_swath src_stitch/merge_swath.c)
target_link_libraries(merge_swath ${LINK_LIBS})

add_executable(stitch_tops src_stitch/stitch_tops.c)
target_link_libraries(stitch_tops ${LINK_LIBS})

add_executable(make_slc_s1a src_swath/make_slc_s1a.c)
target_link_libraries(make_slc_s1a ${LINK_LIBS})

add_executable(make_s1a_tops src_tops/make_s1a_tops.c)
target_link_libraries(make_s1a_tops ${LINK_LIBS})

add_executable(make_s1a_tops_6par src_tops/make_s1a_tops_6par.c)
target_link_libraries(make_s1a_tops_6par ${LINK_LIBS})

# add the install targets

install(
  TARGETS xmlC
          ext_orb_s1a
          spectral_diversity
          merge_swath
          stitch_tops
          make_slc_s1a
          make_s1a_tops
          make_s1a_tops_6par
  LIBRARY DESTINATION /usr/local/lib COMPONENT Runtime
  RUNTIME DESTINATION bin COMPONENT Runtime)
