@echo off

set "TMPDIR=%CD%\%{scratch_dir}"
set "MATLAB_PREFDIR=%TMPDIR%\prefs"
set "PATH=%{cc_path};%PATH%"

if not exist "%MATLAB_PREFDIR%" mkdir "%MATLAB_PREFDIR%"
if errorlevel 1 exit /b 1

"%{mex_exe}" %*
exit /b %ERRORLEVEL%
