set PART xcvu9p-flgb2104-2-i
# HBM: xcvu37p-fsvh2892-3-e-es1
set PROJ_NAME ipgen
set SIMLIB_DIR vcs_simlibs

compile_simlib -simulator vcs -family virtexuplus \
    -language all -library all -dir [exec pwd]/$SIMLIB_DIR
