rem ---------------------------------------------------------------------------

rem Perforce paths
set PATH=%RISCV_GCC%;%PATH%

set TOP_DIR=..\
set OBJ_DIR=%TOP_DIR%obj
set ELF_DIR=%TOP_DIR%bin

mkdir %OBJ_DIR%
mkdir %ELF_DIR%
make -f make_bootrom TOP_DIR=%TOP_DIR% OBJ_DIR=%OBJ_DIR% ELF_DIR=%ELF_DIR%

pause
exit
