REM DEVI9 CopyRustDeskconfog2GitStaging.bat
@ECHO OFF
SET DATE=%date:~10,4%-%date:~4,2%-%date:~7,2%
MKDIR C:\Backup\RustDesk\%DATE%
SET backup_folder=C:\Backup\RustDesk\%DATE%
ECHO backup_folder: %backup_folder%
XCOPY C:\rustdesk-server %backup_folder% /E /F /I /Y /EXCLUDE:excludes.dat
ECHO src_folder: %APPDATA%\RustDesk\config
XCOPY %APPDATA%\RustDesk\config %backup_folder%\DevI9-config /E /F /I /Y /EXCLUDE:excludes.dat
xcopy C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config %backup_folder%\DevI9-server /E /F /I /Y /EXCLUDE:excludes.dat
echo Backup completed to %backup_folder%
