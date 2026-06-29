@echo off

set TARGET_DIR=C:\rama\team\Gazi Blockchain Team
set COMMIT_MESSAGE=Obsidian notes update

cd /d "%TARGET_DIR%"

git status --porcelain > temp_status.txt

for %%A in (temp_status.txt) do if %%~zA==0 (
    echo Degisiklik yok, push yapilmadi.
    del temp_status.txt
    pause
    exit /b
)

del temp_status.txt

git add .
git commit -m "%COMMIT_MESSAGE%"
git push

pause