add_executable(
  snaphu
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

install(TARGETS snaphu RUNTIME DESTINATION bin COMPONENT Runtime)
