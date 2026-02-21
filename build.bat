@echo off
setlocal

:: Force the environment to use your specific MSYS2 UCRT64 path
set "MSYS_DIR=C:\msys64\ucrt64"
set "PATH=%MSYS_DIR%\bin;C:\msys64\usr\bin;%PATH%"

echo [1/3] Cleaning old artifacts...
del hydration_test.exe main.o world.bin 2>nul

echo [2/3] Lisp: Baking binary slab (world.bin)...
:: Note: This assumes SBCL is in your PATH. 
:: If using another Lisp, change 'sbcl --script' accordingly.
sbcl --script emit6.lisp

if %errorlevel% neq 0 (
    echo [ERROR] Lisp failed to emit the binary slab.
    pause
    exit /b
)

echo [3/3] C: Compiling Hydration Runtime...
gcc -Wall -O2 main6.c -o hydration_test.exe

if %errorlevel% equ 0 (
    echo ---------------------------------
    echo [SUCCESS] Runtime Compiled. Executing...
    echo ---------------------------------
    hydration_test.exe
) else (
    echo.
    echo [ERROR] C Compilation failed. 
    echo Check your struct definitions for alignment/syntax errors.
)

pause