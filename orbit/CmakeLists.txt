if(DEFINED CMAKE_Go_COMPILER)
  execute_process(COMMAND ${CMAKE_Go_COMPILER} install
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/orbit)
endif()
