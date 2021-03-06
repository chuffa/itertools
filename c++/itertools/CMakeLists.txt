# ITERTOOLS C++ Interface is header-only
# Create an Interface Target
file(GLOB_RECURSE headers *.hpp)
add_library(${PROJECT_NAME}_c INTERFACE)
add_library(${PROJECT_NAME}::${PROJECT_NAME}_c ALIAS ${PROJECT_NAME}_c)

# Set C++ Standard
include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++20" HAS_CPP20)
if(HAS_CPP20)
  target_compile_options(${PROJECT_NAME}_c INTERFACE -std=c++20)
else()
  target_compile_options(${PROJECT_NAME}_c INTERFACE -std=c++17)
endif()

# Configure target and compilation
target_include_directories(${PROJECT_NAME}_c INTERFACE $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/c++>)
target_include_directories(${PROJECT_NAME}_c SYSTEM INTERFACE $<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include>)
target_compile_definitions(${PROJECT_NAME}_c INTERFACE
				ITERTOOLS_GIT_HASH=${PROJECT_GIT_HASH}
				$<$<CONFIG:Debug>:ITERTOOLS_DEBUG>
			  )

# Install library and headers
install(TARGETS ${PROJECT_NAME}_c EXPORT ${PROJECT_NAME}-targets DESTINATION lib)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} DESTINATION include FILES_MATCHING PATTERN "*.hpp" PATTERN "*.h")


# ========= Static Analyzer Checks ==========

option(ANALYZE_SOURCES OFF "Run static analyzer checks if found (clang-tidy, cppcheck)")
if(ANALYZE_SOURCES)

  # Locate static analyzer tools
  find_program(CPPCHECK_EXECUTABLE NAMES "cppcheck" PATHS ENV PATH)
  find_program(CLANG_TIDY_EXECUTABLE NAMES "clang-tidy" PATHS ENV PATH)

  # Run clang-tidy if found
  if(CLANG_TIDY_EXECUTABLE)
    message(STATUS "clang-tidy found: ${CLANG_TIDY_EXECUTABLE}")
    set_target_properties(${PROJECT_NAME}_c PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_EXECUTABLE}")
  else()
    message(STATUS "clang-tidy not found in $PATH. Please consider installing clang-tidy for additional checks!")
  endif()

  # Run cppcheck if found
  if(CPPCHECK_EXECUTABLE)
    message(STATUS "cppcheck found: ${CPPCHECK_EXECUTABLE}")
    add_custom_command(
	TARGET ${PROJECT_NAME}_c
	COMMAND ${CPPCHECK_EXECUTABLE}
	  --enable=warning,style,performance,portability
	  --std=c++17
	  --template=gcc
	  --verbose
	  --force
	  --quiet
          ${headers}
	WORKING_DIRECTORY
	  ${CMAKE_CURRENT_SOURCE_DIR}
    )
  else()
    message(STATUS "cppcheck not found in $PATH. Please consider installing cppcheck for additional checks!")
  endif()

endif()


# ========= Dynamic Analyzer Checks ==========

option(ASAN OFF "Compile library and executables with LLVM Address Sanitizer")
option(UBSAN OFF "Compile library and executables with LLVM Undefined Behavior Sanitizer")

if(ASAN)
  if(NOT TARGET asan)
    find_package(sanitizer REQUIRED "asan")
  endif()
  target_link_libraries(${PROJECT_NAME}_c INTERFACE $<BUILD_INTERFACE:asan>)
endif()
if(UBSAN)
  if(NOT TARGET ubsan)
    find_package(sanitizer REQUIRED "ubsan")
  endif()
  target_link_libraries(${PROJECT_NAME}_c INTERFACE $<BUILD_INTERFACE:ubsan>)
endif()
