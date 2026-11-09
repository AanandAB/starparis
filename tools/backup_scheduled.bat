@echo off
rem Star Paris local backup - Task Scheduler entry point.
rem
rem Runs tools\backup_d1.py with the repo as the working directory, bun on
rem PATH (the export shells out to `bunx wrangler`), and output appended to
rem backups\backup.log so a scheduled run has a paper trail.
rem
rem Usage:  backup_scheduled.bat daily   |   backup_scheduled.bat weekly
rem
rem daily  -> backups\daily\  , keeps 30 days
rem weekly -> backups\weekly\ , kept indefinitely
cd /d "%~dp0.."
set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
"%LOCALAPPDATA%\Programs\Python\Launcher\py.exe" -3.12 tools\backup_d1.py --type %1 >> backups\backup.log 2>&1
