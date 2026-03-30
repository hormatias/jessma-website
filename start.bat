@echo off
setlocal
cd /d "%~dp0" || exit /b 1
ruby start.rb %*
exit /b %ERRORLEVEL%
