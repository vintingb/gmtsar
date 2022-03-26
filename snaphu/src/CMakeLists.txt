#
#	$Id: $
#

add_executable(snaphu
        snaphu.c
        snaphu_cost.c
        snaphu_cs2.c
        snaphu_io.c
        snaphu_solver.c
        snaphu_tile.c
        snaphu_util.c
        snaphu_cs2types.h
        snaphu.h)
target_link_libraries(snaphu m)

# add the install targets
if (WIN32)
    install(TARGETS snaphu
            ARCHIVE DESTINATION bin
            COMPONENT Runtime
            LIBRARY DESTINATION bin
            COMPONENT Runtime
            RUNTIME DESTINATION bin
            COMPONENT Runtime)
else ()
    install(TARGETS snaphu
            ARCHIVE DESTINATION lib
            COMPONENT Runtime
            LIBRARY DESTINATION lib
            COMPONENT Runtime
            RUNTIME DESTINATION bin
            COMPONENT Runtime)
endif ()
