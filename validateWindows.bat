@echo off
setlocal
set "PROJECT_DIR=%~dp0"
set "MATLAB_EXE="
where matlab >nul 2>nul
if not errorlevel 1 set "MATLAB_EXE=matlab"
if not defined MATLAB_EXE if exist "%ProgramFiles%\MATLAB\R2025b\bin\matlab.exe" set "MATLAB_EXE=%ProgramFiles%\MATLAB\R2025b\bin\matlab.exe"
if not defined MATLAB_EXE (
    echo MATLAB R2025b was not found. Open MATLAB and run runWindowsValidation manually.
    pause
    exit /b 1
)
"%MATLAB_EXE%" -sd "%PROJECT_DIR%" -r "try, runWindowsValidation; catch err, disp(getReport(err,'extended')); end"
endlocal
