@echo off
set DATE=%date:~12,2%%date:~4,2%%date:~7,2%
set TIME=%time:~0,2%%time:~3,2%
set TIME=%TIME: =0%
set TIMESTAMP=%DATE%-%TIME%
set BACKUP_DIR=C:\Terry\rustdesk\backup\%TIMESTAMP%
set LATEST_DIR=C:\Terry\rustdesk\latest_configuration
set SHARED_DIR=\\DevI9\Public\Lap01-backup

echo Backing up Lap01 RustDesk configs...

:: Create directories
mkdir %BACKUP_DIR%
mkdir %LATEST_DIR%
mkdir %SHARED_DIR%

:: Copy .toml files to timestamped backup
copy C:\Users\Terry\AppData\Roaming\RustDesk\config\peers.toml %BACKUP_DIR%\Lap01-peers.toml
copy C:\Users\Terry\AppData\Roaming\RustDesk\config\RustDesk.toml %BACKUP_DIR%\Lap01-RustDesk.toml
copy C:\Users\Terry\AppData\Roaming\RustDesk\config\RustDesk2.toml %BACKUP_DIR%\Lap01-RustDesk2.toml
copy C:\Users\Terry\AppData\Roaming\RustDesk\config\RustDesk_ab %BACKUP_DIR%\Lap01-RustDesk_ab
copy C:\Users\Terry\AppData\Roaming\RustDesk\config\RustDesk_default.toml %BACKUP_DIR%\Lap01-RustDesk_default.toml
copy C:\Users\Terry\AppData\Roaming\RustDesk\config\RustDesk_hwcodec.toml %BACKUP_DIR%\Lap01-RustDesk_hwcodec.toml
copy C:\Users\Terry\AppData\Roaming\RustDesk\config\RustDesk_local.toml %BACKUP_DIR%\Lap01-RustDesk_local.toml

:: Copy to latest_configuration
copy %BACKUP_DIR%\Lap01-peers.toml %LATEST_DIR%\Lap01-peers.toml
copy %BACKUP_DIR%\Lap01-RustDesk.toml %LATEST_DIR%\Lap01-RustDesk.toml
copy %BACKUP_DIR%\Lap01-RustDesk2.toml %LATEST_DIR%\Lap01-RustDesk2.toml
copy %BACKUP_DIR%\Lap01-RustDesk_ab %LATEST_DIR%\Lap01-RustDesk_ab
copy %BACKUP_DIR%\Lap01-RustDesk_default.toml %LATEST_DIR%\Lap01-RustDesk_default.toml
copy %BACKUP_DIR%\Lap01-RustDesk_hwcodec.toml %LATEST_DIR%\Lap01-RustDesk_hwcodec.toml
copy %BACKUP_DIR%\Lap01-RustDesk_local.toml %LATEST_DIR%\Lap01-RustDesk_local.toml

:: Copy to DevI9 shared folder
copy %BACKUP_DIR%\Lap01-peers.toml %SHARED_DIR%\Lap01-peers.toml
copy %BACKUP_DIR%\Lap01-RustDesk.toml %SHARED_DIR%\Lap01-RustDesk.toml
copy %BACKUP_DIR%\Lap01-RustDesk2.toml %SHARED_DIR%\Lap01-RustDesk2.toml
copy %BACKUP_DIR%\Lap01-RustDesk_ab %SHARED_DIR%\Lap01-RustDesk_ab
copy %BACKUP_DIR%\Lap01-RustDesk_default.toml %SHARED_DIR%\Lap01-RustDesk_default.toml
copy %BACKUP_DIR%\Lap01-RustDesk_hwcodec.toml %SHARED_DIR%\Lap01-RustDesk_hwcodec.toml
copy %BACKUP_DIR%\Lap01-RustDesk_local.toml %SHARED_DIR%\Lap01-RustDesk_local.toml

echo Backup completed to %BACKUP_DIR%, %LATEST_DIR%, and %SHARED_DIR%
pause