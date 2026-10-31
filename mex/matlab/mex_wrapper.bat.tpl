@echo off

set "MATLAB_PREFDIR=%TMPDIR%\prefs"
if not exist "%MATLAB_PREFDIR%" mkdir "%MATLAB_PREFDIR%"
if errorlevel 1 exit /b 1

"%{mex_exe}" %*
exit /b %ERRORLEVEL%
