@echo off
rem Install (or refresh) the Star Paris local backup schedules.
rem
rem   StarParisBackupDaily  - every day 02:30, keeps 30 days
rem   StarParisBackupWeekly - every Sunday 03:30, kept indefinitely
rem
rem Both run backup_scheduled.bat in this folder (which cds to the repo,
rem puts bun on PATH, and calls tools\backup_d1.py). Re-running this file
rem overwrites the tasks (/f), so it is safe to run after moving the repo.
schtasks /create /f /tn "StarParisBackupDaily" /tr "\"%~dp0backup_scheduled.bat\" daily" /sc daily /st 02:30
schtasks /create /f /tn "StarParisBackupWeekly" /tr "\"%~dp0backup_scheduled.bat\" weekly" /sc weekly /d SUN /st 03:30
echo Done. Verify with: schtasks /query /tn StarParisBackupDaily
