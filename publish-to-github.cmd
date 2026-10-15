@echo off
setlocal

rem Launcher for tool\publish_to_github.ps1.
rem Works no matter what the current directory is (it resolves its own folder).
rem Usage:
rem   publish-to-github.cmd https://github.com/<user>/<repo>.git
rem or double-click it and paste the repository URL when prompted.

rem Git may be installed but missing from the PATH of an already-open terminal.
if exist "%ProgramFiles%\Git\cmd\git.exe" set "PATH=%ProgramFiles%\Git\cmd;%PATH%"
if exist "%ProgramFiles(x86)%\Git\cmd\git.exe" set "PATH=%ProgramFiles(x86)%\Git\cmd;%PATH%"
if exist "%LOCALAPPDATA%\Programs\Git\cmd\git.exe" set "PATH=%LOCALAPPDATA%\Programs\Git\cmd;%PATH%"

set "REPO_URL=%~1"
if "%REPO_URL%"=="" (
    set /p REPO_URL=Enter GitHub repository URL: 
    set "PAUSE_AT_END=1"
)

if "%REPO_URL%"=="" (
    echo No repository URL given, cancelled.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tool\publish_to_github.ps1" -RepoUrl "%REPO_URL%"
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if not "%EXIT_CODE%"=="0" echo Failed with exit code %EXIT_CODE%.
if defined PAUSE_AT_END pause
exit /b %EXIT_CODE%
